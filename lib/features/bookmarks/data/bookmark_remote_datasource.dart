import 'package:supabase_flutter/supabase_flutter.dart';

/// Accès brut à la table `bookmarks` de Supabase (voir SPEC.md section 3.2
/// et 7).
///
/// Responsabilité unique : exécuter les appels Supabase (`insert`, `select`,
/// `update`, `delete`) et retourner des `Map` brutes. Le mapping vers
/// `VideoBookmark` se fait exclusivement dans `BookmarkRepository` — jamais
/// ici (voir CONVENTIONS.md section Réponses API).
class BookmarkRemoteDatasource {
  /// Crée le datasource à partir d'un [SupabaseClient] déjà initialisé
  /// (injecté pour permettre un mock dans les tests de
  /// `BookmarkRepository`, sans connexion Supabase réelle).
  BookmarkRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const String _table = 'bookmarks';

  /// Insère [data] dans la table `bookmarks` et retourne la ligne créée.
  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) {
    return _client.from(_table).insert(data).select().single();
  }

  /// Insère ou remplace [data] par conflit sur la clé primaire `id`.
  ///
  /// Utilisé par `SyncService` (Tâche 9) pour rattraper les bookmarks en
  /// attente (`isSynced: false`) sans avoir à distinguer un insert d'une
  /// mise à jour — contrairement à `BookmarkRepository._trySyncInsert`/
  /// `_trySyncUpdate`, qui connaissent déjà le contexte de l'opération au
  /// moment de l'écriture initiale.
  Future<void> upsert(Map<String, dynamic> data) {
    return _client.from(_table).upsert(data);
  }

  /// Retourne toutes les lignes de `bookmarks` accessibles à l'utilisateur
  /// courant (RLS), triées par date de création décroissante.
  Future<List<Map<String, dynamic>>> selectAll() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Met à jour la ligne d'identifiant [id] avec [data] et retourne la ligne
  /// mise à jour.
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data) {
    return _client.from(_table).update(data).eq('id', id).select().single();
  }

  /// Supprime la ligne d'identifiant [id].
  Future<void> delete(String id) {
    return _client.from(_table).delete().eq('id', id);
  }
}
