import 'package:isar_community/isar.dart';

import '../../bookmarks/data/bookmark_local_datasource.dart';
import 'tag_local_datasource.dart';

/// Point d'entrée unique entre la couche présentation et la gestion
/// indépendante des tags (Isar local uniquement — aucun tag n'est
/// aujourd'hui synchronisé vers Supabase, seuls les bookmarks le sont via
/// `BookmarkRepository`).
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
/// composée ici.
///
/// Aucun widget n'accède directement à Isar — uniquement via ce repository
/// (voir CONVENTIONS.md section Réponses API), au même titre que
/// `BookmarkRepository` pour les bookmarks.
class TagRepository {
  /// Crée le repository à partir de l'instance [Isar] partagée avec les
  /// bookmarks et des deux datasources correspondants.
  TagRepository({
    required Isar isar,
    required TagLocalDatasource tagLocalDatasource,
    required BookmarkLocalDatasource bookmarkLocalDatasource,
  }) : _isar = isar,
       _tagLocalDatasource = tagLocalDatasource,
       _bookmarkLocalDatasource = bookmarkLocalDatasource;

  final Isar _isar;
  final TagLocalDatasource _tagLocalDatasource;
  final BookmarkLocalDatasource _bookmarkLocalDatasource;

  /// Retourne les noms de tous les tags gérés (ayant un [TagEntity]),
  /// utilisé par `distinctTagsProvider` pour fusionner avec les tags dérivés
  /// des bookmarks (voir DECISIONS.md, entrée « Tâche 15 »).
  Future<List<String>> getManagedTagNames() async {
    final entities = await _tagLocalDatasource.getAll();
    return entities.map((entity) => entity.name).toList();
  }

  /// Crée un tag géré nommé [name]. No-op silencieux si un tag équivalent
  /// (comparaison insensible à la casse) existe déjà — pas d'exception,
  /// cohérent avec un bouton d'ajout qui ne doit jamais bloquer
  /// l'utilisateur sur un doublon trivial.
  Future<void> createTag(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final existing = await _tagLocalDatasource.findByName(trimmedName);
    if (existing != null) return;

    await _tagLocalDatasource.upsert(TagEntity()..name = trimmedName);
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
  /// transaction Isar (voir doc de classe).
  Future<void> renameTag(String oldName, String newName) async {
    final trimmedNewName = newName.trim();
    if (trimmedNewName.isEmpty) return;

    await _isar.writeTxn(() async {
      final existingTag = await _tagLocalDatasource.findByName(oldName);
      if (existingTag != null) {
        existingTag.name = trimmedNewName;
        await _isar.tagEntitys.put(existingTag);
      } else {
        await _isar.tagEntitys.put(TagEntity()..name = trimmedNewName);
      }

      final normalizedOldName = oldName.trim().toLowerCase();
      final affectedBookmarks = await _bookmarkLocalDatasource.findAllByTag(
        oldName,
      );
      final now = DateTime.now();
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
  }

  /// Supprime le tag [name] : retire son [TagEntity] (s'il existe — un tag
  /// purement dérivé n'en a pas) et le retire de tous les
  /// `BookmarkEntity.tags` qui le portent — dans une unique transaction Isar
  /// (voir doc de classe).
  Future<void> deleteTag(String name) async {
    await _isar.writeTxn(() async {
      final existingTag = await _tagLocalDatasource.findByName(name);
      if (existingTag != null) {
        await _isar.tagEntitys.delete(existingTag.isarId);
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
  }
}
