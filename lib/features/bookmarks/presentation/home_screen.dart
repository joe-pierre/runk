import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bookmark_card.dart';
import 'bookmark_list_provider.dart';
import 'clipboard_suggestion_banner.dart';

/// Écran d'accueil : liste chronologique (date de création décroissante) de
/// tous les bookmarks non supprimés (voir SPEC.md section 11).
///
/// Purement présentationnel : lit [bookmarkListProvider] et affiche l'état
/// correspondant (chargement, erreur, liste), ne décide jamais lui-même
/// comment récupérer ou trier les bookmarks (voir CONVENTIONS.md section
/// Partials / Frontend). Affiche `ClipboardSuggestionBanner` en haut de
/// l'écran (voir SPEC.md section 11) — celle-ci ne prend aucune place tant
/// qu'aucune suggestion n'est active.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Runk')),
      body: Column(
        children: [
          const ClipboardSuggestionBanner(),
          Expanded(
            child: bookmarksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Impossible de charger vos bookmarks.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              data: (bookmarks) {
                if (bookmarks.isEmpty) {
                  return Center(
                    child: Text(
                      'Partagez une vidéo vers Runk pour commencer.',
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
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: BookmarkCard(bookmark: bookmarks[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
