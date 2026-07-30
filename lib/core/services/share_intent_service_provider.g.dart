// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_intent_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Instance unique de [ShareIntentService] pour toute l'application.
///
/// `keepAlive: true` : le service doit rester actif (et son flux écouté)
/// pendant toute la durée de vie de l'app, jamais recréé entre deux écrans.
/// Libéré via [ShareIntentService.dispose] si le provider est un jour
/// invalidé (ne devrait pas arriver en usage normal).

@ProviderFor(shareIntentService)
final shareIntentServiceProvider = ShareIntentServiceProvider._();

/// Instance unique de [ShareIntentService] pour toute l'application.
///
/// `keepAlive: true` : le service doit rester actif (et son flux écouté)
/// pendant toute la durée de vie de l'app, jamais recréé entre deux écrans.
/// Libéré via [ShareIntentService.dispose] si le provider est un jour
/// invalidé (ne devrait pas arriver en usage normal).

final class ShareIntentServiceProvider
    extends
        $FunctionalProvider<
          ShareIntentService,
          ShareIntentService,
          ShareIntentService
        >
    with $Provider<ShareIntentService> {
  /// Instance unique de [ShareIntentService] pour toute l'application.
  ///
  /// `keepAlive: true` : le service doit rester actif (et son flux écouté)
  /// pendant toute la durée de vie de l'app, jamais recréé entre deux écrans.
  /// Libéré via [ShareIntentService.dispose] si le provider est un jour
  /// invalidé (ne devrait pas arriver en usage normal).
  ShareIntentServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareIntentServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareIntentServiceHash();

  @$internal
  @override
  $ProviderElement<ShareIntentService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShareIntentService create(Ref ref) {
    return shareIntentService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareIntentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareIntentService>(value),
    );
  }
}

String _$shareIntentServiceHash() =>
    r'635a88e8f57e49e170193c0f84c9b16d27c9cd3e';
