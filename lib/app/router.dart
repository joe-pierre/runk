import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/bookmarks/presentation/home_screen.dart';
import '../features/bookmarks/presentation/share_intent_gate.dart';
import '../features/bookmarks/presentation/sync_service_gate.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/tags/presentation/tags_screen.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Configuration de navigation de Runk (voir SPEC.md section 11) : une
/// unique route "shell" à 3 branches (Home / Tags / Recherche), chacune
/// affichée dans son propre `IndexedStack` via [AppShell].
///
/// `ShareIntentGate` et `SyncServiceGate` enveloppent la coquille entière,
/// jamais un onglet en particulier : leur `context` reste ainsi un
/// descendant valide du `Navigator` quel que soit l'onglet actif au moment
/// d'un partage entrant (`showModalBottomSheet`) ou d'une synchronisation
/// (voir DECISIONS.md, entrée "ShareIntentGate placé comme MaterialApp.home"
/// — même raisonnement, appliqué ici au niveau du shell plutôt que d'un
/// écran unique, maintenant que la navigation à onglets existe).
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => ShareIntentGate(
        child: SyncServiceGate(
          child: AppShell(navigationShell: navigationShell),
        ),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tags',
              builder: (context, state) => const TagsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
