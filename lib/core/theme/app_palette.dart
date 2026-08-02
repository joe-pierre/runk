import 'package:flutter/material.dart';

/// Constantes de couleur brutes de la charte graphique de Runk, nommées par
/// teinte plutôt que par rôle (voir `app_color_tokens.dart`/`app_theme.dart`
/// pour l'attribution des rôles) — palette figée avec l'utilisateur, Tâche
/// 29, voir DECISIONS.md et SPEC.md section 10.
///
/// Zéro logique ici : uniquement des valeurs. Aucun fichier en dehors de
/// `core/theme/` ne doit référencer un `Color(0xFF...)` directement — tout
/// passe par [AppColorTokens]/[ColorScheme].
abstract final class AppPalette {
  // --- Mode sombre ---

  /// Fond d'écran en mode sombre.
  static const espresso = Color(0xFF1B1512);

  /// Fond de carte en mode sombre.
  static const umber = Color(0xFF241C17);

  /// Bordure de carte/sidebar en mode sombre.
  static const bark = Color(0xFF362A20);

  /// Texte principal en mode sombre.
  static const ivory = Color(0xFFFBF3E7);

  /// Icônes secondaires (ex : recherche) en mode sombre.
  static const sand = Color(0xFFA08D74);

  /// Icônes de navigation inactives en mode sombre.
  static const taupe = Color(0xFF6B5D4D);

  /// Fond des pastilles de tag en mode sombre.
  static const amber = Color(0xFF3D2A18);

  /// Texte des pastilles de tag en mode sombre.
  static const gold = Color(0xFFFAC775);

  // --- Mode clair ---

  /// Fond d'écran en mode clair.
  static const cream = Color(0xFFFAF2E4);

  /// Fond de carte en mode clair.
  static const white = Color(0xFFFFFFFF);

  /// Bordure de carte/sidebar en mode clair.
  static const linen = Color(0xFFE7D9C2);

  /// Texte principal en mode clair.
  static const charcoal = Color(0xFF2B2015);

  /// Icônes secondaires en mode clair.
  static const clay = Color(0xFF9C8B72);

  /// Icônes de navigation inactives en mode clair.
  static const fawn = Color(0xFFB3A488);

  /// Fond des pastilles de tag en mode clair.
  static const wheat = Color(0xFFF1E1C4);

  /// Texte des pastilles de tag en mode clair.
  static const bronze = Color(0xFF7A5518);

  // --- Communes aux deux modes ---

  /// Accent de marque — identique en clair et en sombre.
  static const terracotta = Color(0xFFD85A30);

  /// Deuxième couleur cyclique de la palette de miniatures placeholder.
  static const magenta = Color(0xFFB84C6F);

  /// Troisième couleur cyclique de la palette de miniatures placeholder.
  static const forest = Color(0xFF3C7A63);

  /// Texte/icône du badge de plateforme sur une miniature — identique en
  /// clair et en sombre (se pose sur une image colorée, pas sur le fond).
  static const blush = Color(0xFFFDEEE7);

  /// Superposition semi-transparente du badge de plateforme
  /// (`rgba(20,12,8,0.5)`) — identique en clair et en sombre.
  static const inkOverlay = Color(0x80140C08);
}
