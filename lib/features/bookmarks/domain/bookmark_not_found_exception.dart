/// Exception métier levée lorsqu'une opération de `BookmarkRepository`
/// (mise à jour, par exemple) référence un bookmark absent de la base
/// locale.
///
/// Distincte d'une exception réseau/Supabase : signale une erreur
/// d'utilisation de l'API du repository (identifiant inconnu), jamais un
/// échec de synchronisation (voir `BookmarkRemoteSyncException`).
class BookmarkNotFoundException implements Exception {
  /// Crée l'exception pour le bookmark d'identifiant [remoteId] introuvable.
  BookmarkNotFoundException(this.remoteId);

  /// Identifiant (`VideoBookmark.id`) recherché sans succès.
  final String remoteId;

  @override
  String toString() => 'BookmarkNotFoundException: aucun bookmark "$remoteId"';
}
