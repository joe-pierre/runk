import 'package:supabase_flutter/supabase_flutter.dart';

/// Accès brut à la table `tags` de Supabase (voir SPEC.md/DECISIONS.md,
/// extension de synchronisation des tags).
///
/// Responsabilité unique : exécuter les appels Supabase (`insert`, `upsert`,
/// `select`, `update`, `delete`) et retourner des `Map` brutes. Le mapping
/// vers `TagEntity` se fait exclusivement dans `TagRepository` — jamais ici
/// (voir CONVENTIONS.md section Réponses API), même patron que
/// `BookmarkRemoteDatasource`.
class TagRemoteDatasource {
  /// Crée le datasource à partir d'un [SupabaseClient] déjà initialisé
  /// (injecté pour permettre un mock dans les tests de `TagRepository`, sans
  /// connexion Supabase réelle).
  TagRemoteDatasource(this._client);

  final SupabaseClient _client;

  static const String _table = 'tags';

  /// Insère [data] dans la table `tags` et retourne la ligne créée.
  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) {
    return _client.from(_table).insert(data).select().single();
  }

  /// Insère ou remplace [data] par conflit sur la clé primaire `id`.
  Future<void> upsert(Map<String, dynamic> data) {
    return _client.from(_table).upsert(data);
  }

  /// Retourne toutes les lignes de `tags` accessibles à l'utilisateur courant
  /// (RLS).
  Future<List<Map<String, dynamic>>> selectAll() async {
    final rows = await _client.from(_table).select();
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
