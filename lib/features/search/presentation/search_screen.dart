import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bookmarks/presentation/bookmark_card.dart';
import '../../bookmarks/presentation/bookmark_search_provider.dart';
import '../../bookmarks/presentation/open_bookmark_action.dart';

/// Écran de recherche full-text sur titre + tags (voir SPEC.md section 11).
///
/// Purement local : délègue à [bookmarkSearchProvider], qui n'interroge que
/// l'Isar local via `BookmarkRepository.searchBookmarks` — aucun appel
/// Supabase direct dans cet écran (voir contrainte de la Tâche 9). Réutilise
/// `BookmarkCard` pour l'affichage des résultats, comme `HomeScreen`.
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

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Rechercher par titre ou tag',
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
      ),
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
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
