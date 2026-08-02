import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import 'auth_repository.dart';

part 'auth_repository_provider.g.dart';

/// Instance unique d'[AuthRepository], construite à partir du client
/// Supabase déjà initialisé par `SupabaseService` (voir `main.dart`).
///
/// `keepAlive: true` : point d'accès stable pendant toute la durée de vie de
/// l'app, comme `bookmarkRepositoryProvider` (voir DECISIONS.md Tâche 6).
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(SupabaseService.client);

/// État de session Supabase courant, en flux (`GoTrueClient
/// .onAuthStateChange`) — consommé par `AppDrawer` (Tâche 28, voir
/// DECISIONS.md) pour que la sidebar se mette à jour automatiquement à la
/// connexion/déconnexion, sans que l'UI n'ait besoin d'interroger
/// [AuthRepository.currentSession] de façon synchrone à chaque rebuild.
///
/// `keepAlive: true` : la souscription doit rester active pour toute la
/// durée de vie de l'app, pas seulement pendant qu'un widget l'observe (même
/// raisonnement que `syncServiceProvider`, voir DECISIONS.md Tâche 9).
@Riverpod(keepAlive: true)
Stream<AuthState> authStateChanges(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.onAuthStateChange;
}
