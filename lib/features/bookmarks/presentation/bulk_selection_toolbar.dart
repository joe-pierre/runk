import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bookmark_repository_provider.dart';
import 'bookmark_list_provider.dart';
import 'bookmark_selection_controller.dart';
import 'tag_input_field.dart';

/// Barre d'actions groupées affichée en bas de l'écran quand au moins un
/// bookmark est sélectionné (mode sélection multiple, Tâche 26, voir
/// DECISIONS.md) : "Supprimer (N)" et "Ajouter un tag (N)".
///
/// Paramétrée par [scope] (voir la doc de classe de `BookmarkSelectionController`
/// / `BookmarkSelectionScope`) — `home` est la seule instance appelante
/// depuis la Tâche 30 (suppression de `SearchScreen`, voir DECISIONS.md), le
/// paramètre est conservé pour ne pas re-designer ce widget si un second
/// écran de sélection multiple apparaît plus tard. Porte toute la logique de
/// mutation groupée
/// (`BookmarkRepository.deleteBookmarks`/`addTagsToBookmarks` puis
/// rafraîchissement de [bookmarkListProvider]) — les écrans appelants
/// restent purement présentationnels (voir CONVENTIONS.md section Partials /
/// Frontend).
///
/// Volontairement dépourvue de toute action de masquage "My Eyes Only" (voir
/// DECISIONS.md, entrée « Tâche 26 ») : seules "Supprimer" et "Ajouter un
/// tag" sont proposées ici, jamais "Masquer" — une action de masquage
/// visible dans l'usage courant de l'app révélerait l'existence de la
/// fonctionnalité (voir Tâche 24).
class BulkSelectionToolbar extends ConsumerWidget {
  /// Crée la barre pour la sélection portée par [scope].
  const BulkSelectionToolbar({super.key, required this.scope});

  /// Écran propriétaire de la sélection affichée.
  final BookmarkSelectionScope scope;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Set<String> ids,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Supprimer ${ids.length} bookmarks ?'),
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
    await repository.deleteBookmarks(ids.toList());
    await _finishBulkAction(ref);
  }

  Future<void> _addTag(
    BuildContext context,
    WidgetRef ref,
    Set<String> ids,
  ) async {
    final tagsToAdd = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => _AddTagsDialog(bookmarkCount: ids.length),
    );
    if (tagsToAdd == null || tagsToAdd.isEmpty || !context.mounted) return;

    final repository = await ref.read(bookmarkRepositoryProvider.future);
    await repository.addTagsToBookmarks(ids.toList(), tagsToAdd);
    await _finishBulkAction(ref);
  }

  /// Quitte automatiquement le mode sélection et rafraîchit
  /// [bookmarkListProvider] après une action groupée réussie (voir critère
  /// d'acceptation de la Tâche 26).
  Future<void> _finishBulkAction(WidgetRef ref) async {
    ref
        .read(bookmarkSelectionControllerProvider(scope).notifier)
        .toggleSelectionMode();
    await ref.read(bookmarkListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(bookmarkSelectionControllerProvider(scope));
    final ids = selection.selectedIds;

    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: () => _delete(context, ref, ids),
            icon: const Icon(Icons.delete_outline),
            label: Text('Supprimer (${ids.length})'),
          ),
          TextButton.icon(
            onPressed: () => _addTag(context, ref, ids),
            icon: const Icon(Icons.label_outline),
            label: Text('Ajouter un tag (${ids.length})'),
          ),
        ],
      ),
    );
  }
}

/// Dialogue de saisie des tags à ajouter aux [bookmarkCount] bookmarks
/// sélectionnés — réutilise [TagInputField] comme `_EditTagsDialog` de
/// `bookmark_context_menu.dart` (Tâche 21), avec une liste initialement
/// vide : les tags saisis ici s'ajoutent à ceux déjà présents sur chaque
/// bookmark, jamais un remplacement (voir DECISIONS.md, entrée « Tâche 26 »).
class _AddTagsDialog extends StatefulWidget {
  const _AddTagsDialog({required this.bookmarkCount});

  /// Nombre de bookmarks sélectionnés, affiché dans le titre du dialogue.
  final int bookmarkCount;

  @override
  State<_AddTagsDialog> createState() => _AddTagsDialogState();
}

class _AddTagsDialogState extends State<_AddTagsDialog> {
  var _tags = <String>[];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ajouter un tag à ${widget.bookmarkCount} bookmarks'),
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
