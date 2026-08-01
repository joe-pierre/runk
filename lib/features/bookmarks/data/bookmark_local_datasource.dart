import 'package:isar_community/isar.dart';

part 'bookmark_local_datasource.g.dart';

/// Modèle local (Isar) d'un bookmark — miroir de `VideoBookmark` avec des
/// champs additionnels propres à la persistance et à la synchronisation
/// offline-first (voir SPEC.md section 3.3).
@collection
class BookmarkEntity {
  /// Identifiant interne Isar (auto-incrémenté), distinct de [remoteId].
  Id isarId = Isar.autoIncrement;

  /// Correspond à `bookmarks.id` côté Supabase — c'est cet identifiant que
  /// connaît la couche applicative (`VideoBookmark.id`), jamais [isarId].
  @Index(unique: true)
  late String remoteId;

  /// Identifiant de l'utilisateur propriétaire (`bookmarks.user_id` côté
  /// Supabase), nullable tant qu'aucune authentification n'est en place
  /// (Phase 6 du TODO) : un bookmark créé hors ligne avant toute connexion
  /// doit pouvoir être stocké localement sans valeur ici. Rempli
  /// rétroactivement une fois l'utilisateur authentifié (voir DECISIONS.md,
  /// entrée "Tâche 5 — user_id absent avant l'authentification").
  String? userId;

  late String url;
  String? title;
  String? thumbnailUrl;
  late String source;
  bool isPartial = false;

  /// Vrai si ce bookmark est masqué dans la section "My Eyes Only" (Tâche
  /// 22, voir DECISIONS.md) — synchronisé avec Supabase comme les autres
  /// champs, contrairement au code d'accès local (`MyEyesOnlyService`).
  bool isHidden = false;
  List<String> tags = [];
  String? note;
  late DateTime createdAt;
  late DateTime updatedAt;

  /// `false` = en attente de synchronisation vers Supabase.
  bool isSynced = false;

  /// Suppression en attente de propagation vers Supabase (voir SPEC.md
  /// section 13) — vérifié en priorité par le futur `sync_service.dart`
  /// avant toute suppression distante définitive.
  bool isDeletedLocally = false;
}

/// Accès à la collection Isar `BookmarkEntity`.
///
/// Responsabilité unique : lecture/écriture brutes dans Isar, aucune
/// logique de synchronisation ni de mapping vers `VideoBookmark` — celles-ci
/// vivent exclusivement dans `BookmarkRepository`.
class BookmarkLocalDatasource {
  /// Crée le datasource à partir d'une instance [Isar] déjà ouverte
  /// (injectée pour permettre un Isar de test en mémoire, voir
  /// `bookmark_repository_test.dart`).
  BookmarkLocalDatasource(this._isar);

  final Isar _isar;

  /// Insère ou remplace [entity] (upsert par [BookmarkEntity.isarId]).
  Future<void> upsert(BookmarkEntity entity) {
    return _isar.writeTxn(() => _isar.bookmarkEntitys.put(entity));
  }

  /// Retourne l'entité correspondant à [remoteId], ou `null` si absente.
  Future<BookmarkEntity?> findByRemoteId(String remoteId) {
    return _isar.bookmarkEntitys.filter().remoteIdEqualTo(remoteId).findFirst();
  }

  /// Retourne tous les bookmarks non supprimés localement, triés par date de
  /// création décroissante (voir SPEC.md section 11 — écran Home).
  Future<List<BookmarkEntity>> getAllActive() {
    return _isar.bookmarkEntitys
        .filter()
        .isDeletedLocallyEqualTo(false)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Supprime définitivement l'entité correspondant à [remoteId] de la base
  /// locale, si elle existe.
  Future<void> deleteByRemoteId(String remoteId) async {
    final entity = await findByRemoteId(remoteId);
    if (entity == null) return;
    await _isar.writeTxn(() => _isar.bookmarkEntitys.delete(entity.isarId));
  }

  /// Retourne les entités créées/modifiées localement en attente d'envoi vers
  /// Supabase (`isSynced: false`), à l'exclusion de celles déjà marquées pour
  /// suppression (voir [getAllPendingDeletion]) — utilisé par
  /// `SyncService` (Tâche 9) pour son rattrapage périodique.
  Future<List<BookmarkEntity>> getAllPendingUpload() {
    return _isar.bookmarkEntitys
        .filter()
        .isSyncedEqualTo(false)
        .and()
        .isDeletedLocallyEqualTo(false)
        .findAll();
  }

  /// Retourne les entités marquées `isDeletedLocally: true`, dont la
  /// suppression distante reste à confirmer (voir SPEC.md section 13) —
  /// vérifiées en priorité par `SyncService` avant tout autre envoi.
  Future<List<BookmarkEntity>> getAllPendingDeletion() {
    return _isar.bookmarkEntitys
        .filter()
        .isDeletedLocallyEqualTo(true)
        .findAll();
  }

  /// Retourne les [BookmarkEntity.remoteId] des entités déjà confirmées
  /// synchronisées et non supprimées localement — sert à `SyncService` pour
  /// détecter un bookmark supprimé sur un autre appareil (absent des lignes
  /// distantes rapatriées, mais toujours présent localement).
  Future<List<String>> getAllSyncedRemoteIds() async {
    final entities = await _isar.bookmarkEntitys
        .filter()
        .isSyncedEqualTo(true)
        .and()
        .isDeletedLocallyEqualTo(false)
        .findAll();
    return entities.map((entity) => entity.remoteId).toList();
  }

  /// Retourne tous les bookmarks actifs portant [tagName] (comparaison
  /// insensible à la casse) — utilisé par `TagRepository` (voir DECISIONS.md,
  /// entrée « Tâche 15 ») pour compter/lister les bookmarks impactés par un
  /// renommage ou une suppression de tag. Lecture pure (aucune transaction
  /// d'écriture ouverte) : peut être appelée depuis l'intérieur d'une
  /// transaction déjà active sur la même instance [Isar].
  Future<List<BookmarkEntity>> findAllByTag(String tagName) {
    return _isar.bookmarkEntitys
        .filter()
        .isDeletedLocallyEqualTo(false)
        .and()
        .tagsElementEqualTo(tagName, caseSensitive: false)
        .findAll();
  }

  /// Recherche full-text locale sur le titre ou les tags (voir SPEC.md
  /// section 11 — écran Recherche) : aucune requête réseau, la donnée locale
  /// est la seule source consultée. Insensible à la casse, résultats triés
  /// par date de création décroissante.
  ///
  /// Exclut systématiquement les entités `isHidden: true` (section "My Eyes
  /// Only", Tâche 22) — la recherche n'a aucune raison légitime de faire
  /// remonter un bookmark masqué, y compris si aucun code n'a encore été
  /// saisi dans la session (voir DECISIONS.md, entrée "Tâche 23"). Ce filtre
  /// n'est pas paramétrable depuis l'appelant : aucun bookmark masqué ne doit
  /// pouvoir être retrouvé via cette méthode.
  Future<List<BookmarkEntity>> searchByTitleOrTags(String query) {
    return _isar.bookmarkEntitys
        .filter()
        .isDeletedLocallyEqualTo(false)
        .and()
        .isHiddenEqualTo(false)
        .and()
        .group(
          (filterBuilder) => filterBuilder
              .titleContains(query, caseSensitive: false)
              .or()
              .tagsElementContains(query, caseSensitive: false),
        )
        .sortByCreatedAtDesc()
        .findAll();
  }
}
