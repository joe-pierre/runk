import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  runApp(const ProviderScope(child: RunkApp()));
}

/// Widget racine de Runk.
///
/// Configure le thème (sombre par défaut, voir SPEC.md section 10) et
/// délègue toute la navigation à [appRouter] (voir `app/router.dart`) —
/// bottom navigation à 3 onglets Home/Tags/Recherche (SPEC.md section 11).
/// `ShareIntentGate` et `SyncServiceGate` sont câblés au niveau du shell de
/// navigation, pas ici (voir `app/router.dart`).
class RunkApp extends StatelessWidget {
  const RunkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Runk',
      theme: ThemeData.dark(useMaterial3: true),
      routerConfig: appRouter,
    );
  }
}
