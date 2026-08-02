import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tags/data/tag_repository_provider.dart';
import '../../tags/presentation/distinct_tags_provider.dart';
import '../../tags/presentation/hidden_tags_provider.dart';
import 'bookmark_list_provider.dart';

/// Ligne locale à `MyEyesOnlyScreen` (Tâche 25, voir DECISIONS.md) pour un
/// tag masqué (`TagEntity.isHidden == true`) : propose uniquement "Ne plus
/// masquer ce tag" (`TagRepository.unhideTag`).
///
/// Volontairement distinct de tout menu de `tags_screen.dart`/
/// `tag_action_dialogs.dart`, qui ne doivent jamais exposer la moindre trace
/// du masquage de tag (voir DECISIONS.md, entrée « Tâche 25 », même principe
/// que `HiddenBookmarkMenuButton` pour les bookmarks masqués individuellement,
/// Tâche 24) — ce widget n'est importé que par `my_eyes_only_screen.dart`.
class HiddenTagListTile extends ConsumerWidget {
  /// Crée la ligne pour [tagName], qui doit correspondre à un tag masqué —
  /// ce widget ne vérifie pas cette condition lui-même, à la charge de
  /// l'appelant (voir `MyEyesOnlyScreen`).
  const HiddenTagListTile({super.key, required this.tagName});

  /// Nom du tag masqué concerné par cette ligne.
  final String tagName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.label_off_outlined),
      title: Text(tagName),
      trailing: IconButton(
        tooltip: 'Ne plus masquer ce tag',
        icon: const Icon(Icons.visibility_outlined),
        onPressed: () => _unhide(ref),
      ),
    );
  }

  /// Démasque [tagName] via `TagRepository.unhideTag` — cascade sur tous les
  /// bookmarks qui le portent, sauf ceux qu'un autre tag encore masqué
  /// continue de masquer (voir doc de `TagRepository.unhideTag`) — puis
  /// rafraîchit les trois providers affectés : le tag disparaît de cette
  /// liste ([hiddenTagsProvider]), réapparaît dans `TagsScreen`/
  /// l'autocomplétion ([distinctTagsProvider]), et les bookmarks concernés
  /// peuvent réapparaître dans `HomeScreen` ([bookmarkListProvider]).
  Future<void> _unhide(WidgetRef ref) async {
    final tagRepository = await ref.read(tagRepositoryProvider.future);
    await tagRepository.unhideTag(tagName);
    ref.invalidate(hiddenTagsProvider);
    ref.invalidate(distinctTagsProvider);
    await ref.read(bookmarkListProvider.notifier).refresh();
  }
}
