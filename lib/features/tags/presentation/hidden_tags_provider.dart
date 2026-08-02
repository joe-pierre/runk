import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/tag_repository_provider.dart';

part 'hidden_tags_provider.g.dart';

/// Expose les noms des tags masqués (`TagEntity.isHidden == true`, Tâche 25,
/// voir DECISIONS.md), triés par ordre alphabétique insensible à la casse —
/// symétrique de `distinctTagsProvider`, qui les exclut au contraire.
///
/// Consommé uniquement par `MyEyesOnlyScreen`
/// (`features/bookmarks/presentation/`, via `HiddenTagListTile`) : jamais
/// par `TagsScreen` ni aucun écran de navigation normale — le masquage de
/// tag ne doit jamais y apparaître (voir DECISIONS.md, entrée « Tâche 25 »).
/// Ne fait aucun accès propre à Isar : délègue entièrement à
/// [tagRepositoryProvider] (voir CONVENTIONS.md section Partials / Frontend).
@riverpod
Future<List<String>> hiddenTags(Ref ref) async {
  final tagRepository = await ref.watch(tagRepositoryProvider.future);
  final names = await tagRepository.getHiddenTagNames();
  return names..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}
