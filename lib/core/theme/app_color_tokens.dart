import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Rôles de couleur propres à Runk sans équivalent direct dans le
/// [ColorScheme] Material standard (voir DECISIONS.md, Tâche 29) : bordure
/// de carte/sidebar, fond et texte des pastilles de tag, superposition et
/// texte du badge de plateforme sur une miniature, et la palette cyclique
/// des placeholders de miniature.
///
/// Construit exclusivement à partir de [AppPalette] — jamais de valeur
/// hexadécimale en dur ici. Enregistré via `ThemeData.extensions` dans
/// `app_theme.dart`, consommé via
/// `Theme.of(context).extension<AppColorTokens>()`.
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  /// Crée un jeu de tokens. Voir [dark]/[light] pour les instances figées de
  /// la palette validée.
  const AppColorTokens({
    required this.cardBorder,
    required this.tagBackground,
    required this.tagText,
    required this.badgeOverlay,
    required this.badgeText,
    required this.thumbnailPalette,
  });

  /// Bordure des cartes (`BookmarkCard`) et de la sidebar (`AppDrawer`).
  final Color cardBorder;

  /// Fond des pastilles de tag.
  final Color tagBackground;

  /// Texte des pastilles de tag.
  final Color tagText;

  /// Superposition semi-transparente du badge de plateforme affiché sur une
  /// miniature.
  final Color badgeOverlay;

  /// Texte/icône du badge de plateforme sur une miniature.
  final Color badgeText;

  /// Couleurs cycliques assignées de façon déterministe aux placeholders de
  /// miniature (`BookmarkCard._BookmarkThumbnail`, jamais à une vraie
  /// miniature réseau) — voir DECISIONS.md, Tâche 29, pour la règle
  /// d'assignation (`thumbnailPalette[bookmark.id.hashCode.abs() %
  /// thumbnailPalette.length]`).
  final List<Color> thumbnailPalette;

  /// Tokens du mode sombre.
  static const dark = AppColorTokens(
    cardBorder: AppPalette.bark,
    tagBackground: AppPalette.amber,
    tagText: AppPalette.gold,
    badgeOverlay: AppPalette.inkOverlay,
    badgeText: AppPalette.blush,
    thumbnailPalette: [
      AppPalette.terracotta,
      AppPalette.magenta,
      AppPalette.forest,
    ],
  );

  /// Tokens du mode clair.
  static const light = AppColorTokens(
    cardBorder: AppPalette.linen,
    tagBackground: AppPalette.wheat,
    tagText: AppPalette.bronze,
    badgeOverlay: AppPalette.inkOverlay,
    badgeText: AppPalette.blush,
    thumbnailPalette: [
      AppPalette.terracotta,
      AppPalette.magenta,
      AppPalette.forest,
    ],
  );

  @override
  AppColorTokens copyWith({
    Color? cardBorder,
    Color? tagBackground,
    Color? tagText,
    Color? badgeOverlay,
    Color? badgeText,
    List<Color>? thumbnailPalette,
  }) {
    return AppColorTokens(
      cardBorder: cardBorder ?? this.cardBorder,
      tagBackground: tagBackground ?? this.tagBackground,
      tagText: tagText ?? this.tagText,
      badgeOverlay: badgeOverlay ?? this.badgeOverlay,
      badgeText: badgeText ?? this.badgeText,
      thumbnailPalette: thumbnailPalette ?? this.thumbnailPalette,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) {
      return this;
    }
    return AppColorTokens(
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      tagBackground: Color.lerp(tagBackground, other.tagBackground, t)!,
      tagText: Color.lerp(tagText, other.tagText, t)!,
      badgeOverlay: Color.lerp(badgeOverlay, other.badgeOverlay, t)!,
      badgeText: Color.lerp(badgeText, other.badgeText, t)!,
      // Liste discrète, jamais interpolée composante par composante : on
      // bascule d'un jeu à l'autre à mi-transition plutôt que de mélanger
      // des couleurs qui n'ont pas de correspondance terme à terme garantie.
      thumbnailPalette: t < 0.5 ? thumbnailPalette : other.thumbnailPalette,
    );
  }
}
