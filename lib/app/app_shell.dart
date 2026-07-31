import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Coquille de navigation principale de Runk : bottom navigation à 3 onglets
/// (Home / Tags / Recherche), voir SPEC.md section 11.
///
/// Purement présentationnel : reçoit [navigationShell], déjà construit par
/// `StatefulShellRoute.indexedStack` (voir `router.dart`), et se contente
/// d'en refléter/piloter l'onglet actif — chaque branche conserve son propre
/// historique de navigation indépendamment des autres. Utilise le widget
/// Material 3 `NavigationBar` (équivalent moderne de la "Bottom Navigation
/// Bar" décrite dans SPEC.md, cohérent avec `ThemeData.dark(useMaterial3:
/// true)` déjà configuré dans `main.dart`).
class AppShell extends StatelessWidget {
  /// Crée la coquille pour [navigationShell].
  const AppShell({super.key, required this.navigationShell});

  /// État de navigation des 3 branches (Home / Tags / Recherche), fourni par
  /// go_router.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.label_outline),
            selectedIcon: Icon(Icons.label),
            label: 'Tags',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Recherche',
          ),
        ],
      ),
    );
  }
}
