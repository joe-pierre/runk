/// Erreur d'authentification remontée par `AuthRepository`.
///
/// Enveloppe le message d'erreur Supabase (mauvais mot de passe, email déjà
/// utilisé, etc.) dans un type propre à la couche métier, pour que la
/// couche présentation puisse l'afficher sans dépendre directement du type
/// `AuthException` de `package:supabase_flutter` (voir CONVENTIONS.md
/// section Réponses API : "les erreurs réseau/API sont capturées dans le
/// repository et remontées sous forme ... d'exception métier dédiée").
class AuthFailure implements Exception {
  /// Crée l'échec avec le [message] destiné à être affiché tel quel à
  /// l'utilisateur (déjà en français côté Supabase pour les cas courants,
  /// ou traduit au besoin par l'appelant).
  const AuthFailure(this.message);

  /// Message d'erreur à afficher à l'utilisateur.
  final String message;

  @override
  String toString() => message;
}
