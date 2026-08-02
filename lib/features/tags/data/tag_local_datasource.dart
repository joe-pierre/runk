import 'package:isar_community/isar.dart';

part 'tag_local_datasource.g.dart';

/// Modèle local (Isar) d'un tag géré indépendamment de tout bookmark (voir
/// DECISIONS.md, entrée « Tâche 15 — TagEntity : gestion indépendante des
/// tags »).
///
/// Avant cette collection, un tag n'existait que comme valeur dérivée de
/// `BookmarkEntity.tags` (voir `distinctTagsProvider`) — impossible donc de
/// créer un tag sans bookmark associé. `TagEntity` comble ce manque, mais ne
/// remplace pas `BookmarkEntity.tags` : les deux sources coexistent et sont
/// fusionnées à l'affichage (voir `distinct_tags_provider.dart`).
///
/// **Champs de synchronisation (extension tags remote sync, voir
/// DECISIONS.md) :** mêmes rôles que leurs homologues `BookmarkEntity` (Tâche
/// 9/28), avec une différence pour [remoteId] — voir sa doc. [createdAt] est
/// ajouté par cohérence avec `BookmarkEntity` et pour permettre un
/// round-trip complet de la ligne distante (`tags.created_at`) ; il n'est
/// utilisé par aucun tri (`TagsScreen`/`distinctTagsProvider` restent triés
/// par ordre alphabétique, voir `distinct_tags_provider.dart`).
@collection
class TagEntity {
  /// Identifiant interne Isar (auto-incrémenté).
  Id isarId = Isar.autoIncrement;

  /// Nom du tag, unique indépendamment de la casse (`'Cuisine'` et
  /// `'cuisine'` sont le même tag) — cohérent avec la déduplication déjà
  /// actée pour l'autocomplétion (voir DECISIONS.md, entrée « Tâche 13 »).
  @Index(unique: true, caseSensitive: false)
  late String name;

  /// Vrai si ce tag est masqué depuis l'espace privé "My Eyes Only" (Tâche
  /// 25, voir DECISIONS.md) : masque en cascade tous les bookmarks qui le
  /// portent, existants et futurs (voir `TagRepository.hideTag` et
  /// `BookmarkRepository.createBookmark`/`updateBookmark`). Jamais
  /// accessible ni visible depuis le menu normal (`TagsScreen`/
  /// `tag_action_dialogs.dart`), uniquement depuis l'espace privé déjà
  /// déverrouillé — même principe que `BookmarkEntity.isHidden` (Tâche 22).
  bool isHidden = false;

  /// Correspond à `tags.id` côté Supabase. **Nullable, contrairement à
  /// `BookmarkEntity.remoteId`** (toujours généré à la création) : cette
  /// collection existe depuis la Tâche 15, avant cette extension de
  /// synchronisation — un `TagEntity` créé par une version antérieure de
  /// l'app n'a jamais eu de `remoteId`. Isar assigne la valeur par défaut du
  /// type (`null`) aux lignes déjà persistées qui ne connaissaient pas ce
  /// champ, exactement comme `BookmarkEntity.canonicalUrl` (Tâche 31, voir
  /// DECISIONS.md) — aucune migration manuelle requise. `TagRepository`
  /// génère un `remoteId` à la volée (première écriture rencontrée après
  /// cette tâche, ou premier passage de [TagRepository.syncPendingChanges])
  /// pour ces entités historiques.
  @Index()
  String? remoteId;

  /// Correspond à `tags.user_id` — nullable tant qu'aucune authentification
  /// n'existe, même raisonnement que `BookmarkEntity.userId` (voir
  /// DECISIONS.md, entrée « Tâche 5 »).
  String? userId;

  /// `false` = en attente de synchronisation vers Supabase.
  bool isSynced = false;

  /// Suppression en attente de propagation vers Supabase (voir SPEC.md
  /// section 13, même mécanisme que `BookmarkEntity.isDeletedLocally`) —
  /// vérifié en priorité par `TagRepository.syncPendingChanges` avant toute
  /// suppression distante définitive.
  bool isDeletedLocally = false;

  late DateTime createdAt;
  late DateTime updatedAt;
}

/// Accès à la collection Isar `TagEntity`.
///
/// Responsabilité unique : lecture/écriture brutes dans Isar pour la
/// collection `TagEntity` elle-même, aucune logique de propagation vers
/// `BookmarkEntity` — celle-ci vit exclusivement dans `TagRepository`, seul
/// endroit qui compose une transaction Isar unique touchant les deux
/// collections (voir doc de classe de `TagRepository`).
class TagLocalDatasource {
  /// Crée le datasource à partir d'une instance [Isar] déjà ouverte, partagée
  /// avec `BookmarkLocalDatasource` (même instance, voir
  /// `bookmarkIsarProvider`) — condition nécessaire pour que `TagRepository`
  /// puisse composer une transaction unique sur les deux collections.
  TagLocalDatasource(this._isar);

  final Isar _isar;

  /// Retourne l'entité correspondant à [name] (comparaison insensible à la
  /// casse), à l'exclusion des tags marqués [TagEntity.isDeletedLocally]
  /// (suppression en attente de confirmation distante, voir doc de classe) —
  /// un tag en cours de suppression ne doit plus être trouvable, y compris
  /// avant que le passage de synchronisation suivant ne le retire
  /// définitivement. Retourne `null` si absente. Lecture pure (aucune
  /// transaction d'écriture ouverte) : peut être appelée aussi bien en
  /// dehors que depuis l'intérieur d'une transaction déjà active sur la même
  /// instance [Isar] (voir `TagRepository.renameTag`/`deleteTag`).
  Future<TagEntity?> findByName(String name) {
    return _isar.tagEntitys
        .filter()
        .nameEqualTo(name, caseSensitive: false)
        .and()
        .isDeletedLocallyEqualTo(false)
        .findFirst();
  }

  /// Retourne tous les tags gérés non supprimés localement (voir
  /// [findByName] pour la même exclusion).
  Future<List<TagEntity>> getAll() {
    return _isar.tagEntitys.filter().isDeletedLocallyEqualTo(false).findAll();
  }

  /// Retourne l'entité correspondant à [remoteId], ou `null` si absente —
  /// utilisé exclusivement par la synchronisation (`TagRepository`), jamais
  /// par la présentation.
  Future<TagEntity?> findByRemoteId(String remoteId) {
    return _isar.tagEntitys
        .filter()
        .remoteIdEqualTo(remoteId)
        .findFirst();
  }

  /// Insère ou remplace [entity] (upsert par [TagEntity.isarId]).
  ///
  /// Ouvre sa propre transaction — ne doit **jamais** être appelée depuis
  /// l'intérieur d'une transaction déjà active (Isar ne supporte pas les
  /// transactions imbriquées, voir doc de classe de `TagRepository`) ; dans
  /// ce cas, écrire directement via `Isar.tagEntitys.put(...)` sur
  /// l'instance partagée.
  Future<void> upsert(TagEntity entity) {
    return _isar.writeTxn(() => _isar.tagEntitys.put(entity));
  }

  /// Retourne vrai si au moins un nom parmi [tagNames] correspond à un
  /// [TagEntity] marqué `isHidden: true` (comparaison insensible à la casse,
  /// même logique que [findByName]) — utilisé par `BookmarkRepository` pour
  /// masquer automatiquement un bookmark qui reçoit un tag masqué, à la
  /// création comme à l'édition (voir DECISIONS.md, entrée « Tâche 25 »).
  /// Lecture pure (aucune transaction d'écriture ouverte) : peut être
  /// appelée aussi bien en dehors que depuis l'intérieur d'une transaction
  /// déjà active sur la même instance [Isar].
  Future<bool> hasAnyHiddenTag(List<String> tagNames) async {
    for (final tagName in tagNames) {
      final entity = await findByName(tagName);
      if (entity != null && entity.isHidden) return true;
    }
    return false;
  }

  /// Retourne les entités créées/modifiées localement en attente d'envoi vers
  /// Supabase (`isSynced: false`), à l'exclusion de celles déjà marquées pour
  /// suppression — même rôle que `BookmarkLocalDatasource.getAllPendingUpload`
  /// (voir sa doc), utilisé par `TagRepository.syncPendingChanges`.
  Future<List<TagEntity>> getAllPendingUpload() {
    return _isar.tagEntitys
        .filter()
        .isSyncedEqualTo(false)
        .and()
        .isDeletedLocallyEqualTo(false)
        .findAll();
  }

  /// Retourne les entités marquées `isDeletedLocally: true`, dont la
  /// suppression distante reste à confirmer — même rôle que
  /// `BookmarkLocalDatasource.getAllPendingDeletion` (voir sa doc).
  Future<List<TagEntity>> getAllPendingDeletion() {
    return _isar.tagEntitys.filter().isDeletedLocallyEqualTo(true).findAll();
  }

  /// Retourne les [TagEntity.remoteId] des entités déjà confirmées
  /// synchronisées et non supprimées localement — sert à
  /// `TagRepository.pullRemoteChanges` pour détecter un tag supprimé sur un
  /// autre appareil (absent des lignes distantes rapatriées, mais toujours
  /// présent localement), même rôle que
  /// `BookmarkLocalDatasource.getAllSyncedRemoteIds`.
  Future<List<String>> getAllSyncedRemoteIds() async {
    final entities = await _isar.tagEntitys
        .filter()
        .isSyncedEqualTo(true)
        .and()
        .isDeletedLocallyEqualTo(false)
        .findAll();
    return entities
        .map((entity) => entity.remoteId)
        .whereType<String>()
        .toList();
  }

  /// Retourne les entités pas encore associées à un compte (`userId ==
  /// null`), non supprimées localement — sert à la confirmation de
  /// rattachement rétroactif (voir `link_local_data_prompt.dart`) et à
  /// `TagRepository.linkLocalTagsToUser`. Même rôle que
  /// `BookmarkLocalDatasource.getAllWithoutUser`.
  Future<List<TagEntity>> getAllWithoutUser() {
    return _isar.tagEntitys
        .filter()
        .userIdIsNull()
        .and()
        .isDeletedLocallyEqualTo(false)
        .findAll();
  }

  /// Nombre d'entités que retournerait [getAllWithoutUser] — même rôle que
  /// `BookmarkLocalDatasource.countWithoutUser`.
  Future<int> countWithoutUser() {
    return _isar.tagEntitys
        .filter()
        .userIdIsNull()
        .and()
        .isDeletedLocallyEqualTo(false)
        .count();
  }
}
