import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/models/video_source.dart';
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
class BookmarkRepository {
  /// Crée le repository à partir de ses deux sources de données.
  BookmarkRepository({
    required BookmarkLocalDatasource localDatasource,
    required BookmarkRemoteDatasource remoteDatasource,
    Uuid uuid = const Uuid(),
  }) : _localDatasource = localDatasource,
       _remoteDatasource = remoteDatasource,
       _uuid = uuid;

  final BookmarkLocalDatasource _localDatasource;
  final BookmarkRemoteDatasource _remoteDatasource;
  final Uuid _uuid;

  /// Crée un nouveau bookmark : écriture locale immédiate (identifiant
  /// généré côté client), puis tentative de synchronisation distante.
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
    final entity = BookmarkEntity()
      ..remoteId = _uuid.v4()
      ..url = url
      ..title = title
      ..thumbnailUrl = thumbnailUrl
      ..source = source.name
      ..isPartial = isPartial
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
  /// Lève [BookmarkNotFoundException] si [bookmark.id] ne correspond à
  /// aucune entité locale.
  Future<VideoBookmark> updateBookmark(VideoBookmark bookmark) async {
    final entity = await _localDatasource.findByRemoteId(bookmark.id);
    if (entity == null) {
      throw BookmarkNotFoundException(bookmark.id);
    }

    entity
      ..url = bookmark.url
      ..title = bookmark.title
      ..thumbnailUrl = bookmark.thumbnailUrl
      ..source = bookmark.source.name
      ..isPartial = bookmark.isPartial
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
    'created_at': entity.createdAt.toIso8601String(),
    'updated_at': entity.updatedAt.toIso8601String(),
  };

  VideoBookmark _toBookmark(BookmarkEntity entity) => VideoBookmark(
    id: entity.remoteId,
    url: entity.url,
    title: entity.title ?? '',
    thumbnailUrl: entity.thumbnailUrl,
    source: VideoSource.values.byName(entity.source),
    isPartial: entity.isPartial,
    tags: entity.tags,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
    note: entity.note,
  );
}
