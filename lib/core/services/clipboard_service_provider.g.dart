// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clipboard_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Instance unique de [ClipboardHistoryStore], appuyée sur l'instance
/// partagée de `SharedPreferences` de l'appareil.
///
/// `keepAlive: true` : l'historique des liens vus doit rester cohérent
/// pendant toute la durée de vie de l'app.

@ProviderFor(clipboardHistoryStore)
final clipboardHistoryStoreProvider = ClipboardHistoryStoreProvider._();

/// Instance unique de [ClipboardHistoryStore], appuyée sur l'instance
/// partagée de `SharedPreferences` de l'appareil.
///
/// `keepAlive: true` : l'historique des liens vus doit rester cohérent
/// pendant toute la durée de vie de l'app.

final class ClipboardHistoryStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClipboardHistoryStore>,
          ClipboardHistoryStore,
          FutureOr<ClipboardHistoryStore>
        >
    with
        $FutureModifier<ClipboardHistoryStore>,
        $FutureProvider<ClipboardHistoryStore> {
  /// Instance unique de [ClipboardHistoryStore], appuyée sur l'instance
  /// partagée de `SharedPreferences` de l'appareil.
  ///
  /// `keepAlive: true` : l'historique des liens vus doit rester cohérent
  /// pendant toute la durée de vie de l'app.
  ClipboardHistoryStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipboardHistoryStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipboardHistoryStoreHash();

  @$internal
  @override
  $FutureProviderElement<ClipboardHistoryStore> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ClipboardHistoryStore> create(Ref ref) {
    return clipboardHistoryStore(ref);
  }
}

String _$clipboardHistoryStoreHash() =>
    r'f224e061c99865ad0fdc96a029f8ba1349535a7c';

/// Instance unique de [ClipboardService] pour toute l'application.
///
/// `keepAlive: true` : comme `shareIntentServiceProvider`, l'observation du
/// cycle de vie doit rester active pendant toute la durée de vie de l'app,
/// jamais recréée entre deux écrans. Libérée via [ClipboardService.dispose]
/// si le provider est un jour invalidé (ne devrait pas arriver en usage
/// normal).

@ProviderFor(clipboardService)
final clipboardServiceProvider = ClipboardServiceProvider._();

/// Instance unique de [ClipboardService] pour toute l'application.
///
/// `keepAlive: true` : comme `shareIntentServiceProvider`, l'observation du
/// cycle de vie doit rester active pendant toute la durée de vie de l'app,
/// jamais recréée entre deux écrans. Libérée via [ClipboardService.dispose]
/// si le provider est un jour invalidé (ne devrait pas arriver en usage
/// normal).

final class ClipboardServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClipboardService>,
          ClipboardService,
          FutureOr<ClipboardService>
        >
    with $FutureModifier<ClipboardService>, $FutureProvider<ClipboardService> {
  /// Instance unique de [ClipboardService] pour toute l'application.
  ///
  /// `keepAlive: true` : comme `shareIntentServiceProvider`, l'observation du
  /// cycle de vie doit rester active pendant toute la durée de vie de l'app,
  /// jamais recréée entre deux écrans. Libérée via [ClipboardService.dispose]
  /// si le provider est un jour invalidé (ne devrait pas arriver en usage
  /// normal).
  ClipboardServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipboardServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipboardServiceHash();

  @$internal
  @override
  $FutureProviderElement<ClipboardService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ClipboardService> create(Ref ref) {
    return clipboardService(ref);
  }
}

String _$clipboardServiceHash() => r'bb49b40090da5ea149089366832e2c6a8311088d';
