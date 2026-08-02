import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/deep_link_service_provider.dart';
import '../domain/video_bookmark.dart';

/// Délègue la réouverture de [bookmark] à `DeepLinkService.openInSource`
/// (voir SPEC.md section 4 règle 5), et affiche un message d'erreur discret
/// si ni le schéma natif ni le navigateur n'ont pu ouvrir la vidéo (cas
/// extrême) — ne plante jamais l'écran appelant.
///
/// Utilisé par `HomeScreen` (qui affiche des `BookmarkCard` tapables) pour
/// ne jamais dupliquer cette logique d'ouverture (voir CONVENTIONS.md, éviter
/// la duplication entre écrans).
Future<void> openBookmark(
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
