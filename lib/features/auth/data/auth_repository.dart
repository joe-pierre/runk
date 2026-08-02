import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_failure.dart';

/// Point d'entrée unique vers `SupabaseService.client.auth` (Tâche 28, voir
/// DECISIONS.md).
///
/// Aucun widget ni provider de présentation ne doit appeler
/// `Supabase.instance.client.auth` directement (voir CONVENTIONS.md section
/// Réponses API) — uniquement via cette classe. Toute erreur Supabase
/// (`AuthException`) est capturée ici et remontée sous forme d'[AuthFailure],
/// jamais un `catch` silencieux : la couche présentation affiche
/// systématiquement ce message à l'utilisateur (voir prompt de la Tâche 28,
/// "erreurs Supabase ... jamais avalées silencieusement").
class AuthRepository {
  /// Crée le repository à partir du client Supabase déjà initialisé par
  /// `SupabaseService` (voir `main.dart`).
  AuthRepository(this._client);

  final SupabaseClient _client;

  /// Utilisateur actuellement authentifié, ou `null` si aucune session
  /// active n'existe.
  User? get currentUser => _client.auth.currentUser;

  /// Session Supabase active courante, ou `null` si aucune.
  Session? get currentSession => _client.auth.currentSession;

  /// Flux des changements d'état d'authentification (connexion,
  /// déconnexion, rafraîchissement de session) — émet immédiatement l'état
  /// courant lors de la souscription (comportement natif de
  /// `GoTrueClient.onAuthStateChange`), ce qui permet à l'UI (sidebar) de se
  /// mettre à jour automatiquement sans état initial ambigu.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Crée un nouveau compte par email/mot de passe.
  ///
  /// Nécessite que la confirmation d'email soit désactivée côté dashboard
  /// Supabase (prérequis manuel de la Tâche 28, hors périmètre du code) pour
  /// qu'une session active soit retournée immédiatement — sinon
  /// l'utilisateur reste sans session tant qu'il n'a pas confirmé son email,
  /// ce que cette classe ne peut pas détecter autrement qu'en constatant
  /// l'absence de session après l'appel.
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  /// Connecte un utilisateur existant par email/mot de passe.
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    }
  }

  /// Termine la session Supabase courante.
  ///
  /// Ne supprime aucune donnée Isar locale — les bookmarks restent visibles
  /// et modifiables hors ligne, `SyncService` cesse simplement de
  /// synchroniser (déjà son comportement actuel via `hasActiveSession`, voir
  /// DECISIONS.md Tâche 9, rien à changer côté `SyncService`).
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    }
  }
}
