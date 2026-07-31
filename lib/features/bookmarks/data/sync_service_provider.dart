import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_service.dart';
import 'bookmark_repository_provider.dart';
import 'sync_service.dart';

part 'sync_service_provider.g.dart';

/// Instance unique de [SyncService], construite à partir du
/// [bookmarkRepositoryProvider] déjà exposé à la couche présentation et de
/// l'état de session Supabase courant (`SupabaseService.client.auth`).
///
/// `keepAlive: true` : le service doit rester actif (abonnements réseau,
/// minuteur périodique) pendant toute la durée de vie de l'app, démarré une
/// seule fois par `SyncServiceGate`.
@Riverpod(keepAlive: true)
Future<SyncService> syncService(Ref ref) async {
  final repository = await ref.watch(bookmarkRepositoryProvider.future);
  final service = SyncService(
    repository: repository,
    hasActiveSession: () =>
        SupabaseService.client.auth.currentSession != null,
  );
  ref.onDispose(service.dispose);
  return service;
}
