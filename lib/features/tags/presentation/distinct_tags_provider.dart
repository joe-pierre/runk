import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../bookmarks/presentation/bookmark_list_provider.dart';
import '../data/tag_repository_provider.dart';

part 'distinct_tags_provider.g.dart';

/// Expose la liste fusionnée des tags distincts, triés par ordre
/// alphabétique insensible à la casse (voir SPEC.md section 11 — écran
/// Tags).
///
/// Fusionne deux sources (voir DECISIONS.md, entrée « Tâche 15 ») :
/// - les tags **dérivés** de [bookmarkListProvider] (portés par au moins un
///   bookmark **visible**, `isHidden == false` — voir ci-dessous) ;
/// - les tags **gérés** via `TagRepository` (un `TagEntity` peut exister
///   sans aucun bookmark associé), déjà filtrés sur `isHidden == false` par
///   `TagRepository.getManagedTagNames()`.
///
/// **Exclusion des tags masqués (Tâche 25, corrige un bug préexistant
/// documenté en Tâche 23) :** avant cette tâche, les tags étaient dérivés de
/// *tous* les bookmarks retournés par [bookmarkListProvider], y compris ceux
/// `isHidden == true` — un tag porté uniquement par des bookmarks masqués
/// apparaissait donc dans `TagsScreen`/l'autocomplétion, révélant l'existence
/// d'un bookmark masqué sans le code "My Eyes Only" (voir DECISIONS.md,
/// entrée « Tâche 23 »). Filtré ici sur `!bookmark.isHidden` avant dérivation
/// — en plus du filtrage des `TagEntity.isHidden == true` eux-mêmes,
/// désormais géré par `TagRepository.getManagedTagNames()`.
///
/// Déduplication insensible à la casse (cohérent avec `TagInputField`,
/// DECISIONS.md entrée « Tâche 13 ») ; en cas de collision, la casse
/// affichée est celle du tag **géré** quand il existe pour ce nom normalisé
/// (décision actée en Phase A de la Tâche 15) — un tag purement dérivé sans
/// `TagEntity` correspondant garde sa casse telle que tapée dans un
/// bookmark. Ne fait aucun accès propre à Isar : délègue entièrement à
/// [bookmarkListProvider] et [tagRepositoryProvider] (voir CONVENTIONS.md
/// section Partials / Frontend).
@riverpod
Future<List<String>> distinctTags(Ref ref) async {
  final bookmarks = await ref.watch(bookmarkListProvider.future);
  final tagRepository = await ref.watch(tagRepositoryProvider.future);
  final managedTagNames = await tagRepository.getManagedTagNames();

  final derivedTagNames = <String>{};
  for (final bookmark in bookmarks.where((bookmark) => !bookmark.isHidden)) {
    derivedTagNames.addAll(bookmark.tags);
  }

  final managedByNormalizedName = <String, String>{
    for (final name in managedTagNames) name.toLowerCase(): name,
  };

  final mergedByNormalizedName = <String, String>{};
  for (final name in derivedTagNames) {
    final normalizedName = name.toLowerCase();
    mergedByNormalizedName[normalizedName] =
        managedByNormalizedName[normalizedName] ?? name;
  }
  for (final entry in managedByNormalizedName.entries) {
    mergedByNormalizedName.putIfAbsent(entry.key, () => entry.value);
  }

  final sortedTags = mergedByNormalizedName.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return sortedTags;
}
