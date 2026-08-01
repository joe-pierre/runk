import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/supabase_service.dart';
import '../../tags/data/tag_local_datasource.dart';
import 'bookmark_local_datasource.dart';
import 'bookmark_remote_datasource.dart';
import 'bookmark_repository.dart';

part 'bookmark_repository_provider.g.dart';

/// Ouvre l'unique instance [Isar] de l'application, dans le répertoire de
/// documents.
///
/// Vit ici plutôt que dans `core/` : les schémas ouverts (`BookmarkEntitySchema`,
/// `TagEntitySchema`) sont propres à des features, et `core/` ne doit jamais
/// dépendre d'une `feature/` (voir DECISIONS.md, entrée Tâche 4). `keepAlive:
/// true` car l'instance doit rester ouverte pour toute la durée de vie de
/// l'app.
///
/// Historiquement propre à la feature bookmarks (seule collection Isar
/// existante, voir DECISIONS.md entrée Tâche 6), cette instance est devenue
/// partagée avec la feature tags depuis la Tâche 15 : `TagRepository` a
/// besoin de modifier `TagEntity` et `BookmarkEntity` dans une **même**
/// transaction Isar (Isar interdit les transactions imbriquées, donc les
/// deux collections doivent appartenir à la même instance ouverte par un
/// seul `Isar.open`). Reste dans `features/bookmarks/data/` plutôt que
/// déplacé vers un nouveau composant partagé : déplacer l'ouverture
/// elle-même sans en avoir un troisième consommateur réel serait anticiper
/// une factorisation non justifiée (même raisonnement que DECISIONS.md,
/// entrée Tâche 6.5) — voir DECISIONS.md, entrée « Tâche 15 » pour le détail
/// de cette dépendance croisée `bookmarks/data` ↔ `tags/data`.
@Riverpod(keepAlive: true)
Future<Isar> bookmarkIsar(Ref ref) async {
  final directory = await getApplicationDocumentsDirectory();
  return Isar.open([
    BookmarkEntitySchema,
    TagEntitySchema,
  ], directory: directory.path);
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
