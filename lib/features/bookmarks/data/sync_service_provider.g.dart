// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Instance unique de [SyncService], construite à partir du
/// [bookmarkRepositoryProvider] et du [tagRepositoryProvider] déjà exposés à
/// la couche présentation, et de l'état de session Supabase courant
/// (`SupabaseService.client.auth`).
///
/// `keepAlive: true` : le service doit rester actif (abonnements réseau,
/// minuteur périodique) pendant toute la durée de vie de l'app, démarré une
/// seule fois par `SyncServiceGate`.

@ProviderFor(syncService)
final syncServiceProvider = SyncServiceProvider._();

/// Instance unique de [SyncService], construite à partir du
/// [bookmarkRepositoryProvider] et du [tagRepositoryProvider] déjà exposés à
/// la couche présentation, et de l'état de session Supabase courant
/// (`SupabaseService.client.auth`).
///
/// `keepAlive: true` : le service doit rester actif (abonnements réseau,
/// minuteur périodique) pendant toute la durée de vie de l'app, démarré une
/// seule fois par `SyncServiceGate`.

final class SyncServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<SyncService>,
          SyncService,
          FutureOr<SyncService>
        >
    with $FutureModifier<SyncService>, $FutureProvider<SyncService> {
  /// Instance unique de [SyncService], construite à partir du
  /// [bookmarkRepositoryProvider] et du [tagRepositoryProvider] déjà exposés à
  /// la couche présentation, et de l'état de session Supabase courant
  /// (`SupabaseService.client.auth`).
  ///
  /// `keepAlive: true` : le service doit rester actif (abonnements réseau,
  /// minuteur périodique) pendant toute la durée de vie de l'app, démarré une
  /// seule fois par `SyncServiceGate`.
  SyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncServiceHash();

  @$internal
  @override
  $FutureProviderElement<SyncService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SyncService> create(Ref ref) {
    return syncService(ref);
  }
}

String _$syncServiceHash() => r'651806d8243deea8092c4d105b13b0f12ed03d71';
