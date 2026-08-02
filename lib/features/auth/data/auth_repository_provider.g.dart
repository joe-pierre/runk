// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Instance unique d'[AuthRepository], construite à partir du client
/// Supabase déjà initialisé par `SupabaseService` (voir `main.dart`).
///
/// `keepAlive: true` : point d'accès stable pendant toute la durée de vie de
/// l'app, comme `bookmarkRepositoryProvider` (voir DECISIONS.md Tâche 6).

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

/// Instance unique d'[AuthRepository], construite à partir du client
/// Supabase déjà initialisé par `SupabaseService` (voir `main.dart`).
///
/// `keepAlive: true` : point d'accès stable pendant toute la durée de vie de
/// l'app, comme `bookmarkRepositoryProvider` (voir DECISIONS.md Tâche 6).

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// Instance unique d'[AuthRepository], construite à partir du client
  /// Supabase déjà initialisé par `SupabaseService` (voir `main.dart`).
  ///
  /// `keepAlive: true` : point d'accès stable pendant toute la durée de vie de
  /// l'app, comme `bookmarkRepositoryProvider` (voir DECISIONS.md Tâche 6).
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'de4fd0e2b91e9489ed63fc7a555760eb21d388be';

/// État de session Supabase courant, en flux (`GoTrueClient
/// .onAuthStateChange`) — consommé par `AppDrawer` (Tâche 28, voir
/// DECISIONS.md) pour que la sidebar se mette à jour automatiquement à la
/// connexion/déconnexion, sans que l'UI n'ait besoin d'interroger
/// [AuthRepository.currentSession] de façon synchrone à chaque rebuild.
///
/// `keepAlive: true` : la souscription doit rester active pour toute la
/// durée de vie de l'app, pas seulement pendant qu'un widget l'observe (même
/// raisonnement que `syncServiceProvider`, voir DECISIONS.md Tâche 9).

@ProviderFor(authStateChanges)
final authStateChangesProvider = AuthStateChangesProvider._();

/// État de session Supabase courant, en flux (`GoTrueClient
/// .onAuthStateChange`) — consommé par `AppDrawer` (Tâche 28, voir
/// DECISIONS.md) pour que la sidebar se mette à jour automatiquement à la
/// connexion/déconnexion, sans que l'UI n'ait besoin d'interroger
/// [AuthRepository.currentSession] de façon synchrone à chaque rebuild.
///
/// `keepAlive: true` : la souscription doit rester active pour toute la
/// durée de vie de l'app, pas seulement pendant qu'un widget l'observe (même
/// raisonnement que `syncServiceProvider`, voir DECISIONS.md Tâche 9).

final class AuthStateChangesProvider
    extends
        $FunctionalProvider<AsyncValue<AuthState>, AuthState, Stream<AuthState>>
    with $FutureModifier<AuthState>, $StreamProvider<AuthState> {
  /// État de session Supabase courant, en flux (`GoTrueClient
  /// .onAuthStateChange`) — consommé par `AppDrawer` (Tâche 28, voir
  /// DECISIONS.md) pour que la sidebar se mette à jour automatiquement à la
  /// connexion/déconnexion, sans que l'UI n'ait besoin d'interroger
  /// [AuthRepository.currentSession] de façon synchrone à chaque rebuild.
  ///
  /// `keepAlive: true` : la souscription doit rester active pour toute la
  /// durée de vie de l'app, pas seulement pendant qu'un widget l'observe (même
  /// raisonnement que `syncServiceProvider`, voir DECISIONS.md Tâche 9).
  AuthStateChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateChangesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateChangesHash();

  @$internal
  @override
  $StreamProviderElement<AuthState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthState> create(Ref ref) {
    return authStateChanges(ref);
  }
}

String _$authStateChangesHash() => r'bd8ae3d3636b6ce8ce4fe4de396bc5acac533b44';
