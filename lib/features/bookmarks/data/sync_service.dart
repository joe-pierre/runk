import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'bookmark_repository.dart';

/// Retourne vrai si une session Supabase active existe — injecté pour
/// permettre de tester [SyncService] sans dépendre d'une connexion Supabase
/// réelle (voir CONVENTIONS.md section Tests).
typedef HasActiveSessionCheck = bool Function();

/// Synchronise en tâche de fond [BookmarkRepository] avec Supabase, sans
/// jamais bloquer l'UI (voir SPEC.md section 3.3 et 13).
///
/// Placé dans `features/bookmarks/data/` plutôt que `core/services/` (voir
/// SPEC.md section 5) : sa logique manipule directement les flags
/// `isSynced`/`isDeletedLocally` propres à `BookmarkEntity`, une
/// responsabilité de la feature bookmarks — un service `core/` qui en
/// dépendrait inverserait la dépendance `core/` → `feature/`, proscrite
/// depuis DECISIONS.md (entrées Tâche 4 et Tâche 6). Voir DECISIONS.md
/// Tâche 9 pour le détail de ce choix.
///
/// Se déclenche sur deux signaux, ni l'un ni l'autre suffisant seul pour
/// couvrir tous les cas de reconnexion (voir DECISIONS.md Tâche 9) :
/// - un changement de connectivité réseau (retour en ligne) ;
/// - un intervalle périodique fixe ([periodicInterval]), filet de sécurité
///   si l'événement de connectivité est manqué ou peu fiable sur une
///   plateforme donnée.
///
/// Ne fait jamais rien tant qu'aucune session Supabase active n'existe
/// ([hasActiveSession]) — ce n'est pas une erreur (voir DECISIONS.md, entrée
/// "user_id absent avant l'authentification"), juste un état "pas encore
/// prêt à synchroniser", cohérent avec le garde-fou déjà en place dans
/// `BookmarkRepository`.
class SyncService {
  /// Crée le service. [connectivityChanges] et [hasActiveSession] sont
  /// injectables pour les tests ; en usage réel, [connectivityChanges]
  /// utilise `Connectivity().onConnectivityChanged`.
  SyncService({
    required BookmarkRepository repository,
    required HasActiveSessionCheck hasActiveSession,
    Stream<List<ConnectivityResult>>? connectivityChanges,
    this.periodicInterval = const Duration(minutes: 2),
  }) : _repository = repository,
       _hasActiveSession = hasActiveSession,
       _connectivityChanges =
           connectivityChanges ?? Connectivity().onConnectivityChanged;

  final BookmarkRepository _repository;
  final HasActiveSessionCheck _hasActiveSession;
  final Stream<List<ConnectivityResult>> _connectivityChanges;

  /// Intervalle entre deux tentatives de synchronisation périodiques.
  final Duration periodicInterval;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicTimer;
  bool _isSyncing = false;

  /// Démarre l'écoute de la reconnexion réseau et le minuteur périodique, et
  /// tente une première synchronisation immédiate. Idempotent : un second
  /// appel sans [dispose] intermédiaire ne double pas les abonnements.
  void start() {
    if (_connectivitySubscription != null) return;

    _connectivitySubscription = _connectivityChanges.listen((results) {
      final isConnected = results.any(
        (result) => result != ConnectivityResult.none,
      );
      if (isConnected) {
        unawaited(syncNow());
      }
    });
    _periodicTimer = Timer.periodic(
      periodicInterval,
      (_) => unawaited(syncNow()),
    );
    unawaited(syncNow());
  }

  /// Arrête l'écoute de connectivité et le minuteur périodique — à appeler
  /// quand le composant propriétaire de ce service est détruit (voir
  /// `SyncServiceGate`).
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Effectue une passe complète de synchronisation : d'abord le push des
  /// changements locaux en attente (suppressions en priorité, voir
  /// [BookmarkRepository.syncPendingChanges]), puis le rapatriement des
  /// changements distants ([BookmarkRepository.pullRemoteChanges]).
  ///
  /// Ne lève jamais d'exception — un échec réel est déjà journalisé au plus
  /// près de sa source (voir `BookmarkRemoteSyncException`), et un échec de
  /// rapatriement (ex: coupure réseau en cours de route) est journalisé ici,
  /// jamais un `catch` silencieux (voir CONVENTIONS.md section Réponses
  /// API), jamais non plus bloquant pour l'UI.
  Future<void> syncNow() async {
    if (_isSyncing) return;
    if (!_hasActiveSession()) return;

    _isSyncing = true;
    try {
      await _repository.syncPendingChanges();
      await _repository.pullRemoteChanges();
    } on Exception catch (error) {
      debugPrint('SyncService.syncNow a échoué : $error');
    } finally {
      _isSyncing = false;
    }
  }
}
