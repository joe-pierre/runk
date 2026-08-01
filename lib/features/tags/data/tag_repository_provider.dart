import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../bookmarks/data/bookmark_local_datasource.dart';
import '../../bookmarks/data/bookmark_repository_provider.dart';
import 'tag_local_datasource.dart';
import 'tag_repository.dart';

part 'tag_repository_provider.g.dart';

/// Instance unique de [TagRepository], construite à partir de l'instance
/// [Isar] partagée avec les bookmarks ([bookmarkIsarProvider] — voir sa doc
/// de classe pour le détail de ce partage, DECISIONS.md entrée « Tâche 15 »).
///
/// Seul point d'accès exposé à la couche présentation — aucun widget ni
/// provider de présentation ne doit construire directement
/// `TagLocalDatasource` ou accéder à Isar (voir CONVENTIONS.md section
/// Réponses API).
@Riverpod(keepAlive: true)
Future<TagRepository> tagRepository(Ref ref) async {
  final isar = await ref.watch(bookmarkIsarProvider.future);
  return TagRepository(
    isar: isar,
    tagLocalDatasource: TagLocalDatasource(isar),
    bookmarkLocalDatasource: BookmarkLocalDatasource(isar),
  );
}
