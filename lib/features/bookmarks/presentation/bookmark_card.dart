import 'package:flutter/material.dart';

import '../../../core/models/video_source.dart';
import '../domain/video_bookmark.dart';

/// Carte d'affichage d'un [VideoBookmark] : miniature (ou placeholder si
/// [VideoBookmark.isPartial]), titre, tags et icône de plateforme.
///
/// Composant réutilisable et purement présentationnel : reçoit un
/// [VideoBookmark] déjà résolu et ne décide jamais lui-même comment
/// récupérer une métadonnée (voir CONVENTIONS.md section Partials /
/// Frontend). [onTap] est branché par `HomeScreen` sur
/// `DeepLinkService.openInSource` (Tâche 8) — laissé optionnel ici, ce
/// widget ne connaît lui-même aucune logique de réouverture.
class BookmarkCard extends StatelessWidget {
  /// Crée la carte pour [bookmark]. [onTap] est appelé au tap sur la carte.
  const BookmarkCard({super.key, required this.bookmark, this.onTap});

  /// Bookmark à afficher.
  final VideoBookmark bookmark;

  /// Appelé au tap sur la carte, ou `null` si aucune action n'est branchée.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BookmarkThumbnail(bookmark: bookmark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_platformIcon(bookmark.source), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            bookmark.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    if (bookmark.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final tag in bookmark.tags)
                            Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Miniature du bookmark, ou placeholder si absente / [VideoBookmark.isPartial]
/// (voir SPEC.md section 4 règle 3 — dégradation propre des métadonnées).
class _BookmarkThumbnail extends StatelessWidget {
  const _BookmarkThumbnail({required this.bookmark});

  final VideoBookmark bookmark;

  static const _size = 72.0;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = bookmark.thumbnailUrl;
    if (bookmark.isPartial || thumbnailUrl == null) {
      return _placeholder(context, icon: Icons.videocam_off_outlined);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        thumbnailUrl,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _placeholder(context, icon: Icons.broken_image_outlined),
      ),
    );
  }

  Widget _placeholder(BuildContext context, {required IconData icon}) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

/// Icône représentative de [source].
///
/// Icônes Material génériques en attendant les icônes de plateforme
/// dédiées prévues en Tâche 7 (voir SPEC.md section 8, `assets/icons/`).
IconData _platformIcon(VideoSource source) {
  switch (source) {
    case VideoSource.youtube:
      return Icons.smart_display_outlined;
    case VideoSource.tiktok:
      return Icons.music_note;
    case VideoSource.instagram:
      return Icons.camera_alt_outlined;
    case VideoSource.facebook:
      return Icons.facebook;
    case VideoSource.twitter:
      return Icons.alternate_email;
    case VideoSource.threads:
      return Icons.forum_outlined;
    case VideoSource.unknown:
      return Icons.link;
  }
}
