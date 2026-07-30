import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_service.dart';
import 'bookmark_local_datasource.dart';
import 'bookmark_remote_datasource.dart';
import 'bookmark_repository.dart';

part 'bookmark_repository_provider.g.dart';

/// Ouvre l'unique instance [Isar] de la feature bookmarks, dans le
/// répertoire de documents de l'application.
///
/// Vit ici plutôt que dans `core/` : le schéma ouvert (`BookmarkEntitySchema`)
/// est propre à cette feature, et `core/` ne doit jamais dépendre d'une
/// `feature/` (voir DECISIONS.md, entrée Tâche 4). `keepAlive: true` car
/// l'instance doit rester ouverte pour toute la durée de vie de l'app.
@Riverpod(keepAlive: true)
Future<Isar> bookmarkIsar(Ref ref) async {
  final directory = await getApplicationDocumentsDirectory();
  return Isar.open([BookmarkEntitySchema], directory: directory.path);
}

/// Instance unique de [BookmarkRepository], construite à partir de l'Isar
/// local ([bookmarkIsarProvider]) et du client Supabase déjà initialisé par
/// `SupabaseService` (voir `main.dart`).
///
/// Seul point d'accès exposé à la couche présentation — aucun widget ni
/// provider de présentation ne doit construire directement
/// `BookmarkLocalDatasource` ou `BookmarkRemoteDatasource` (voir
/// CONVENTIONS.md section Réponses API).
@Riverpod(keepAlive: true)
Future<BookmarkRepository> bookmarkRepository(Ref ref) async {
  final isar = await ref.watch(bookmarkIsarProvider.future);
  return BookmarkRepository(
    localDatasource: BookmarkLocalDatasource(isar),
    remoteDatasource: BookmarkRemoteDatasource(SupabaseService.client),
  );
}
