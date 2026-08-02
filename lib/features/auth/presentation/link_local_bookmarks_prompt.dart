import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bookmarks/data/bookmark_repository_provider.dart';
import '../../bookmarks/presentation/bookmark_list_provider.dart';

/// Affiche, si nécessaire, la confirmation de rattachement rétroactif des
/// bookmarks locaux créés hors ligne à [userId] (Tâche 28, voir
/// DECISIONS.md) — appelée par `AppDrawer` à chaque transition "aucune
/// session" → "session active", que ce soit après une connexion ou une
/// inscription.
///
/// Ne fait strictement rien (aucune boîte de dialogue) si aucun bookmark
/// local n'a `userId == null` : la confirmation ne doit jamais apparaître
/// sans raison (voir contrainte explicite de la Tâche 28 — "vérifier le
/// compte avant d'afficher quoi que ce soit"). N'appelle
/// `BookmarkRepository.linkLocalBookmarksToUser` qu'après un clic explicite
/// sur "Associer" — aucun rattachement automatique, sans exception.
Future<void> promptToLinkLocalBookmarks(
  BuildContext context,
  WidgetRef ref,
  String userId,
) async {
  final repository = await ref.read(bookmarkRepositoryProvider.future);
  final unlinkedCount = await repository.countLocalOnlyBookmarks();
  if (unlinkedCount == 0 || !context.mounted) return;

  final plural = unlinkedCount > 1 ? 's' : '';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Bookmarks créés hors ligne'),
      content: Text(
        'Associer les $unlinkedCount bookmark$plural créé$plural hors '
        'ligne à ce compte ?',
      ),
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

  await repository.linkLocalBookmarksToUser(userId);
  await ref.read(bookmarkListProvider.notifier).refresh();
}
