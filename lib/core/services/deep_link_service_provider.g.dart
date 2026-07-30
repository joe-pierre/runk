// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deep_link_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Instance unique de [DeepLinkService] pour toute l'application.
///
/// `keepAlive: true` : le service n'a aucun état par requête, pas de raison
/// de le recréer entre deux taps sur `BookmarkCard`.

@ProviderFor(deepLinkService)
final deepLinkServiceProvider = DeepLinkServiceProvider._();

/// Instance unique de [DeepLinkService] pour toute l'application.
///
/// `keepAlive: true` : le service n'a aucun état par requête, pas de raison
/// de le recréer entre deux taps sur `BookmarkCard`.

final class DeepLinkServiceProvider
    extends
        $FunctionalProvider<DeepLinkService, DeepLinkService, DeepLinkService>
    with $Provider<DeepLinkService> {
  /// Instance unique de [DeepLinkService] pour toute l'application.
  ///
  /// `keepAlive: true` : le service n'a aucun état par requête, pas de raison
  /// de le recréer entre deux taps sur `BookmarkCard`.
  DeepLinkServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deepLinkServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deepLinkServiceHash();

  @$internal
  @override
  $ProviderElement<DeepLinkService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeepLinkService create(Ref ref) {
    return deepLinkService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeepLinkService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeepLinkService>(value),
    );
  }
}

String _$deepLinkServiceHash() => r'db039b94a7219db479072c14ed9ffbf7a0f932dc';
