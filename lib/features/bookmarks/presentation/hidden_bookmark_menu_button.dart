import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bookmark_repository_provider.dart';
import '../domain/video_bookmark.dart';
import 'bookmark_list_provider.dart';

/// Actions proposées par [HiddenBookmarkMenuButton].
enum _HiddenBookmarkAction { unhide, delete }

/// Bouton de menu local à `MyEyesOnlyScreen` (Tâche 24, voir DECISIONS.md) :
/// propose "Ne plus masquer" et "Supprimer" pour un bookmark masqué.
///
/// Volontairement distinct de `showBookmarkContextMenu`
/// (`bookmark_context_menu.dart`), qui ne doit plus jamais exposer la
/// moindre trace du masquage (voir DECISIONS.md, ajustement de la Tâche 22
/// par la Tâche 24) : ce widget n'est importé que par
/// `my_eyes_only_screen.dart`, pour qu'aucun autre écran ne puisse par
/// erreur y donner accès.
class HiddenBookmarkMenuButton extends ConsumerWidget {
  /// Crée le bouton pour [bookmark], qui doit être masqué (`isHidden ==
  /// true`) — ce widget ne vérifie pas cette condition lui-même, à la
  /// charge de l'appelant (voir `MyEyesOnlyScreen`).
  const HiddenBookmarkMenuButton({super.key, required this.bookmark});

  /// Bookmark masqué concerné par ce menu.
  final VideoBookmark bookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_HiddenBookmarkAction>(
      onSelected: (action) => _handle(context, ref, action),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _HiddenBookmarkAction.unhide,
          child: Text('Ne plus masquer'),
        ),
        PopupMenuItem(
          value: _HiddenBookmarkAction.delete,
          child: Text('Supprimer'),
        ),
      ],
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    _HiddenBookmarkAction action,
  ) async {
    switch (action) {
      case _HiddenBookmarkAction.unhide:
        await _unhide(ref);
      case _HiddenBookmarkAction.delete:
        await _delete(context, ref);
    }
  }

  /// Démasque [bookmark] via `BookmarkRepository.updateBookmark`, puis
  /// rafraîchit [bookmarkListProvider] — le bookmark disparaît alors
  /// immédiatement de `MyEyesOnlyScreen` (filtrée sur `isHidden == true`).
  Future<void> _unhide(WidgetRef ref) async {
    final repository = await ref.read(bookmarkRepositoryProvider.future);
    await repository.updateBookmark(bookmark.copyWith(isHidden: false));
    await ref.read(bookmarkListProvider.notifier).refresh();
  }

  /// Demande confirmation ("cette action est définitive") avant de
  /// supprimer [bookmark] via `BookmarkRepository.deleteBookmark` — même
  /// dialogue que `bookmark_context_menu.dart`.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce bookmark ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final repository = await ref.read(bookmarkRepositoryProvider.future);
    await repository.deleteBookmark(bookmark.id);
    await ref.read(bookmarkListProvider.notifier).refresh();
  }
}
