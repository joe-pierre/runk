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
  /// casse), ou `null` si absente. Lecture pure (aucune transaction
  /// d'écriture ouverte) : peut être appelée aussi bien en dehors que depuis
  /// l'intérieur d'une transaction déjà active sur la même instance [Isar]
  /// (voir `TagRepository.renameTag`/`deleteTag`).
  Future<TagEntity?> findByName(String name) {
    return _isar.tagEntitys
        .filter()
        .nameEqualTo(name, caseSensitive: false)
        .findFirst();
  }

  /// Retourne tous les tags gérés.
  Future<List<TagEntity>> getAll() {
    return _isar.tagEntitys.where().findAll();
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
}
