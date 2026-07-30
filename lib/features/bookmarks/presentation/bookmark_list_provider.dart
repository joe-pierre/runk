import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/bookmark_repository_provider.dart';
import '../domain/video_bookmark.dart';

part 'bookmark_list_provider.g.dart';

/// Expose la liste des bookmarks à la couche présentation, triée par date de
/// création décroissante (tri déjà appliqué par
/// `BookmarkLocalDatasource.getAllActive`, voir SPEC.md section 11).
///
/// Seule façon pour un widget d'obtenir les bookmarks — jamais d'appel
/// direct à `BookmarkRepository` depuis un écran (voir CONVENTIONS.md
/// section Partials / Frontend).
@riverpod
class BookmarkList extends _$BookmarkList {
  @override
  Future<List<VideoBookmark>> build() async {
    final repository = await ref.watch(bookmarkRepositoryProvider.future);
    return repository.getAllBookmarks();
  }

  /// Recharge la liste depuis le repository — à appeler après la création
  /// d'un bookmark dans `AddBookmarkSheet`, pour que `HomeScreen` reflète
  /// immédiatement l'ajout.
  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final repository = await ref.read(bookmarkRepositoryProvider.future);
      return repository.getAllBookmarks();
    });
  }
}
