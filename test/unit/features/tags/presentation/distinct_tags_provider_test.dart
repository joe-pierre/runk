import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/domain/video_bookmark.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_list_provider.dart';
import 'package:runk/features/tags/data/tag_repository.dart';
import 'package:runk/features/tags/data/tag_repository_provider.dart';
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

/// Court-circuite `TagRepository` (donc Isar) avec une liste de tags gérés
/// fixe — seul `getManagedTagNames` est exercé par `distinctTagsProvider`
/// (voir DECISIONS.md, entrée « Tâche 15 »), les autres méthodes ne sont
/// jamais appelées dans ces tests.
class _FakeTagRepository implements TagRepository {
  _FakeTagRepository([this._managedTagNames = const []]);

  final List<String> _managedTagNames;

  @override
  Future<List<String>> getManagedTagNames() async => _managedTagNames;

  @override
  Future<List<String>> getHiddenTagNames() async => const [];

  @override
  Future<void> createTag(String name) => throw UnimplementedError();

  @override
  Future<int> countBookmarksForTag(String name) => throw UnimplementedError();

  @override
  Future<void> renameTag(String oldName, String newName) =>
      throw UnimplementedError();

  @override
  Future<void> deleteTag(String name) => throw UnimplementedError();

  @override
  Future<void> hideTag(String name) => throw UnimplementedError();

  @override
  Future<void> unhideTag(String name) => throw UnimplementedError();
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

/// Même chose que [_bookmark], mais `isHidden: true` — pour vérifier que ses
/// tags n'apparaissent jamais dans [distinctTagsProvider] (voir DECISIONS.md,
/// entrée « Tâche 25 »).
VideoBookmark _bookmarkHidden({
  required String id,
  required List<String> tags,
}) {
  return _bookmark(id: id, tags: tags).copyWith(isHidden: true);
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
        tagRepositoryProvider.overrideWith((ref) async => _FakeTagRepository()),
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
        tagRepositoryProvider.overrideWith((ref) async => _FakeTagRepository()),
      ],
    );
    addTearDown(container.dispose);

    final tags = await container.read(distinctTagsProvider.future);

    expect(tags, isEmpty);
  });

  test('inclut un tag géré sans aucun bookmark associé (voir DECISIONS.md, '
      'entrée « Tâche 15 »)', () async {
    final container = ProviderContainer(
      overrides: [
        bookmarkListProvider.overrideWith(
          () => _FakeBookmarkList([
            _bookmark(id: '1', tags: const ['dev']),
          ]),
        ),
        tagRepositoryProvider.overrideWith(
          (ref) async => _FakeTagRepository(const ['sans-bookmark']),
        ),
      ],
    );
    addTearDown(container.dispose);

    final tags = await container.read(distinctTagsProvider.future);

    expect(tags, ['dev', 'sans-bookmark']);
  });

  test(
    'en cas de collision de casse, priorité d\'affichage au tag géré',
    () async {
      final container = ProviderContainer(
        overrides: [
          bookmarkListProvider.overrideWith(
            () => _FakeBookmarkList([
              _bookmark(id: '1', tags: const ['cuisine']),
            ]),
          ),
          tagRepositoryProvider.overrideWith(
            (ref) async => _FakeTagRepository(const ['Cuisine']),
          ),
        ],
      );
      addTearDown(container.dispose);

      final tags = await container.read(distinctTagsProvider.future);

      expect(tags, ['Cuisine']);
    },
  );

  test(
    'exclut un tag porté uniquement par des bookmarks masqués (corrige la '
    'fuite documentée en Tâche 23, voir DECISIONS.md, entrée « Tâche 25 »)',
    () async {
      final container = ProviderContainer(
        overrides: [
          bookmarkListProvider.overrideWith(
            () => _FakeBookmarkList([
              _bookmark(id: '1', tags: const ['public']),
              _bookmarkHidden(id: '2', tags: const ['secret-derive']),
            ]),
          ),
          tagRepositoryProvider.overrideWith(
            (ref) async => _FakeTagRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final tags = await container.read(distinctTagsProvider.future);

      expect(tags, ['public']);
    },
  );
}
