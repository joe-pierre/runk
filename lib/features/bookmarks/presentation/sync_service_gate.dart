import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
