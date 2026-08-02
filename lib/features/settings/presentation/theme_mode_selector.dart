import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/theme_mode_provider.dart';

/// Sélecteur de thème (clair / sombre / système), affiché dans `AppDrawer`
/// (Tâche 29, voir DECISIONS.md) — point d'entrée unique pour changer le
/// thème actif à la volée, sans redémarrage de l'app.
///
/// Affiché que l'utilisateur soit connecté ou non : le choix de thème n'a
/// aucun lien avec l'authentification (voir `AppDrawer`).
class ThemeModeSelector extends ConsumerWidget {
  /// Crée le sélecteur.
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMode = ref.watch(themeModeControllerProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thème', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Clair'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Sombre'),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.settings_suggest_outlined),
                label: Text('Système'),
              ),
            ],
            selected: {activeMode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => ref
                .read(themeModeControllerProvider.notifier)
                .setThemeMode(selection.first),
          ),
        ],
      ),
    );
  }
}
