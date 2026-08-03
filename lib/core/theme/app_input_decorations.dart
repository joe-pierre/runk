import 'package:flutter/material.dart';

/// Style de référence pour tout champ de recherche/filtre de l'app (bordure
/// arrondie, dense, icône de recherche) — évite la duplication constatée
/// entre `home_screen.dart` (barre de recherche) et `tags_screen.dart` (champ
/// de filtre local), voir `DECISIONS.md`, entrée « Tâche 37 ». Pure fonction
/// de style, sans logique métier ni dépendance à un provider.
InputDecoration searchFieldDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: const Icon(Icons.search),
    isDense: true,
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    ),
  );
}
