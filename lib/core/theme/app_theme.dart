import 'package:flutter/material.dart';

import 'app_color_tokens.dart';
import 'app_palette.dart';

/// Thèmes clair et sombre de Runk (Tâche 29, voir DECISIONS.md et SPEC.md
/// section 10 pour la palette validée).
///
/// [ColorScheme] construit explicitement à partir de [ColorScheme.dark]/
/// [ColorScheme.light] — jamais `ColorScheme.fromSeed`, qui dériverait
/// algorithmiquement des teintes que la palette pilote précisément. Les
/// rôles sans équivalent Material standard (bordure de carte, tags, badge
/// de plateforme, palette de miniatures) vivent dans [AppColorTokens],
/// enregistrés via `ThemeData.extensions`.
abstract final class AppTheme {
  /// Thème sombre — thème par défaut de l'app (voir SPEC.md section 10).
  static final ThemeData dark = _build(
    brightness: Brightness.dark,
    background: AppPalette.espresso,
    surface: AppPalette.umber,
    onSurface: AppPalette.ivory,
    onSurfaceVariant: AppPalette.sand,
    outline: AppPalette.taupe,
    tokens: AppColorTokens.dark,
  );

  /// Thème clair.
  static final ThemeData light = _build(
    brightness: Brightness.light,
    background: AppPalette.cream,
    surface: AppPalette.white,
    onSurface: AppPalette.charcoal,
    onSurfaceVariant: AppPalette.clay,
    outline: AppPalette.fawn,
    tokens: AppColorTokens.light,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color outline,
    required AppColorTokens tokens,
  }) {
    final baseScheme = brightness == Brightness.dark
        ? ColorScheme.dark(
            primary: AppPalette.terracotta,
            onPrimary: AppPalette.blush,
            secondary: AppPalette.terracotta,
            onSecondary: AppPalette.blush,
            surface: surface,
            onSurface: onSurface,
            onSurfaceVariant: onSurfaceVariant,
            outline: outline,
          )
        : ColorScheme.light(
            primary: AppPalette.terracotta,
            onPrimary: AppPalette.blush,
            secondary: AppPalette.terracotta,
            onSecondary: AppPalette.blush,
            surface: surface,
            onSurface: onSurface,
            onSurfaceVariant: onSurfaceVariant,
            outline: outline,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: baseScheme,
      // Rôle "background" (fond d'écran) distinct du rôle "surface" (fond de
      // carte) porté par le ColorScheme — voir la palette, SPEC.md section
      // 10 : les deux ne partagent pas la même valeur, contrairement au
      // comportement par défaut de Material 3.
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        color: surface,
        // Désactive la superposition de teinte (`surfaceTint`) que Material
        // 3 applique par défaut aux surfaces élevées : sans ça, `Card`
        // teinterait la couleur exacte de la palette avec `colorScheme
        // .primary`, ce qui contredit "piloter précisément" les couleurs
        // (même raisonnement que le rejet de `ColorScheme.fromSeed`).
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: tokens.cardBorder),
        ),
      ),
      // Checkboxes rondes plutôt que carrées (Tâche 35, voir DECISIONS.md),
      // pour toute l'app (carte de bookmark, case "Tout sélectionner",
      // sélection de `AddToMyEyesOnlyScreen`) — réglé ici plutôt qu'en
      // override local sur chaque `Checkbox`, pour un rendu uniforme garanti.
      checkboxTheme: const CheckboxThemeData(shape: CircleBorder()),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        // Pastille d'indicateur teintée accent derrière l'icône active (voir
        // TASK_PROMPTS.md, Tâche 29 : "icône active teintée accent") ;
        // l'icône elle-même passe en `onPrimary` (blanc chaud) pour rester
        // lisible sur ce fond coloré plutôt que de dupliquer la même teinte
        // accent pour le fond et l'icône (DECISIONS.md, Tâche 29).
        indicatorColor: baseScheme.primary,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? baseScheme.onPrimary
                : outline,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? baseScheme.primary
                : outline,
          ),
        ),
      ),
      extensions: [tokens],
    );
  }
}
