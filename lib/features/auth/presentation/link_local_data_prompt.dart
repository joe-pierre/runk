import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bookmarks/data/bookmark_repository_provider.dart';
import '../../bookmarks/presentation/bookmark_list_provider.dart';
import '../../tags/data/tag_repository_provider.dart';
import '../../tags/presentation/distinct_tags_provider.dart';

/// Affiche, si nécessaire, la confirmation de rattachement rétroactif des
/// bookmarks **et** tags locaux créés hors ligne à [userId] — appelée par
/// `AppDrawer` à chaque transition "aucune session" → "session active", que
/// ce soit après une connexion ou une inscription.
///
/// **Extension aux tags (voir DECISIONS.md) :** à l'origine (Tâche 28) cette
/// fonction ne couvrait que les bookmarks (`promptToLinkLocalBookmarks`,
/// `link_local_bookmarks_prompt.dart`) — renommée avec l'ajout de la
/// synchronisation des tags, pour ne pas laisser un nom de fichier/fonction
/// trompeur (voir CONVENTIONS.md, règle de nommage explicite). **Une seule
/// boîte de dialogue** couvre les deux, plutôt que deux confirmations
/// séquentielles : empiler deux `AlertDialog` à chaque connexion aurait été
/// une régression d'UX pour un cas qui, dans les faits, se produit toujours
/// ensemble (un même compte hors ligne accumule potentiellement des
/// bookmarks *et* des tags avant sa première connexion).
///
/// Ne fait strictement rien (aucune boîte de dialogue) si ni bookmark ni tag
/// local n'a `userId == null` : la confirmation ne doit jamais apparaître
/// sans raison (voir contrainte explicite de la Tâche 28 — "vérifier le
/// compte avant d'afficher quoi que ce soit"). N'appelle
/// `BookmarkRepository.linkLocalBookmarksToUser`/`TagRepository.
/// linkLocalTagsToUser` qu'après un clic explicite sur "Associer" — aucun
/// rattachement automatique, sans exception.
Future<void> promptToLinkLocalData(
  BuildContext context,
  WidgetRef ref,
  String userId,
) async {
  final bookmarkRepository = await ref.read(bookmarkRepositoryProvider.future);
  final tagRepository = await ref.read(tagRepositoryProvider.future);
  final unlinkedBookmarkCount = await bookmarkRepository
      .countLocalOnlyBookmarks();
  final unlinkedTagCount = await tagRepository.countLocalOnlyTags();
  if ((unlinkedBookmarkCount == 0 && unlinkedTagCount == 0) ||
      !context.mounted) {
    return;
  }

  final parts = <String>[];
  if (unlinkedBookmarkCount > 0) {
    final plural = unlinkedBookmarkCount > 1 ? 's' : '';
    parts.add('$unlinkedBookmarkCount bookmark$plural');
  }
  if (unlinkedTagCount > 0) {
    final plural = unlinkedTagCount > 1 ? 's' : '';
    parts.add('$unlinkedTagCount tag$plural');
  }
  final summary = parts.join(' et ');

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Données créées hors ligne'),
      content: Text('Associer $summary créés hors ligne à ce compte ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Associer'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  if (unlinkedBookmarkCount > 0) {
    await bookmarkRepository.linkLocalBookmarksToUser(userId);
    await ref.read(bookmarkListProvider.notifier).refresh();
  }
  if (unlinkedTagCount > 0) {
    await tagRepository.linkLocalTagsToUser(userId);
    ref.invalidate(distinctTagsProvider);
  }
}
