/// Exception levée lorsqu'une tentative de synchronisation d'un bookmark
/// vers Supabase échoue véritablement (erreur réseau, rejet RLS malgré un
/// utilisateur authentifié, erreur serveur, etc.).
///
/// Volontairement distincte du cas "utilisateur pas encore authentifié" :
/// `BookmarkRepository` ne tente même pas la synchronisation distante tant
/// que `BookmarkEntity.userId` est `null`, donc ce cas n'atteint jamais
/// cette exception. Elle ne signale que de vrais échecs de synchronisation,
/// pour que le futur `sync_service.dart` (voir SPEC.md section 13 et
/// DECISIONS.md) puisse un jour les différencier d'une simple absence de
/// session plutôt que de tout traiter comme un `isSynced = false`
/// indifférencié.
class BookmarkRemoteSyncException implements Exception {
  /// Crée l'exception pour le bookmark [remoteId], en conservant [cause]
  /// (l'exception d'origine, ex: `PostgrestException`).
  BookmarkRemoteSyncException(this.remoteId, this.cause);

  /// Identifiant (`VideoBookmark.id`) dont la synchronisation a échoué.
  final String remoteId;

  /// Exception d'origine ayant causé l'échec de synchronisation.
  final Object cause;

  @override
  String toString() =>
      'BookmarkRemoteSyncException: échec de synchronisation du bookmark '
      '"$remoteId" — $cause';
}
