import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';

import '../../bookmarks/data/bookmark_local_datasource.dart';
import '../../bookmarks/data/bookmark_repository.dart' show CurrentUserIdProvider;
import 'tag_local_datasource.dart';
import 'tag_remote_datasource.dart';
import 'tag_remote_sync_exception.dart';

/// Point d'entrée unique entre la couche présentation et la gestion
/// indépendante des tags (Isar local + Supabase distant depuis l'extension
/// de synchronisation, voir DECISIONS.md — auparavant "Isar local
/// uniquement", voir l'ancienne version de cette doc de classe conservée
/// dans l'historique git).
///
/// Applique les décisions actées dans DECISIONS.md, entrée « Tâche 15 » :
/// - **Suppression en cascade** : supprimer un tag le retire de tous les
///   `BookmarkEntity.tags` qui le portent.
/// - **Renommage propagé** : renommer un tag met à jour tous les
///   `BookmarkEntity.tags` concernés.
/// - **Tag purement dérivé éditable** : renommer un tag qui n'a pas encore
///   de [TagEntity] (visible uniquement parce qu'un bookmark le porte) en
///   crée un implicitement.
///
/// Étend en Tâche 25 (voir DECISIONS.md) le masquage "My Eyes Only" (Tâche
/// 22) aux tags eux-mêmes : [hideTag]/[unhideTag] masquent/démasquent en
/// cascade tous les `BookmarkEntity` qui portent le tag, existants et
/// futurs (l'auto-masquage à la création/édition d'un bookmark vit dans
/// `BookmarkRepository`, voir sa doc de classe). Jamais accessible ni
/// visible depuis le menu normal (`TagsScreen`/`tag_action_dialogs.dart`) —
/// uniquement depuis l'espace privé déjà déverrouillé.
///
/// **Synchronisation offline-first (extension tags remote sync, voir
/// DECISIONS.md) :** même architecture que `BookmarkRepository` (Tâche 9) —
/// [createTag]/[renameTag]/[deleteTag]/[hideTag]/[unhideTag] écrivent
/// d'abord localement (`isSynced: false`), puis tentent une synchronisation
/// immédiate ; [syncPendingChanges]/[pullRemoteChanges] rattrapent le reste,
/// appelées par `SyncService`. **Simplification volontaire par rapport à
/// `BookmarkRepository`** : une seule méthode `_trySyncUpsert` (pas de
/// distinction insert/update) — contrairement à un bookmark, un tag n'a
/// jamais besoin d'un insert strict qui échouerait sur conflit ; un upsert
/// idempotent suffit à tous les points d'écriture (voir DECISIONS.md).
/// [deleteTag] applique la même suppression douce que
/// `BookmarkRepository.deleteBookmark` (`isDeletedLocally: true` avant
/// confirmation distante, voir SPEC.md section 13) — écart par rapport à la
/// suppression Isar immédiate de la version initiale (Tâche 15).
///
/// **Contrainte technique Isar (justifie l'accès direct à [Isar] ici) :**
/// Isar interdit les transactions imbriquées (`writeTxn` dans un `writeTxn`
/// actif lève une `IsarError`, voir doc du package). Pour que le renommage
/// et la suppression modifient `TagEntity` et les `BookmarkEntity` concernés
/// dans une **seule** transaction (contrainte explicite de la tâche, pour
/// éviter un état incohérent en cas de crash entre les deux écritures), ce
/// repository ouvre lui-même l'unique `writeTxn` et appelle les collections
/// Isar directement (`_isar.tagEntitys`/`_isar.bookmarkEntitys`) plutôt que
/// les méthodes d'écriture de [TagLocalDatasource]/[BookmarkLocalDatasource]
/// (qui ouvrent chacune leur propre transaction, incompatible avec cette
/// composition). Les méthodes de lecture de ces datasources restent
/// utilisées telles quelles : elles n'ouvrent pas de transaction et peuvent
/// être appelées aussi bien à l'intérieur qu'à l'extérieur de la transaction
/// composée ici. Toute tentative de synchronisation réseau est faite
/// **après** la transaction, jamais depuis l'intérieur (un appel réseau ne
/// doit jamais garder une transaction Isar ouverte, même raisonnement que
/// `BookmarkRepository.deleteBookmarks`/`addTagsToBookmarks`, Tâche 26).
///
/// Aucun widget n'accède directement à Isar — uniquement via ce repository
/// (voir CONVENTIONS.md section Réponses API), au même titre que
/// `BookmarkRepository` pour les bookmarks.
class TagRepository {
  /// Crée le repository à partir de l'instance [Isar] partagée avec les
  /// bookmarks, des datasources correspondants et du fournisseur
  /// d'identifiant utilisateur courant (même mécanisme que
  /// `BookmarkRepository`, voir DECISIONS.md entrée « Tâche 28 »).
  TagRepository({
    required Isar isar,
    required TagLocalDatasource tagLocalDatasource,
    required BookmarkLocalDatasource bookmarkLocalDatasource,
    required TagRemoteDatasource remoteDatasource,
    required CurrentUserIdProvider getCurrentUserId,
    Uuid uuid = const Uuid(),
  }) : _isar = isar,
       _tagLocalDatasource = tagLocalDatasource,
       _bookmarkLocalDatasource = bookmarkLocalDatasource,
       _remoteDatasource = remoteDatasource,
       _getCurrentUserId = getCurrentUserId,
       _uuid = uuid;

  final Isar _isar;
  final TagLocalDatasource _tagLocalDatasource;
  final BookmarkLocalDatasource _bookmarkLocalDatasource;
  final TagRemoteDatasource _remoteDatasource;
  final CurrentUserIdProvider _getCurrentUserId;
  final Uuid _uuid;

  /// Retourne les noms de tous les tags gérés **visibles** (ayant un
  /// [TagEntity], `isHidden == false`), utilisé par `distinctTagsProvider`
  /// pour fusionner avec les tags dérivés des bookmarks (voir DECISIONS.md,
  /// entrée « Tâche 15 »). Exclut les tags masqués (`isHidden == true`,
  /// Tâche 25) — un tag masqué ne doit jamais apparaître dans
  /// `TagsScreen`/l'autocomplétion, voir [getHiddenTagNames] pour la liste
  /// symétrique.
  Future<List<String>> getManagedTagNames() async {
    final entities = await _tagLocalDatasource.getAll();
    return entities
        .where((entity) => !entity.isHidden)
        .map((entity) => entity.name)
        .toList();
  }

  /// Retourne les noms de tous les tags masqués (`TagEntity.isHidden ==
  /// true`, Tâche 25, voir DECISIONS.md) — utilisé exclusivement par
  /// `MyEyesOnlyScreen` (`hiddenTagsProvider`), jamais par `TagsScreen` ni
  /// l'autocomplétion.
  Future<List<String>> getHiddenTagNames() async {
    final entities = await _tagLocalDatasource.getAll();
    return entities
        .where((entity) => entity.isHidden)
        .map((entity) => entity.name)
        .toList();
  }

  /// Crée un tag géré nommé [name]. No-op silencieux si un tag équivalent
  /// (comparaison insensible à la casse) existe déjà — pas d'exception,
  /// cohérent avec un bouton d'ajout qui ne doit jamais bloquer
  /// l'utilisateur sur un doublon trivial.
  ///
  /// Écriture locale immédiate (`isSynced: false`), puis tentative de
  /// synchronisation distante — même patron que
  /// `BookmarkRepository.createBookmark` (voir DECISIONS.md).
  Future<void> createTag(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final existing = await _tagLocalDatasource.findByName(trimmedName);
    if (existing != null) return;

    final now = DateTime.now();
    final entity = TagEntity()
      ..name = trimmedName
      ..remoteId = _uuid.v4()
      ..userId = _getCurrentUserId()
      ..createdAt = now
      ..updatedAt = now
      ..isSynced = false
      ..isDeletedLocally = false;
    await _tagLocalDatasource.upsert(entity);
    await _trySyncUpsert(entity);
  }

  /// Retourne le nombre de bookmarks actifs portant [name] — à appeler par
  /// la couche présentation *avant* [deleteTag], pour afficher ce chiffre
  /// dans une boîte de dialogue de confirmation (voir critère d'acceptation
  /// de la Tâche 15).
  Future<int> countBookmarksForTag(String name) async {
    final bookmarks = await _bookmarkLocalDatasource.findAllByTag(name);
    return bookmarks.length;
  }

  /// Renomme le tag [oldName] en [newName] : met à jour (ou crée, si
  /// [oldName] ne correspondait qu'à un tag dérivé sans [TagEntity]) le
  /// [TagEntity] correspondant, et propage le nouveau nom sur tous les
  /// `BookmarkEntity.tags` qui portaient l'ancien — dans une unique
  /// transaction Isar (voir doc de classe). Les bookmarks affectés sont
  /// marqués `isSynced: false` (déjà le cas depuis la Tâche 15, vérifié et
  /// confirmé lors de l'extension de synchronisation, voir DECISIONS.md) :
  /// `SyncService`/`BookmarkRepository.syncPendingChanges` les repoussent
  /// donc normalement, sans logique supplémentaire nécessaire ici.
  Future<void> renameTag(String oldName, String newName) async {
    final trimmedNewName = newName.trim();
    if (trimmedNewName.isEmpty) return;

    TagEntity? mutatedTag;
    await _isar.writeTxn(() async {
      final now = DateTime.now();
      final existingTag = await _tagLocalDatasource.findByName(oldName);
      if (existingTag != null) {
        existingTag
          ..name = trimmedNewName
          ..remoteId = existingTag.remoteId ?? _uuid.v4()
          ..userId = existingTag.userId ?? _getCurrentUserId()
          ..updatedAt = now
          ..isSynced = false;
        await _isar.tagEntitys.put(existingTag);
        mutatedTag = existingTag;
      } else {
        final createdTag = TagEntity()
          ..name = trimmedNewName
          ..remoteId = _uuid.v4()
          ..userId = _getCurrentUserId()
          ..createdAt = now
          ..updatedAt = now
          ..isSynced = false;
        await _isar.tagEntitys.put(createdTag);
        mutatedTag = createdTag;
      }

      final normalizedOldName = oldName.trim().toLowerCase();
      final affectedBookmarks = await _bookmarkLocalDatasource.findAllByTag(
        oldName,
      );
      for (final bookmark in affectedBookmarks) {
        bookmark
          ..tags = [
            for (final tag in bookmark.tags)
              tag.toLowerCase() == normalizedOldName ? trimmedNewName : tag,
          ]
          ..updatedAt = now
          ..isSynced = false;
        await _isar.bookmarkEntitys.put(bookmark);
      }
    });

    if (mutatedTag != null) await _trySyncUpsert(mutatedTag!);
  }

  /// Supprime le tag [name] : retire son [TagEntity] (s'il existe — un tag
  /// purement dérivé n'en a pas) et le retire de tous les
  /// `BookmarkEntity.tags` qui le portent — dans une unique transaction Isar
  /// (voir doc de classe).
  ///
  /// **Suppression douce (extension de synchronisation, voir DECISIONS.md)**
  /// : si le [TagEntity] existe, il est marqué `isDeletedLocally: true`
  /// plutôt que supprimé immédiatement d'Isar — même mécanisme que
  /// `BookmarkRepository.deleteBookmark` (voir SPEC.md section 13), pour ne
  /// jamais faire réapparaître un tag supprimé hors ligne après un
  /// [pullRemoteChanges] ultérieur. La suppression distante est tentée
  /// aussitôt après la transaction ; en cas de succès (ou d'absence de
  /// [TagEntity]/de session active), l'entité locale est retirée
  /// définitivement — sinon elle reste marquée en attente, reprise par
  /// [syncPendingChanges]. [TagLocalDatasource.findByName]/[getAll]
  /// excluent déjà les entités `isDeletedLocally: true` (voir leur doc), un
  /// tag en cours de suppression n'est donc jamais visible entre-temps.
  Future<void> deleteTag(String name) async {
    TagEntity? deletedTag;
    await _isar.writeTxn(() async {
      final existingTag = await _tagLocalDatasource.findByName(name);
      if (existingTag != null) {
        existingTag
          ..isDeletedLocally = true
          ..updatedAt = DateTime.now()
          ..isSynced = false;
        await _isar.tagEntitys.put(existingTag);
        deletedTag = existingTag;
      }

      final normalizedName = name.trim().toLowerCase();
      final affectedBookmarks = await _bookmarkLocalDatasource.findAllByTag(
        name,
      );
      final now = DateTime.now();
      for (final bookmark in affectedBookmarks) {
        bookmark
          ..tags = bookmark.tags
              .where((tag) => tag.toLowerCase() != normalizedName)
              .toList()
          ..updatedAt = now
          ..isSynced = false;
        await _isar.bookmarkEntitys.put(bookmark);
      }
    });

    if (deletedTag == null) return;
    if (deletedTag!.userId == null || deletedTag!.remoteId == null) return;

    try {
      await _remoteDatasource.delete(deletedTag!.remoteId!);
      await _isar.writeTxn(
        () => _isar.tagEntitys.delete(deletedTag!.isarId),
      );
    } on Exception catch (cause) {
      _logSyncFailure(TagRemoteSyncException(deletedTag!.name, cause));
    }
  }

  /// Masque le tag [name] (Tâche 25, voir DECISIONS.md) : crée son
  /// [TagEntity] s'il n'existe pas encore (tag purement dérivé, même logique
  /// que [renameTag]) et le marque `isHidden: true`, puis marque `isHidden:
  /// true` sur tous les `BookmarkEntity.tags` qui le portent (comparaison
  /// insensible à la casse) — dans une unique transaction Isar (voir doc de
  /// classe). S'applique aussi bien aux bookmarks déjà existants qu'à tout
  /// bookmark qui recevra ce tag plus tard (voir `BookmarkRepository`, qui
  /// consulte ce même [TagEntity.isHidden] à la création/édition).
  Future<void> hideTag(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    TagEntity? mutatedTag;
    await _isar.writeTxn(() async {
      final now = DateTime.now();
      final existingTag = await _tagLocalDatasource.findByName(trimmedName);
      if (existingTag != null) {
        existingTag
          ..isHidden = true
          ..remoteId = existingTag.remoteId ?? _uuid.v4()
          ..userId = existingTag.userId ?? _getCurrentUserId()
          ..updatedAt = now
          ..isSynced = false;
        await _isar.tagEntitys.put(existingTag);
        mutatedTag = existingTag;
      } else {
        final createdTag = TagEntity()
          ..name = trimmedName
          ..isHidden = true
          ..remoteId = _uuid.v4()
          ..userId = _getCurrentUserId()
          ..createdAt = now
          ..updatedAt = now
          ..isSynced = false;
        await _isar.tagEntitys.put(createdTag);
        mutatedTag = createdTag;
      }

      final affectedBookmarks = await _bookmarkLocalDatasource.findAllByTag(
        trimmedName,
      );
      for (final bookmark in affectedBookmarks) {
        bookmark
          ..isHidden = true
          ..updatedAt = now
          ..isSynced = false;
        await _isar.bookmarkEntitys.put(bookmark);
      }
    });

    if (mutatedTag != null) await _trySyncUpsert(mutatedTag!);
  }

  /// Démasque le tag [name] (symétrique de [hideTag]) : marque son
  /// [TagEntity] `isHidden: false`, puis démasque tous les
  /// `BookmarkEntity.tags` qui le portent — **sauf** ceux qui portent encore
  /// un autre tag masqué (revérifié via [TagLocalDatasource.hasAnyHiddenTag]
  /// après la mise à jour de ce [TagEntity], dans la même transaction),
  /// pour ne jamais rendre visible un bookmark que le masquage d'un autre
  /// tag continue légitimement de masquer.
  ///
  /// **Limite assumée, non résolue par cette tâche** (voir DECISIONS.md,
  /// entrée « Tâche 25 ») : si un bookmark est masqué à la fois
  /// individuellement (Tâche 24, `HiddenBookmarkMenuButton`/
  /// `AddToMyEyesOnlyScreen`) et via ce tag, démasquer le tag le rend
  /// visible à nouveau aussi — aucun mécanisme ne distingue *pourquoi* un
  /// bookmark est masqué.
  Future<void> unhideTag(String name) async {
    TagEntity? mutatedTag;
    await _isar.writeTxn(() async {
      final now = DateTime.now();
      final existingTag = await _tagLocalDatasource.findByName(name);
      if (existingTag != null) {
        existingTag
          ..isHidden = false
          ..remoteId = existingTag.remoteId ?? _uuid.v4()
          ..userId = existingTag.userId ?? _getCurrentUserId()
          ..updatedAt = now
          ..isSynced = false;
        await _isar.tagEntitys.put(existingTag);
        mutatedTag = existingTag;
      }

      final affectedBookmarks = await _bookmarkLocalDatasource.findAllByTag(
        name,
      );
      for (final bookmark in affectedBookmarks) {
        final stillHasHiddenTag = await _tagLocalDatasource.hasAnyHiddenTag(
          bookmark.tags,
        );
        if (stillHasHiddenTag) continue;

        bookmark
          ..isHidden = false
          ..updatedAt = now
          ..isSynced = false;
        await _isar.bookmarkEntitys.put(bookmark);
      }
    });

    if (mutatedTag != null) await _trySyncUpsert(mutatedTag!);
  }

  /// Tente de synchroniser [entity] vers Supabase via un upsert (voir doc de
  /// classe pour la justification de ne pas distinguer insert/update). Ne
  /// fait rien tant qu'aucune session active n'existe (`userId == null`,
  /// même garde-fou que `BookmarkRepository`, voir DECISIONS.md entrée
  /// « Tâche 5 ») — ce n'est pas un échec, juste un état "pas encore prêt à
  /// synchroniser".
  Future<void> _trySyncUpsert(TagEntity entity) async {
    if (entity.userId == null) return;

    try {
      await _remoteDatasource.upsert(_toRemoteMap(entity));
      entity.isSynced = true;
      await _tagLocalDatasource.upsert(entity);
    } on Exception catch (cause) {
      _logSyncFailure(TagRemoteSyncException(entity.name, cause));
    }
  }

  /// Rattrape toute écriture locale qui n'a pas encore atteint Supabase —
  /// appelé par `SyncService` à la reconnexion réseau et périodiquement,
  /// jamais par la couche présentation directement. Même patron que
  /// `BookmarkRepository.syncPendingChanges` (voir DECISIONS.md, entrée
  /// « Tâche 9 ») : les suppressions en attente sont traitées **avant** tout
  /// autre envoi.
  Future<void> syncPendingChanges() async {
    final pendingDeletions = await _tagLocalDatasource.getAllPendingDeletion();
    for (final entity in pendingDeletions) {
      if (entity.userId == null || entity.remoteId == null) continue;
      try {
        await _remoteDatasource.delete(entity.remoteId!);
        await _isar.writeTxn(() => _isar.tagEntitys.delete(entity.isarId));
      } on Exception catch (cause) {
        _logSyncFailure(TagRemoteSyncException(entity.name, cause));
      }
    }

    final pendingUploads = await _tagLocalDatasource.getAllPendingUpload();
    for (final entity in pendingUploads) {
      // Un TagEntity créé par une version antérieure de l'app (avant cette
      // extension de synchronisation) peut ne pas avoir de remoteId — voir
      // doc de classe de TagEntity.
      entity.remoteId ??= _uuid.v4();
      await _trySyncUpsert(entity);
    }
  }

  /// Rapatrie vers l'Isar local les tags distants absents ou plus récents
  /// que leur copie locale. Résolution de conflit **last-write-wins** sur
  /// `updated_at` (voir SPEC.md section 13, même politique que les
  /// bookmarks). Une entité locale déjà synchronisée mais absente des lignes
  /// distantes rapatriées a été supprimée depuis un autre appareil : elle
  /// est alors retirée localement aussi. Même patron que
  /// `BookmarkRepository.pullRemoteChanges` (voir DECISIONS.md, entrée
  /// « Tâche 9 »).
  Future<void> pullRemoteChanges() async {
    final remoteRows = await _remoteDatasource.selectAll();
    final remoteIds = <String>{};

    for (final row in remoteRows) {
      final remoteId = row['id'] as String;
      remoteIds.add(remoteId);
      final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);
      final existing = await _tagLocalDatasource.findByRemoteId(remoteId);

      if (existing == null) {
        await _tagLocalDatasource.upsert(_fromRemoteMap(row));
        continue;
      }
      if (existing.isDeletedLocally) {
        // Suppression locale en attente : ne pas ressusciter l'entité tant
        // que la suppression distante n'a pas été tentée (voir
        // syncPendingChanges).
        continue;
      }
      if (remoteUpdatedAt.isAfter(existing.updatedAt)) {
        await _tagLocalDatasource.upsert(
          _fromRemoteMap(row)..isarId = existing.isarId,
        );
      }
    }

    final syncedRemoteIds = await _tagLocalDatasource.getAllSyncedRemoteIds();
    for (final remoteId in syncedRemoteIds) {
      if (!remoteIds.contains(remoteId)) {
        final entity = await _tagLocalDatasource.findByRemoteId(remoteId);
        if (entity == null) continue;
        await _isar.writeTxn(() => _isar.tagEntitys.delete(entity.isarId));
      }
    }
  }

  /// Nombre de tags locaux pas encore associés à un compte (`userId ==
  /// null`) — sert à décider si la confirmation de rattachement
  /// (`link_local_data_prompt.dart`) doit être affichée après une connexion
  /// ou une inscription réussie. Même rôle que
  /// `BookmarkRepository.countLocalOnlyBookmarks` (voir DECISIONS.md,
  /// entrée « Tâche 28 »).
  Future<int> countLocalOnlyTags() {
    return _tagLocalDatasource.countWithoutUser();
  }

  /// Associe rétroactivement à [userId] tous les tags locaux pas encore liés
  /// à un compte (`userId == null`), et force `isSynced: false` sur chacun
  /// pour que `SyncService` les prenne en charge à son prochain passage —
  /// même mécanisme que `BookmarkRepository.linkLocalBookmarksToUser` (voir
  /// DECISIONS.md, entrée « Tâche 28 »). N'est appelée qu'après confirmation
  /// explicite de l'utilisateur (voir `link_local_data_prompt.dart`).
  Future<void> linkLocalTagsToUser(String userId) async {
    await _isar.writeTxn(() async {
      final entities = await _tagLocalDatasource.getAllWithoutUser();
      for (final entity in entities) {
        entity
          ..userId = userId
          ..remoteId = entity.remoteId ?? _uuid.v4()
          ..isSynced = false;
        await _isar.tagEntitys.put(entity);
      }
    });
  }

  /// Journalise un échec de synchronisation distant réel (jamais le cas
  /// "pas encore authentifié", filtré en amont) — au minimum un log
  /// explicite, jamais un `catch` silencieux (voir CONVENTIONS.md section
  /// Réponses API), même patron que `BookmarkRepository._logSyncFailure`.
  void _logSyncFailure(TagRemoteSyncException exception) {
    debugPrint('$exception');
  }

  Map<String, dynamic> _toRemoteMap(TagEntity entity) => {
    'id': entity.remoteId,
    'user_id': entity.userId,
    'name': entity.name,
    'is_hidden': entity.isHidden,
    'created_at': entity.createdAt.toIso8601String(),
    'updated_at': entity.updatedAt.toIso8601String(),
  };

  /// Reconstruit un [TagEntity] local à partir d'une ligne distante brute
  /// (voir [pullRemoteChanges]) — toujours marqué `isSynced: true` et
  /// `isDeletedLocally: false`, puisqu'il vient d'être lu depuis Supabase.
  TagEntity _fromRemoteMap(Map<String, dynamic> row) => TagEntity()
    ..remoteId = row['id'] as String
    ..userId = row['user_id'] as String?
    ..name = row['name'] as String
    ..isHidden = row['is_hidden'] as bool? ?? false
    ..createdAt = DateTime.parse(row['created_at'] as String)
    ..updatedAt = DateTime.parse(row['updated_at'] as String)
    ..isSynced = true
    ..isDeletedLocally = false;
}
