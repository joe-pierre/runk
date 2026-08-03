import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/theme_mode_provider.dart';

/// Sélecteur de thème (clair / sombre / système), affiché dans `AppDrawer`
/// (Tâche 29, voir DECISIONS.md) — point d'entrée unique pour changer le
/// thème actif à la volée, sans redémarrage de l'app.
///
/// Présenté comme un [Switch] Clair/Sombre associé à une case à cocher
/// séparée "Suivre le thème du système" (Tâche 36, voir DECISIONS.md) —
/// remplace le `SegmentedButton` de la Tâche 29 sans changer la logique de
/// [themeModeControllerProvider].
///
/// Affiché que l'utilisateur soit connecté ou non : le choix de thème n'a
/// aucun lien avec l'authentification (voir `AppDrawer`).
class ThemeModeSelector extends ConsumerWidget {
  /// Crée le sélecteur.
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMode = ref.watch(themeModeControllerProvider);
    final isFollowingSystem = activeMode == ThemeMode.system;
    final systemPrefersDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDarkSwitchPosition =
        isFollowingSystem ? systemPrefersDark : activeMode == ThemeMode.dark;

    void setThemeMode(ThemeMode mode) =>
        ref.read(themeModeControllerProvider.notifier).setThemeMode(mode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thème', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.light_mode_outlined),
              Switch(
                value: isDarkSwitchPosition,
                onChanged: isFollowingSystem
                    ? null
                    : (isDark) =>
                        setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light),
              ),
              const Icon(Icons.dark_mode_outlined),
            ],
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Suivre le thème du système'),
            value: isFollowingSystem,
            onChanged: (followSystem) {
              if (followSystem == true) {
                setThemeMode(ThemeMode.system);
              } else {
                setThemeMode(
                  isDarkSwitchPosition ? ThemeMode.dark : ThemeMode.light,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
