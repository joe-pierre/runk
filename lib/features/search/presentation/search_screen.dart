import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_scaffold_key_provider.dart';
import '../../bookmarks/presentation/bookmark_card.dart';
import '../../bookmarks/presentation/bookmark_search_provider.dart';
import '../../bookmarks/presentation/bookmark_selection_controller.dart';
import '../../bookmarks/presentation/bulk_selection_toolbar.dart';
import '../../bookmarks/presentation/open_bookmark_action.dart';

/// Sélection multiple de cet écran (Tâche 26, voir DECISIONS.md) — instance
/// distincte de celle de `HomeScreen`, voir `BookmarkSelectionScope`.
const _selectionScope = BookmarkSelectionScope.search;

/// Écran de recherche full-text sur titre + tags (voir SPEC.md section 11).
///
/// Purement local : délègue à [bookmarkSearchProvider], qui n'interroge que
/// l'Isar local via `BookmarkRepository.searchBookmarks` — aucun appel
/// Supabase direct dans cet écran (voir contrainte de la Tâche 9). Réutilise
/// `BookmarkCard` pour l'affichage des résultats, comme `HomeScreen`.
///
/// **Mode sélection multiple (Tâche 26, voir DECISIONS.md) :** même
/// principe que `HomeScreen` — icône dédiée de l'`AppBar`, sélection portée
/// par sa propre instance de `BookmarkSelectionController` ([_selectionScope]
/// distinct de celui de `HomeScreen`), `BulkSelectionToolbar` en bas dès
/// qu'au moins un résultat est coché. Aucune action de masquage n'y est
/// jamais exposée (voir `BulkSelectionToolbar`).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(bookmarkSearchProvider(_query));
    final selection = ref.watch(
      bookmarkSelectionControllerProvider(_selectionScope),
    );
    final selectionNotifier = ref.read(
      bookmarkSelectionControllerProvider(_selectionScope).notifier,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () =>
              ref.read(appScaffoldKeyProvider).currentState?.openDrawer(),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rechercher par titre ou tag',
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        actions: [
          IconButton(
            icon: Icon(
              selection.isSelectionModeActive ? Icons.close : Icons.checklist,
            ),
            tooltip: selection.isSelectionModeActive
                ? 'Annuler la sélection'
                : 'Sélectionner des bookmarks',
            onPressed: selectionNotifier.toggleSelectionMode,
          ),
        ],
      ),
      bottomNavigationBar: selection.selectedIds.isEmpty
          ? null
          : const BulkSelectionToolbar(scope: _selectionScope),
      body: _query.trim().isEmpty
          ? Center(
              child: Text(
                'Tapez un titre ou un tag pour rechercher.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Impossible d\'effectuer la recherche.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              data: (bookmarks) {
                if (bookmarks.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun résultat pour "$_query".',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: BookmarkCard(
                        bookmark: bookmark,
                        onTap: () => openBookmark(context, ref, bookmark),
                        selectionMode: selection.isSelectionModeActive,
                        isSelected: selection.selectedIds.contains(bookmark.id),
                        onToggleSelection: (_) =>
                            selectionNotifier.toggleSelected(bookmark.id),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
