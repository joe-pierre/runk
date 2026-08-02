// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(ThemeModeController)
final themeModeControllerProvider = ThemeModeControllerProvider._();

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
final class ThemeModeControllerProvider
    extends $NotifierProvider<ThemeModeController, ThemeMode> {
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
  ThemeModeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeControllerHash();

  @$internal
  @override
  ThemeModeController create() => ThemeModeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeControllerHash() =>
    r'7fe39c49930a8ea115ea6fb77e2c1a7a294c7ebd';

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

abstract class _$ThemeModeController extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
