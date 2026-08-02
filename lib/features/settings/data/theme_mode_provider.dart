import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_mode_provider.g.dart';

const _themeModePreferenceKey = 'theme_mode';

/// [ThemeMode] actif de Runk, persisté via `SharedPreferences` (Tâche 29,
/// voir DECISIONS.md).
///
/// Vaut [ThemeMode.system] tant qu'aucun choix n'a été enregistré — l'app
/// suit alors le thème du système d'exploitation, conformément à la
/// contrainte de la tâche ("le mode système doit suivre le thème OS si
/// l'utilisateur ne l'a jamais changé manuellement"). La valeur persistée
/// est chargée de façon asynchrone après la valeur initiale synchrone (état
/// exposé directement en `ThemeMode`, pas en `AsyncValue`, pour que
/// `main.dart` puisse l'utiliser tel quel via `MaterialApp.themeMode`) —
/// écart bref et sans conséquence pratique entre le premier frame et la
/// restauration de la préférence enregistrée.
@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  @override
  ThemeMode build() {
    _loadPersistedThemeMode();
    return ThemeMode.system;
  }

  Future<void> _loadPersistedThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final storedName = preferences.getString(_themeModePreferenceKey);
    for (final mode in ThemeMode.values) {
      if (mode.name == storedName) {
        state = mode;
        return;
      }
    }
  }

  /// Change le thème actif immédiatement (sans redémarrage) et persiste ce
  /// choix pour les prochains lancements de l'app.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModePreferenceKey, mode.name);
  }
}
