import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bookmark_repository_provider.dart';
import '../domain/video_bookmark.dart';
import 'bookmark_list_provider.dart';
import 'tag_input_field.dart';

/// Actions proposées par le menu contextuel d'un bookmark (voir
/// [showBookmarkContextMenu]).
enum _BookmarkMenuAction { editTags, toggleHidden, delete }

/// Affiche le menu contextuel d'un [bookmark] (déclenché par un appui long
/// sur une `BookmarkCard`, voir Tâche 21) : "Modifier les tags",
/// "Masquer"/"Ne plus masquer" (Tâche 22, voir DECISIONS.md) et
/// "Supprimer".
///
/// Porte toute la logique de mutation (appels à `bookmarkRepositoryProvider`
/// puis rafraîchissement de [bookmarkListProvider]) — `BookmarkCard` reste
/// `StatelessWidget` et purement présentationnelle, elle ne fait qu'appeler
/// cette fonction via un `onLongPress` fourni par l'écran appelant, sur le
/// même principe que `openBookmark` pour l'ouverture d'un bookmark (voir
/// CONVENTIONS.md section Partials / Frontend).
Future<void> showBookmarkContextMenu(
  BuildContext context,
  WidgetRef ref,
  VideoBookmark bookmark,
) async {
  final action = await showModalBottomSheet<_BookmarkMenuAction>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Modifier les tags'),
            onTap: () =>
                Navigator.of(sheetContext).pop(_BookmarkMenuAction.editTags),
          ),
          ListTile(
            leading: Icon(
              bookmark.isHidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            title: Text(bookmark.isHidden ? 'Ne plus masquer' : 'Masquer'),
            onTap: () => Navigator.of(
              sheetContext,
            ).pop(_BookmarkMenuAction.toggleHidden),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Supprimer'),
            onTap: () =>
                Navigator.of(sheetContext).pop(_BookmarkMenuAction.delete),
          ),
        ],
      ),
    ),
  );

  if (!context.mounted || action == null) return;

  switch (action) {
    case _BookmarkMenuAction.editTags:
      await _editTags(context, ref, bookmark);
    case _BookmarkMenuAction.toggleHidden:
      await _toggleHidden(ref, bookmark);
    case _BookmarkMenuAction.delete:
      await _delete(context, ref, bookmark);
  }
}

/// Inverse `VideoBookmark.isHidden` via `BookmarkRepository.updateBookmark`
/// (Tâche 22, voir DECISIONS.md) — masquer un bookmark le fait immédiatement
/// disparaître de `HomeScreen` (filtrée sur `isHidden == false`), sans
/// jamais le supprimer.
Future<void> _toggleHidden(WidgetRef ref, VideoBookmark bookmark) async {
  final repository = await ref.read(bookmarkRepositoryProvider.future);
  await repository.updateBookmark(
    bookmark.copyWith(isHidden: !bookmark.isHidden),
  );
  await ref.read(bookmarkListProvider.notifier).refresh();
}

/// Ouvre un dialogue réutilisant [TagInputField] pré-rempli avec les tags
/// actuels de [bookmark], puis valide via
/// `BookmarkRepository.updateBookmark`.
Future<void> _editTags(
  BuildContext context,
  WidgetRef ref,
  VideoBookmark bookmark,
) async {
  final newTags = await showDialog<List<String>>(
    context: context,
    builder: (dialogContext) => _EditTagsDialog(initialTags: bookmark.tags),
  );
  if (newTags == null || !context.mounted) return;

  final repository = await ref.read(bookmarkRepositoryProvider.future);
  await repository.updateBookmark(bookmark.copyWith(tags: newTags));
  await ref.read(bookmarkListProvider.notifier).refresh();
}

/// Demande confirmation ("cette action est définitive") avant de supprimer
/// [bookmark] via `BookmarkRepository.deleteBookmark`.
Future<void> _delete(
  BuildContext context,
  WidgetRef ref,
  VideoBookmark bookmark,
) async {
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

/// Dialogue de modification des tags d'un bookmark existant : enveloppe
/// [TagInputField] (composant contrôlé, voir sa doc de classe — pensé pour
/// être réutilisé ailleurs qu'`AddBookmarkSheet`) autour d'un état local
/// initialisé avec [initialTags], sans persister quoi que ce soit tant que
/// "Valider" n'a pas été pressé.
class _EditTagsDialog extends StatefulWidget {
  const _EditTagsDialog({required this.initialTags});

  /// Tags actuels du bookmark, avant modification.
  final List<String> initialTags;

  @override
  State<_EditTagsDialog> createState() => _EditTagsDialogState();
}

class _EditTagsDialogState extends State<_EditTagsDialog> {
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _tags = List.of(widget.initialTags);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier les tags'),
      content: SizedBox(
        width: double.maxFinite,
        child: TagInputField(
          tags: _tags,
          onTagsChanged: (tags) => setState(() => _tags = tags),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_tags),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
