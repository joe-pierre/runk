import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/supabase_service.dart';
import 'features/bookmarks/presentation/home_screen.dart';
import 'features/bookmarks/presentation/share_intent_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  runApp(const ProviderScope(child: RunkApp()));
}

/// Widget racine de Runk.
///
/// Configure le thème (sombre par défaut, voir SPEC.md section 10) et place
/// `ShareIntentGate` comme contenu de la route initiale : son `context` est
/// ainsi déjà un descendant du `Navigator` créé par `MaterialApp`, ce qui lui
/// permet d'ouvrir `AddBookmarkSheet` dès qu'un partage est reçu (voir
/// SPEC.md section 13).
class RunkApp extends StatelessWidget {
  const RunkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runk',
      theme: ThemeData.dark(useMaterial3: true),
      home: const ShareIntentGate(child: HomeScreen()),
    );
  }
}
