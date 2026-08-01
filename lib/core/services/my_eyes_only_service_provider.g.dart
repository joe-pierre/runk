// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_eyes_only_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Instance unique de [MyEyesOnlyService], appuyée sur l'instance partagée
/// de `SharedPreferences` de l'appareil (même pattern que
/// `clipboardHistoryStoreProvider`).
///
/// `keepAlive: true` : le code doit rester vérifiable de façon cohérente
/// pendant toute la durée de vie de l'app.

@ProviderFor(myEyesOnlyService)
final myEyesOnlyServiceProvider = MyEyesOnlyServiceProvider._();

/// Instance unique de [MyEyesOnlyService], appuyée sur l'instance partagée
/// de `SharedPreferences` de l'appareil (même pattern que
/// `clipboardHistoryStoreProvider`).
///
/// `keepAlive: true` : le code doit rester vérifiable de façon cohérente
/// pendant toute la durée de vie de l'app.

final class MyEyesOnlyServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<MyEyesOnlyService>,
          MyEyesOnlyService,
          FutureOr<MyEyesOnlyService>
        >
    with
        $FutureModifier<MyEyesOnlyService>,
        $FutureProvider<MyEyesOnlyService> {
  /// Instance unique de [MyEyesOnlyService], appuyée sur l'instance partagée
  /// de `SharedPreferences` de l'appareil (même pattern que
  /// `clipboardHistoryStoreProvider`).
  ///
  /// `keepAlive: true` : le code doit rester vérifiable de façon cohérente
  /// pendant toute la durée de vie de l'app.
  MyEyesOnlyServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myEyesOnlyServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myEyesOnlyServiceHash();

  @$internal
  @override
  $FutureProviderElement<MyEyesOnlyService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MyEyesOnlyService> create(Ref ref) {
    return myEyesOnlyService(ref);
  }
}

String _$myEyesOnlyServiceHash() => r'3023d8654f853de9d7a166ad525f6d5bf6248728';
