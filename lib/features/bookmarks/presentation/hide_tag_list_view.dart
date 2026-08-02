import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tags/data/tag_repository_provider.dart';
import '../../tags/presentation/distinct_tags_provider.dart';
import '../../tags/presentation/hidden_tags_provider.dart';
import 'bookmark_list_provider.dart';

/// Mode "Tags" de `AddToMyEyesOnlyScreen` (Tâche 25, voir DECISIONS.md) :
/// liste des tags actuellement visibles ([distinctTagsProvider], qui exclut
/// déjà les tags masqués — voir sa doc de classe). Un tap sur un tag le
/// masque immédiatement via `TagRepository.hideTag` : cascade automatique
/// sur tous les bookmarks qui le portent, existants et futurs (voir doc de
/// `TagRepository.hideTag`).
///
/// Pas de confirmation intermédiaire — cohérent avec le "Masquer" déjà sans
/// confirmation ailleurs dans l'app (Tâches 22/24, `bookmark_context_menu`
/// historique) : masquer reste une action réversible depuis
/// `MyEyesOnlyScreen` (`HiddenTagListTile`), contrairement à une suppression
/// (`tags_screen.dart`, qui affiche `confirmTagDeletion`).
///
/// N'est jamais importé que par `add_to_my_eyes_only_screen.dart` — comme
/// `HiddenTagListTile`, ce widget n'apparaît jamais depuis le menu normal.
class HideTagListView extends ConsumerWidget {
  const HideTagListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(distinctTagsProvider);

    return tagsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          'Impossible de charger les tags.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      data: (tags) {
        if (tags.isEmpty) {
          return Center(
            child: Text(
              'Aucun tag à masquer.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return ListView.builder(
          itemCount: tags.length,
          itemBuilder: (context, index) {
            final tag = tags[index];
            return ListTile(
              leading: const Icon(Icons.label_outline),
              title: Text(tag),
              trailing: const Icon(Icons.visibility_off_outlined),
              onTap: () => _hideTag(ref, tag),
            );
          },
        );
      },
    );
  }

  /// Masque [tag] via `TagRepository.hideTag`, puis rafraîchit les trois
  /// providers affectés : le tag disparaît de cette liste et de
  /// `TagsScreen`/l'autocomplétion ([distinctTagsProvider]), réapparaît dans
  /// `MyEyesOnlyScreen` ([hiddenTagsProvider]), et les bookmarks qui le
  /// portaient disparaissent de `HomeScreen` ([bookmarkListProvider]).
  Future<void> _hideTag(WidgetRef ref, String tag) async {
    final tagRepository = await ref.read(tagRepositoryProvider.future);
    await tagRepository.hideTag(tag);
    ref.invalidate(distinctTagsProvider);
    ref.invalidate(hiddenTagsProvider);
    await ref.read(bookmarkListProvider.notifier).refresh();
  }
}
