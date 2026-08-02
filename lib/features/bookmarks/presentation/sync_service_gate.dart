import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_repository_provider.dart';
import '../data/sync_service_provider.dart';

/// Démarre `SyncService` (Tâche 9) pour toute la durée de vie de l'app.
///
/// Ne contient aucune logique de synchronisation elle-même : se contente
/// d'appeler `SyncService.start()` une fois le service prêt, jamais avant
/// (`ref.listen` plutôt qu'un accès synchrone, car le service dépend de
/// l'ouverture asynchrone d'Isar via `bookmarkRepositoryProvider`). Purement
/// un point de branchement de cycle de vie, comme `ShareIntentGate` pour le
/// Share Intent — `SyncService.dispose()` reste géré par
/// `syncServiceProvider` lui-même (`ref.onDispose`), pas par ce widget.
///
/// Déclenche aussi `SyncService.syncNow()` explicitement à chaque connexion
/// réussie (`AuthChangeEvent.signedIn` sur [authStateChangesProvider], déjà
/// utilisé par `AppDrawer`, Tâche 28) — sans cela, les bookmarks distants
/// d'un compte existant (ex : réinstallation de l'app) ne sont rapatriés
/// qu'au prochain changement de connectivité ou passage du minuteur
/// périodique (jusqu'à `SyncService.periodicInterval`, voir Tâche 9). Rien
/// n'est déclenché à la déconnexion (`AuthChangeEvent.signedOut`) : inutile,
/// et `SyncService.syncNow()` est de toute façon un no-op sans session
/// active. Volontairement dans ce gate plutôt que dans `AuthForm`
/// (`features/auth/`) : cette dernière ne doit connaître ni `SyncService` ni
/// `syncServiceProvider`, cohérent avec la séparation de features déjà en
/// place.
class SyncServiceGate extends ConsumerStatefulWidget {
  /// Crée le gate au-dessus de [child], le contenu applicatif normal.
  const SyncServiceGate({super.key, required this.child});

  /// Contenu applicatif rendu tel quel par ce widget.
  final Widget child;

  @override
  ConsumerState<SyncServiceGate> createState() => _SyncServiceGateState();
}

class _SyncServiceGateState extends ConsumerState<SyncServiceGate> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(syncServiceProvider, (previous, next) {
      final service = next.value;
      if (service != null && !_started) {
        _started = true;
        service.start();
      }
    }, fireImmediately: true);

    ref.listenManual(authStateChangesProvider, (previous, next) {
      if (next.value?.event != AuthChangeEvent.signedIn) return;
      unawaited(ref.read(syncServiceProvider).value?.syncNow());
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
