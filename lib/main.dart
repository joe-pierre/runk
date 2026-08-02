import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/data/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  runApp(const ProviderScope(child: RunkApp()));
}

/// Widget racine de Runk.
///
/// Thèmes clair/sombre définis dans `core/theme/app_theme.dart` (palette
/// figée, Tâche 29, voir DECISIONS.md et SPEC.md section 10) ; l'app suit le
/// thème du système tant qu'aucune préférence n'a été enregistrée
/// explicitement (`themeModeControllerProvider` vaut `ThemeMode.system` par
/// défaut, voir sa doc — écart assumé par rapport à l'ancien "sombre par
/// défaut" de SPEC.md section 10, révisé en Tâche 29, voir DECISIONS.md).
/// Bascule à la volée depuis la sidebar (`ThemeModeSelector`), sans
/// redémarrage. Délègue toute la
/// navigation à [appRouter] (voir `app/router.dart`) — bottom navigation à 3
/// onglets Home/Tags/Recherche (SPEC.md section 11). `ShareIntentGate` et
/// `SyncServiceGate` sont câblés au niveau du shell de navigation, pas ici
/// (voir `app/router.dart`).
class RunkApp extends ConsumerWidget {
  const RunkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Runk',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeControllerProvider),
      routerConfig: appRouter,
    );
  }
}
