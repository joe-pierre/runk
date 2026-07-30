import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/deep_link_service_provider.dart';
import '../domain/video_bookmark.dart';
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
/// qu'aucune suggestion n'est active. Un tap sur une carte délègue la
/// réouverture à `DeepLinkService.openInSource` (voir SPEC.md section 4
/// règle 5) — l'écran ne décide lui-même d'aucun schéma natif ni fallback,
/// il se contente de transmettre le résultat à l'utilisateur.
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
                    itemBuilder: (context, index) {
                      final bookmark = bookmarks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BookmarkCard(
                          bookmark: bookmark,
                          onTap: () => _openBookmark(context, ref, bookmark),
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
    );
  }
}

/// Délègue la réouverture de [bookmark] à [DeepLinkService.openInSource], et
/// affiche un message d'erreur discret si ni le schéma natif ni le
/// navigateur n'ont pu ouvrir la vidéo (cas extrême, voir doc de
/// [DeepLinkService.openInSource]) — ne plante jamais l'écran.
Future<void> _openBookmark(
  BuildContext context,
  WidgetRef ref,
  VideoBookmark bookmark,
) async {
  final opened = await ref
      .read(deepLinkServiceProvider)
      .openInSource(bookmark.url, bookmark.source);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible d\'ouvrir cette vidéo.')),
    );
  }
}
