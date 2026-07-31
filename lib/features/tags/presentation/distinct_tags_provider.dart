import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../bookmarks/presentation/bookmark_list_provider.dart';

part 'distinct_tags_provider.g.dart';

/// Expose la liste des tags distincts utilisés par tous les bookmarks, triés
/// par ordre alphabétique (voir SPEC.md section 11 — écran Tags).
///
/// Dérivé de [bookmarkListProvider] : ne fait aucun accès propre à
/// `BookmarkRepository`, pour ne jamais dupliquer la source de vérité des
/// bookmarks (voir CONVENTIONS.md section Partials / Frontend).
@riverpod
Future<List<String>> distinctTags(Ref ref) async {
  final bookmarks = await ref.watch(bookmarkListProvider.future);
  final tags = <String>{};
  for (final bookmark in bookmarks) {
    tags.addAll(bookmark.tags);
  }
  final sortedTags = tags.toList()..sort();
  return sortedTags;
}
