import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/video_source.dart';
import '../../tags/data/tag_local_datasource.dart';
import '../domain/bookmark_not_found_exception.dart';
import '../domain/video_bookmark.dart';
import 'bookmark_local_datasource.dart';
import 'bookmark_remote_datasource.dart';
import 'bookmark_remote_sync_exception.dart';

/// Point d'entrée unique entre la couche présentation et les sources de
/// données d'un bookmark (Isar local + Supabase distant).
///
/// Applique la logique offline-first (SPEC.md section 4 règle 2) : toute
/// écriture passe d'abord par [BookmarkLocalDatasource] (`isSynced: false`),
/// puis une synchronisation vers Supabase est tentée immédiatement. Aucun
/// widget ni provider de présentation ne doit appeler directement Isar ou
/// Supabase (voir CONVENTIONS.md section Réponses API) — uniquement via
/// cette classe.
///
/// **Accès en lecture seule à `TagEntity` (Tâche 25, voir DECISIONS.md) :**
/// [createBookmark]/[updateBookmark] consultent [TagLocalDatasource] pour
/// savoir si l'un des tags finaux du bookmark correspond à un tag masqué
/// (`TagEntity.isHidden == true`), et forcent alors `isHidden: true` sur le
/// bookmark — même justification que `TagRepository` accédant déjà en
/// écriture à `BookmarkEntity` (voir sa doc de classe, entrée « Tâche 15 ») :
/// Isar interdit les transactions imbriquées, mais ici aucune écriture n'est
/// faite sur `TagEntity` (responsabilité exclusive de `TagRepository`,
/// jamais partagée) — une simple lecture, pas de composition de transaction
/// nécessaire.
class BookmarkRepository {
  /// Crée le repository à partir de ses sources de données.
  BookmarkRepository({
    required BookmarkLocalDatasource localDatasource,
    required BookmarkRemoteDatasource remoteDatasource,
    required TagLocalDatasource tagLocalDatasource,
    Uuid uuid = const Uuid(),
  }) : _localDatasource = localDatasource,
       _remoteDatasource = remoteDatasource,
       _tagLocalDatasource = tagLocalDatasource,
       _uuid = uuid;

  final BookmarkLocalDatasource _localDatasource;
  final BookmarkRemoteDatasource _remoteDatasource;
  final TagLocalDatasource _tagLocalDatasource;
  final Uuid _uuid;

  /// Crée un nouveau bookmark : écriture locale immédiate (identifiant
  /// généré côté client), puis tentative de synchronisation distante.
  ///
  /// Si l'un de [tags] correspond à un tag masqué (`TagEntity.isHidden ==
  /// true`, Tâche 25, voir DECISIONS.md et doc de classe), le bookmark est
  /// créé directement `isHidden: true` — aucune action supplémentaire de
  /// l'utilisateur requise.
  Future<VideoBookmark> createBookmark({
    required String url,
    required String title,
    required VideoSource source,
    String? thumbnailUrl,
    bool isPartial = false,
    List<String> tags = const [],
    String? note,
  }) async {
    final now = DateTime.now();
    final hasHiddenTag = await _tagLocalDatasource.hasAnyHiddenTag(tags);
    final entity = BookmarkEntity()
      ..remoteId = _uuid.v4()
      ..url = url
      ..title = title
      ..thumbnailUrl = thumbnailUrl
      ..source = source.name
      ..isPartial = isPartial
      ..isHidden = hasHiddenTag
      ..tags = tags
      ..note = note
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..isDeletedLocally = false;

    await _localDatasource.upsert(entity);
    await _trySyncInsert(entity);
    return _toBookmark(entity);
  }

  /// Retourne tous les bookmarks non supprimés, triés par date de création
  /// décroissante — lus depuis la base locale (source de vérité côté UI,
  /// jamais un aller-retour réseau direct).
  Future<List<VideoBookmark>> getAllBookmarks() async {
    final entities = await _localDatasource.getAllActive();
    return entities.map(_toBookmark).toList();
  }

  /// Met à jour un bookmark existant (titre, tags, note, etc.) : écriture
  /// locale immédiate, puis tentative de synchronisation distante.
  ///
  /// Si l'un de [bookmark.tags] correspond à un tag masqué
  /// (`TagEntity.isHidden == true`, Tâche 25, voir DECISIONS.md et doc de
  /// classe), `isHidden: true` est forcé quelle que soit la valeur fournie
  /// par l'appelant — s'applique donc aussi bien à l'ajout d'un tag masqué
  /// via "Modifier les tags" (Tâche 21) qu'à toute autre modification.
  ///
  /// Lève [BookmarkNotFoundException] si [bookmark.id] ne correspond à
  /// aucune entité locale.
  Future<VideoBookmark> updateBookmark(VideoBookmark bookmark) async {
    final entity = await _localDatasource.findByRemoteId(bookmark.id);
    if (entity == null) {
      throw BookmarkNotFoundException(bookmark.id);
    }

    final hasHiddenTag = await _tagLocalDatasource.hasAnyHiddenTag(
      bookmark.tags,
    );

    entity
      ..url = bookmark.url
      ..title = bookmark.title
      ..thumbnailUrl = bookmark.thumbnailUrl
      ..source = bookmark.source.name
      ..isPartial = bookmark.isPartial
      ..isHidden = hasHiddenTag || bookmark.isHidden
      ..tags = bookmark.tags
      ..note = bookmark.note
      ..updatedAt = DateTime.now()
      ..isSynced = false;

    await _localDatasource.upsert(entity);
    await _trySyncUpdate(entity);
    return _toBookmark(entity);
  }

  /// Supprime le bookmark d'identifiant [id].
  ///
  /// Marque d'abord l'entité locale `isDeletedLocally: true` (elle
  /// disparaît immédiatement de [getAllBookmarks]), puis tente la
  /// suppression distante : si elle réussit, l'entité locale est retirée
  /// définitivement ; sinon elle reste marquée en attente, pour être
  /// propagée plus tard par le futur `sync_service.dart` (voir SPEC.md
  /// section 13 — évite qu'un bookmark supprimé hors ligne ne réapparaisse
  /// après une synchronisation ultérieure).
  Future<void> deleteBookmark(String id) async {
    final entity = await _localDatasource.findByRemoteId(id);
    if (entity == null) return;

    entity.isDeletedLocally = true;
    await _localDatasource.upsert(entity);

    if (entity.userId == null) {
      // Pas encore authentifié : aucune tentative distante (voir
      // DECISIONS.md, entrée "user_id absent avant l'authentification").
      return;
    }

    try {
      await _remoteDatasource.delete(id);
      await _localDatasource.deleteByRemoteId(id);
    } on Exception catch (cause) {
      _logSyncFailure(BookmarkRemoteSyncException(id, cause));
    }
  }

  Future<void> _trySyncInsert(BookmarkEntity entity) async {
    if (entity.userId == null) {
      // Pas encore authentifié (Phase 6 du TODO) : la contrainte NOT NULL
      // sur `bookmarks.user_id` rendrait tout insert distant impossible.
      // Ce n'est pas un échec de synchronisation — aucune tentative n'est
      // faite, l'entité reste `isSynced: false` jusqu'à ce qu'une future
      // authentification renseigne `userId` rétroactivement (voir
      // DECISIONS.md).
      return;
    }

    try {
      await _remoteDatasource.insert(_toRemoteMap(entity));
      entity.isSynced = true;
      await _localDatasource.upsert(entity);
    } on Exception catch (cause) {
      _logSyncFailure(BookmarkRemoteSyncException(entity.remoteId, cause));
    }
  }

  Future<void> _trySyncUpdate(BookmarkEntity entity) async {
    if (entity.userId == null) {
      return;
    }

    try {
      await _remoteDatasource.update(entity.remoteId, _toRemoteMap(entity));
      entity.isSynced = true;
      await _localDatasource.upsert(entity);
    } on Exception catch (cause) {
      _logSyncFailure(BookmarkRemoteSyncException(entity.remoteId, cause));
    }
  }

  /// Rattrape toute écriture locale qui n'a pas encore atteint Supabase —
  /// appelé par `SyncService` (Tâche 9) à la reconnexion réseau et
  /// périodiquement, jamais par la couche présentation directement.
  ///
  /// Traite les suppressions en attente (`isDeletedLocally`) **avant** tout
  /// autre envoi (voir SPEC.md section 13) : un bookmark qu'un autre flux
  /// tenterait de re-synchroniser entre-temps ne doit jamais réapparaître
  /// après avoir été supprimé localement. Les créations/modifications en
  /// attente (`isSynced: false`) sont ensuite envoyées via `upsert` distant
  /// (pas de distinction insert/update ici — l'entité a pu être créée puis
  /// modifiée hors ligne plusieurs fois avant ce rattrapage).
  Future<void> syncPendingChanges() async {
    final pendingDeletions = await _localDatasource.getAllPendingDeletion();
    for (final entity in pendingDeletions) {
      if (entity.userId == null) continue;
      try {
        await _remoteDatasource.delete(entity.remoteId);
        await _localDatasource.deleteByRemoteId(entity.remoteId);
      } on Exception catch (cause) {
        _logSyncFailure(BookmarkRemoteSyncException(entity.remoteId, cause));
      }
    }

    final pendingUploads = await _localDatasource.getAllPendingUpload();
    for (final entity in pendingUploads) {
      if (entity.userId == null) continue;
      try {
        await _remoteDatasource.upsert(_toRemoteMap(entity));
        entity.isSynced = true;
        await _localDatasource.upsert(entity);
      } on Exception catch (cause) {
        _logSyncFailure(BookmarkRemoteSyncException(entity.remoteId, cause));
      }
    }
  }

  /// Rapatrie vers l'Isar local les bookmarks distants absents ou plus
  /// récents que leur copie locale — c'est ce qui permet à un bookmark créé
  /// sur un premier appareil d'apparaître sur un second (voir critère
  /// d'acceptation de la Tâche 9). Appelé par `SyncService` uniquement
  /// lorsqu'une session Supabase active existe (voir `SyncService`).
  ///
  /// Résolution de conflit **last-write-wins** sur `updated_at` (voir
  /// SPEC.md section 13, décision déjà actée) : si la ligne distante est plus
  /// récente que la copie locale, elle écrase cette dernière. Une entité
  /// locale déjà synchronisée mais absente des lignes distantes rapatriées a
  /// été supprimée depuis un autre appareil : elle est alors retirée
  /// localement aussi.
  Future<void> pullRemoteChanges() async {
    final remoteRows = await _remoteDatasource.selectAll();
    final remoteIds = <String>{};

    for (final row in remoteRows) {
      final remoteId = row['id'] as String;
      remoteIds.add(remoteId);
      final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);
      final existing = await _localDatasource.findByRemoteId(remoteId);

      if (existing == null) {
        await _localDatasource.upsert(_fromRemoteMap(row));
        continue;
      }
      if (existing.isDeletedLocally) {
        // Suppression locale en attente : ne pas ressusciter l'entité tant
        // que la suppression distante n'a pas été tentée (voir
        // syncPendingChanges).
        continue;
      }
      if (remoteUpdatedAt.isAfter(existing.updatedAt)) {
        await _localDatasource.upsert(
          _fromRemoteMap(row)..isarId = existing.isarId,
        );
      }
    }

    final syncedRemoteIds = await _localDatasource.getAllSyncedRemoteIds();
    for (final remoteId in syncedRemoteIds) {
      if (!remoteIds.contains(remoteId)) {
        await _localDatasource.deleteByRemoteId(remoteId);
      }
    }
  }

  /// Démasque tous les bookmarks actuellement `isHidden: true` (flux "Code
  /// oublié ?" de la section "My Eyes Only", Tâche 22, voir DECISIONS.md) :
  /// aucune perte de données, seule la visibilité change. Réutilise
  /// [updateBookmark] pour chacun plutôt qu'un accès direct à Isar, afin de
  /// bénéficier de la même tentative de synchronisation distante qu'une
  /// modification normale.
  Future<void> unhideAllBookmarks() async {
    final bookmarks = await getAllBookmarks();
    for (final bookmark in bookmarks.where((bookmark) => bookmark.isHidden)) {
      await updateBookmark(bookmark.copyWith(isHidden: false));
    }
  }

  /// Recherche full-text locale sur titre + tags (voir SPEC.md section 11) —
  /// délègue entièrement à [BookmarkLocalDatasource.searchByTitleOrTags],
  /// jamais d'appel à [_remoteDatasource] : la donnée locale est la seule
  /// source de vérité pour l'affichage d'une recherche (voir CONVENTIONS.md,
  /// contrainte de la Tâche 9).
  Future<List<VideoBookmark>> searchBookmarks(String query) async {
    final entities = await _localDatasource.searchByTitleOrTags(query);
    return entities.map(_toBookmark).toList();
  }

  /// Journalise un échec de synchronisation distant réel (jamais le cas
  /// "pas encore authentifié", filtré en amont) — au minimum un log
  /// explicite, jamais un `catch` silencieux (voir CONVENTIONS.md section
  /// Réponses API), en attendant qu'un futur `sync_service.dart` (Tâche 9)
  /// exploite ce signal pour ses propres tentatives de rattrapage.
  void _logSyncFailure(BookmarkRemoteSyncException exception) {
    debugPrint('$exception');
  }

  Map<String, dynamic> _toRemoteMap(BookmarkEntity entity) => {
    'id': entity.remoteId,
    'user_id': entity.userId,
    'url': entity.url,
    'title': entity.title,
    'thumbnail_url': entity.thumbnailUrl,
    'source': entity.source,
    'tags': entity.tags,
    'note': entity.note,
    'is_partial': entity.isPartial,
    'is_hidden': entity.isHidden,
    'created_at': entity.createdAt.toIso8601String(),
    'updated_at': entity.updatedAt.toIso8601String(),
  };

  /// Reconstruit une [BookmarkEntity] locale à partir d'une ligne distante
  /// brute (voir [pullRemoteChanges]) — toujours marquée `isSynced: true` et
  /// `isDeletedLocally: false`, puisqu'elle vient d'être lue depuis Supabase.
  BookmarkEntity _fromRemoteMap(Map<String, dynamic> row) => BookmarkEntity()
    ..remoteId = row['id'] as String
    ..userId = row['user_id'] as String?
    ..url = row['url'] as String
    ..title = row['title'] as String?
    ..thumbnailUrl = row['thumbnail_url'] as String?
    ..source = row['source'] as String
    ..isPartial = row['is_partial'] as bool? ?? false
    ..isHidden = row['is_hidden'] as bool? ?? false
    ..tags = List<String>.from(row['tags'] as List? ?? const [])
    ..note = row['note'] as String?
    ..createdAt = DateTime.parse(row['created_at'] as String)
    ..updatedAt = DateTime.parse(row['updated_at'] as String)
    ..isSynced = true
    ..isDeletedLocally = false;

  VideoBookmark _toBookmark(BookmarkEntity entity) => VideoBookmark(
    id: entity.remoteId,
    url: entity.url,
    title: entity.title ?? '',
    thumbnailUrl: entity.thumbnailUrl,
    source: VideoSource.values.byName(entity.source),
    isPartial: entity.isPartial,
    isHidden: entity.isHidden,
    tags: entity.tags,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
    note: entity.note,
  );
}
