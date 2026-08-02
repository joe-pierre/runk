import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/app_scaffold_key_provider.dart';
import 'app_drawer.dart';

/// Coquille de navigation principale de Runk : bottom navigation à 2 onglets
/// (Home / Tags), voir SPEC.md section 11 — réduite de 3 à 2 onglets en
/// Tâche 30 (recherche absorbée par une barre flottante sur `HomeScreen`,
/// suppression de l'onglet Recherche, voir DECISIONS.md).
///
/// Purement présentationnel : reçoit [navigationShell], déjà construit par
/// `StatefulShellRoute.indexedStack` (voir `router.dart`), et se contente
/// d'en refléter/piloter l'onglet actif — chaque branche conserve son propre
/// historique de navigation indépendamment des autres. Utilise le widget
/// Material 3 `NavigationBar` (équivalent moderne de la "Bottom Navigation
/// Bar" décrite dans SPEC.md, cohérent avec `ThemeData.dark(useMaterial3:
/// true)` déjà configuré dans `main.dart`).
///
/// Porte le `Drawer` d'authentification (`AppDrawer`, Tâche 28, voir
/// DECISIONS.md), ouvert depuis les 2 écrans via [appScaffoldKeyProvider]
/// (voir sa doc) plutôt que `Scaffold.of(context)`, chaque écran ayant son
/// propre `Scaffold` imbriqué.
class AppShell extends ConsumerWidget {
  /// Crée la coquille pour [navigationShell].
  const AppShell({super.key, required this.navigationShell});

  /// État de navigation des 2 branches (Home / Tags), fourni par go_router.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: ref.watch(appScaffoldKeyProvider),
      drawer: const AppDrawer(),
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
        ],
      ),
    );
  }
}
