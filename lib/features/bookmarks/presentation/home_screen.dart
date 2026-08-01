import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bookmark_card.dart';
import 'bookmark_context_menu.dart';
import 'bookmark_list_provider.dart';
import 'bookmark_tag_filter_provider.dart';
import 'clipboard_suggestion_banner.dart';
import 'manual_add_dialog.dart';
import 'open_bookmark_action.dart';

/// Écran d'accueil : liste chronologique (date de création décroissante) de
/// tous les bookmarks non supprimés (voir SPEC.md section 11).
///
/// Purement présentationnel : lit [bookmarkListProvider] et affiche l'état
/// correspondant (chargement, erreur, liste), ne décide jamais lui-même
/// comment récupérer ou trier les bookmarks (voir CONVENTIONS.md section
/// Partials / Frontend). Affiche `ClipboardSuggestionBanner` en haut de
/// l'écran (voir SPEC.md section 11) — celle-ci ne prend aucune place tant
/// qu'aucune suggestion n'est active. Un tap sur une carte délègue la
/// réouverture à `DeepLinkService.openInSource` (voir SPEC.md section 4
/// règle 5) — l'écran ne décide lui-même d'aucun schéma natif ni fallback,
/// il se contente de transmettre le résultat à l'utilisateur.
///
/// Si [bookmarkTagFilterProvider] est actif (venant de `TagsScreen`), filtre
/// la liste sur ce tag et affiche un chip permettant de retirer le filtre —
/// `BookmarkCard` reste le seul widget d'affichage d'un bookmark, aucune
/// duplication (voir contrainte de la Tâche 9).
///
/// Le bouton flottant "+" ouvre `ManualAddDialog`, troisième voie d'entrée
/// d'un bookmark équivalente au Share Intent et à la suggestion clipboard
/// (voir SPEC.md section 11).
///
/// Un appui long sur une carte délègue à `showBookmarkContextMenu` (Tâche
/// 21) l'ouverture du menu contextuel (modifier les tags / supprimer) —
/// geste distinct du tap simple, sans interférence (voir `BookmarkCard`).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkListProvider);
    final tagFilter = ref.watch(bookmarkTagFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Runk')),
      body: Column(
        children: [
          const ClipboardSuggestionBanner(),
          if (tagFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text('Filtré par : $tagFilter'),
                  onDeleted: () =>
                      ref.read(bookmarkTagFilterProvider.notifier).clear(),
                ),
              ),
            ),
          Expanded(
            child: bookmarksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Impossible de charger vos bookmarks.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              data: (allBookmarks) {
                final bookmarks = tagFilter == null
                    ? allBookmarks
                    : allBookmarks
                          .where((bookmark) => bookmark.tags.contains(tagFilter))
                          .toList();
                if (bookmarks.isEmpty) {
                  return Center(
                    child: Text(
                      tagFilter == null
                          ? 'Partagez une vidéo vers Runk pour commencer.'
                          : 'Aucun bookmark avec ce tag.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(bookmarkListProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = bookmarks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BookmarkCard(
                          bookmark: bookmark,
                          onTap: () => openBookmark(context, ref, bookmark),
                          onLongPress: () =>
                              showBookmarkContextMenu(context, ref, bookmark),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ManualAddDialog.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
