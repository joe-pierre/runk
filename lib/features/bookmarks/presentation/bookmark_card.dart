import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/models/video_source.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../domain/video_bookmark.dart';

/// Tokens de couleur actifs, ou [AppColorTokens.dark] si aucun thème Runk
/// (`AppTheme.light`/`AppTheme.dark`, voir `core/theme/`) n'est enregistré —
/// cas des tests de widget qui montent un `MaterialApp` minimal sans thème
/// applicatif ; en usage réel, `main.dart` enregistre toujours l'extension.
AppColorTokens _colorTokens(BuildContext context) =>
    Theme.of(context).extension<AppColorTokens>() ?? AppColorTokens.dark;

/// Carte d'affichage d'un [VideoBookmark] : miniature (ou placeholder si
/// [VideoBookmark.isPartial]), titre, tags et icône de plateforme.
///
/// Composant réutilisable et purement présentationnel : reçoit un
/// [VideoBookmark] déjà résolu et ne décide jamais lui-même comment
/// récupérer une métadonnée (voir CONVENTIONS.md section Partials /
/// Frontend). [onTap] est branché par `HomeScreen` sur
/// `DeepLinkService.openInSource` (Tâche 8) — laissé optionnel ici, ce
/// widget ne connaît lui-même aucune logique de réouverture. [onLongPress]
/// suit le même principe (Tâche 21) : branché par `HomeScreen` sur
/// `showBookmarkContextMenu`, jamais d'appel direct à `BookmarkRepository`
/// depuis ce fichier.
///
/// **Mode sélection multiple (Tâche 26, voir DECISIONS.md) :** quand
/// [selectionMode] est vrai, une case à cocher apparaît en superposition
/// (état porté par [isSelected]), le tap sur la carte appelle
/// [onToggleSelection] au lieu de [onTap], et [onLongPress] est ignoré — pas
/// de menu contextuel individuel pendant une sélection multiple, pour éviter
/// toute ambiguïté. Un seul widget, jamais de duplication : ce mode n'est
/// qu'un affichage différent du même `BookmarkCard`.
class BookmarkCard extends StatelessWidget {
  /// Crée la carte pour [bookmark]. [onTap] est appelé au tap sur la carte,
  /// [onLongPress] à l'appui long (tous deux ignorés si [selectionMode] est
  /// vrai, voir doc de classe).
  const BookmarkCard({
    super.key,
    required this.bookmark,
    this.onTap,
    this.onLongPress,
    this.selectionMode = false,
    this.isSelected = false,
    this.onToggleSelection,
  });

  /// Bookmark à afficher.
  final VideoBookmark bookmark;

  /// Appelé au tap sur la carte, ou `null` si aucune action n'est branchée.
  /// Ignoré si [selectionMode] est vrai (voir [onToggleSelection]).
  final VoidCallback? onTap;

  /// Appelé à l'appui long sur la carte, ou `null` si aucune action n'est
  /// branchée. Geste distinct du tap simple (`onTap`) — `InkWell` gère
  /// nativement la désambiguïsation entre les deux, aucune interférence.
  /// Ignoré si [selectionMode] est vrai (voir doc de classe).
  final VoidCallback? onLongPress;

  /// Vrai si la carte doit s'afficher en mode sélection multiple (Tâche 26).
  final bool selectionMode;

  /// Vrai si ce bookmark est actuellement coché — sans effet si
  /// [selectionMode] est faux.
  final bool isSelected;

  /// Appelé quand [selectionMode] est actif et que l'utilisateur tape la
  /// carte ou la case à cocher, avec le nouvel état de sélection souhaité
  /// (inverse de [isSelected]).
  final ValueChanged<bool>? onToggleSelection;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = _colorTokens(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens.cardBorder),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: selectionMode
                ? () => onToggleSelection?.call(!isSelected)
                : onTap,
            onLongPress: selectionMode ? null : onLongPress,
            child: Padding(
              padding: EdgeInsets.fromLTRB(selectionMode ? 40 : 8, 8, 8, 8),
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
                            _PlatformIcon(
                              source: bookmark.source,
                              color: colorScheme.onSurfaceVariant,
                            ),
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
                                  label: Text(
                                    tag,
                                    style: TextStyle(color: tokens.tagText),
                                  ),
                                  backgroundColor: tokens.tagBackground,
                                  side: BorderSide.none,
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
          if (selectionMode)
            Positioned(
              top: 4,
              left: 4,
              child: Checkbox(
                value: isSelected,
                onChanged: (checked) =>
                    onToggleSelection?.call(checked ?? false),
              ),
            ),
        ],
      ),
    );
  }
}

/// Miniature du bookmark, ou placeholder si absente / [VideoBookmark.isPartial]
/// (voir SPEC.md section 4 règle 3 — dégradation propre des métadonnées).
///
/// Le chargement passe par [CachedNetworkImage] (cache disque local à
/// l'appareil, voir DECISIONS.md « Tâche 12 »), pour rester affichée même
/// après un redémarrage de l'app si l'URL distante d'origine a expiré
/// entre-temps (cas fréquent des CDN signés Instagram/Facebook).
class _BookmarkThumbnail extends StatelessWidget {
  const _BookmarkThumbnail({required this.bookmark});

  final VideoBookmark bookmark;

  static const _size = 72.0;

  @override
  Widget build(BuildContext context) {
    if (bookmark.source == VideoSource.maps) {
      return _mapsIcon(context);
    }
    final thumbnailUrl = bookmark.thumbnailUrl;
    if (bookmark.isPartial || thumbnailUrl == null) {
      return _placeholder(context, icon: Icons.videocam_off_outlined);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: thumbnailUrl,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) =>
            _placeholder(context, icon: Icons.broken_image_outlined),
      ),
    );
  }

  /// Icône fixe affichée pour un bookmark [VideoSource.maps] (Tâche 39), à
  /// la place de toute tentative de miniature réseau.
  ///
  /// Visuellement distincte du [_placeholder] générique utilisé pour un
  /// [VideoBookmark.isPartial] classique (`Icons.videocam_off_outlined`/
  /// `Icons.broken_image_outlined` sur fond `thumbnailPalette` cyclique) :
  /// fond `colorScheme.primary` fixe (jamais cyclique) et icône
  /// `Icons.location_on`, pour signaler sans ambiguïté un choix délibéré —
  /// jamais un échec de récupération de miniature (voir DECISIONS.md,
  /// entrée "Tâche 39").
  Widget _mapsIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.location_on, color: colorScheme.onPrimary),
    );
  }

  /// Placeholder affiché si la miniature réseau est absente, non encore
  /// chargée avec succès, ou si [VideoBookmark.isPartial] est vrai — fond
  /// coloré assigné de façon déterministe (voir DECISIONS.md, Tâche 29) via
  /// `AppColorTokens.thumbnailPalette`, jamais aléatoire à chaque rebuild ni
  /// lié à [VideoSource]. Ne concerne jamais une vraie miniature réseau,
  /// affichée par [CachedNetworkImage] ci-dessus, ni un bookmark
  /// [VideoSource.maps] (voir [_mapsIcon]).
  Widget _placeholder(BuildContext context, {required IconData icon}) {
    final tokens = _colorTokens(context);
    final palette = tokens.thumbnailPalette;
    final color = palette[bookmark.id.hashCode.abs() % palette.length];
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: tokens.badgeText),
    );
  }
}

/// Icône représentative de [source], teintée par [color].
///
/// Instagram/Facebook/X/Threads utilisent les icônes SVG dédiées
/// d'`assets/icons/` (voir SPEC.md section 8), câblées en Tâche 29 — ce qui
/// clôt la dette documentée dans `BUGS_AND_ROADMAP.md` (entrée Tâche 7).
/// YouTube et TikTok n'ont pas d'icône SVG dédiée : icône Material générique
/// conservée, teintée avec le même [color] pour rester visuellement
/// cohérente avec les icônes SVG (voir DECISIONS.md, Tâche 29).
class _PlatformIcon extends StatelessWidget {
  const _PlatformIcon({required this.source, required this.color});

  /// Plateforme dont l'icône doit être affichée.
  final VideoSource source;

  /// Teinte appliquée à l'icône (SVG ou Material).
  final Color color;

  static const _size = 16.0;

  @override
  Widget build(BuildContext context) {
    final svgAsset = _svgAssetFor(source);
    if (svgAsset != null) {
      return SvgPicture.asset(
        svgAsset,
        width: _size,
        height: _size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Icon(_materialIconFor(source), size: _size, color: color);
  }

  static String? _svgAssetFor(VideoSource source) {
    switch (source) {
      case VideoSource.instagram:
        return 'assets/icons/instagram.svg';
      case VideoSource.facebook:
        return 'assets/icons/facebook.svg';
      case VideoSource.twitter:
        return 'assets/icons/x.svg';
      case VideoSource.threads:
        return 'assets/icons/threads.svg';
      case VideoSource.youtube:
      case VideoSource.tiktok:
      case VideoSource.website:
      case VideoSource.maps:
      case VideoSource.unknown:
        return null;
    }
  }

  static IconData _materialIconFor(VideoSource source) {
    switch (source) {
      case VideoSource.youtube:
        return Icons.smart_display_outlined;
      case VideoSource.tiktok:
        return Icons.music_note;
      case VideoSource.website:
        return Icons.public;
      case VideoSource.maps:
        return Icons.location_on;
      case VideoSource.unknown:
        return Icons.link;
      case VideoSource.instagram:
      case VideoSource.facebook:
      case VideoSource.twitter:
      case VideoSource.threads:
        // Non atteint : ces 4 plateformes ont un SVG dédié, retourné plus
        // haut par `_svgAssetFor`. Conservé uniquement pour l'exhaustivité
        // du switch (voir `VideoSource`).
        return Icons.link;
    }
  }
}
