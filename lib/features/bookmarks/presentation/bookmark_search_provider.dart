import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/bookmark_repository_provider.dart';
import '../domain/video_bookmark.dart';

part 'bookmark_search_provider.g.dart';

/// Résultats de recherche full-text (titre + tags) pour la requête [query]
/// (voir SPEC.md section 11 — écran Recherche).
///
/// Délègue entièrement à
/// [BookmarkRepository.searchBookmarks](../data/bookmark_repository.dart),
/// qui n'interroge que l'Isar local — aucun appel réseau direct ici (voir
/// contrainte de la Tâche 9). Une requête vide retourne une liste vide sans
/// solliciter le repository, pour ne pas afficher tous les bookmarks avant
/// toute saisie.
@riverpod
Future<List<VideoBookmark>> bookmarkSearch(Ref ref, String query) async {
  final trimmedQuery = query.trim();
  if (trimmedQuery.isEmpty) return const [];

  final repository = await ref.watch(bookmarkRepositoryProvider.future);
  return repository.searchBookmarks(trimmedQuery);
}
