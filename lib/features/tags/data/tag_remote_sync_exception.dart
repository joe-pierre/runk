/// Exception levée lorsqu'une tentative de synchronisation d'un tag vers
/// Supabase échoue véritablement (erreur réseau, rejet RLS malgré un
/// utilisateur authentifié, erreur serveur, etc.).
///
/// Volontairement distincte du cas "utilisateur pas encore authentifié" :
/// `TagRepository` ne tente même pas la synchronisation distante tant que
/// `TagEntity.userId` est `null`, donc ce cas n'atteint jamais cette
/// exception — même raisonnement que `BookmarkRemoteSyncException` (voir
/// DECISIONS.md, entrée « Tâche 5 »).
class TagRemoteSyncException implements Exception {
  /// Crée l'exception pour le tag [name], en conservant [cause] (l'exception
  /// d'origine, ex: `PostgrestException`).
  TagRemoteSyncException(this.name, this.cause);

  /// Nom du tag (`TagEntity.name`) dont la synchronisation a échoué.
  final String name;

  /// Exception d'origine ayant causé l'échec de synchronisation.
  final Object cause;

  @override
  String toString() =>
      'TagRemoteSyncException: échec de synchronisation du tag "$name" — '
      '$cause';
}
