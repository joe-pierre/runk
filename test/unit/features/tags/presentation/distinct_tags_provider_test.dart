import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/domain/video_bookmark.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_list_provider.dart';
import 'package:runk/features/tags/presentation/distinct_tags_provider.dart';

/// Court-circuite `BookmarkRepository` (donc Isar et Supabase), comme
/// `_FakeBookmarkList` dans `home_screen_test.dart` (voir CONVENTIONS.md
/// section Tests).
class _FakeBookmarkList extends BookmarkList {
  _FakeBookmarkList(this._bookmarks);

  final List<VideoBookmark> _bookmarks;

  @override
  Future<List<VideoBookmark>> build() async => _bookmarks;
}

VideoBookmark _bookmark({required String id, required List<String> tags}) {
  return VideoBookmark(
    id: id,
    url: 'https://www.youtube.com/watch?v=$id',
    title: 'Vidéo $id',
    source: VideoSource.youtube,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    tags: tags,
  );
}

void main() {
  test('retourne les tags distincts triés alphabétiquement', () async {
    final container = ProviderContainer(
      overrides: [
        bookmarkListProvider.overrideWith(
          () => _FakeBookmarkList([
            _bookmark(id: '1', tags: const ['drole', 'cuisine']),
            _bookmark(id: '2', tags: const ['cuisine', 'dev']),
            _bookmark(id: '3', tags: const []),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final tags = await container.read(distinctTagsProvider.future);

    expect(tags, ['cuisine', 'dev', 'drole']);
  });

  test('retourne une liste vide si aucun bookmark n\'a de tag', () async {
    final container = ProviderContainer(
      overrides: [
        bookmarkListProvider.overrideWith(
          () => _FakeBookmarkList([_bookmark(id: '1', tags: const [])]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final tags = await container.read(distinctTagsProvider.future);

    expect(tags, isEmpty);
  });
}
