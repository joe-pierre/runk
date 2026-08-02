import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/domain/video_bookmark.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_list_provider.dart';
import 'package:runk/features/bookmarks/presentation/my_eyes_only_screen.dart';
import 'package:runk/features/tags/data/tag_repository.dart';
import 'package:runk/features/tags/data/tag_repository_provider.dart';
import 'package:runk/features/tags/presentation/hidden_tags_provider.dart';

/// Notifier de test qui court-circuite `BookmarkRepository` (donc Isar et
/// Supabase) — même pattern que `home_screen_test.dart`.
class _FakeBookmarkList extends BookmarkList {
  _FakeBookmarkList(this._bookmarks);

  final List<VideoBookmark> _bookmarks;

  @override
  Future<List<VideoBookmark>> build() async => _bookmarks;
}

/// Court-circuite `TagRepository` (donc Isar) — `MyEyesOnlyScreen` consulte
/// désormais `hiddenTagsProvider` (Tâche 25, voir DECISIONS.md), qui en
/// dépend. Aucun tag masqué dans ces tests : seul le comportement des
/// bookmarks masqués est exercé ici (voir `hidden_tag_list_tile_test.dart`
/// pour la section "Tags masqués" elle-même).
class _FakeTagRepository implements TagRepository {
  @override
  Future<List<String>> getManagedTagNames() async => const [];

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

void main() {
  testWidgets('affiche un message quand aucun bookmark n\'est masqué', (
    tester,
  ) async {
    final visible = VideoBookmark(
      id: '1',
      url: 'https://youtube.com/watch?v=abc',
      title: 'Vidéo visible',
      source: VideoSource.youtube,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarkListProvider.overrideWith(() => _FakeBookmarkList([visible])),
          tagRepositoryProvider.overrideWith(
            (ref) async => _FakeTagRepository(),
          ),
        ],
        child: const MaterialApp(home: MyEyesOnlyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucun bookmark masqué.'), findsOneWidget);
    expect(find.text('Vidéo visible'), findsNothing);
  });

  testWidgets('affiche uniquement les bookmarks isHidden: true, en réutilisant '
      'BookmarkCard', (tester) async {
    final visible = VideoBookmark(
      id: '1',
      url: 'https://youtube.com/watch?v=abc',
      title: 'Vidéo visible',
      source: VideoSource.youtube,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final hidden = VideoBookmark(
      id: '2',
      url: 'https://youtube.com/watch?v=xyz',
      title: 'Vidéo masquée',
      source: VideoSource.youtube,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isHidden: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarkListProvider.overrideWith(
            () => _FakeBookmarkList([visible, hidden]),
          ),
          tagRepositoryProvider.overrideWith(
            (ref) async => _FakeTagRepository(),
          ),
        ],
        child: const MaterialApp(home: MyEyesOnlyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vidéo masquée'), findsOneWidget);
    expect(find.text('Vidéo visible'), findsNothing);
  });

  testWidgets('le bouton "+" ouvre AddToMyEyesOnlyScreen (Tâche 24)', (
    tester,
  ) async {
    final hidden = VideoBookmark(
      id: '2',
      url: 'https://youtube.com/watch?v=xyz',
      title: 'Vidéo masquée',
      source: VideoSource.youtube,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isHidden: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarkListProvider.overrideWith(() => _FakeBookmarkList([hidden])),
          tagRepositoryProvider.overrideWith(
            (ref) async => _FakeTagRepository(),
          ),
        ],
        child: const MaterialApp(home: MyEyesOnlyScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Ajouter à My Eyes Only'), findsOneWidget);
  });

  testWidgets(
    'n\'affiche aucune section "Tags masqués" tant qu\'aucun tag n\'est '
    'masqué',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkListProvider.overrideWith(() => _FakeBookmarkList([])),
            tagRepositoryProvider.overrideWith(
              (ref) async => _FakeTagRepository(),
            ),
          ],
          child: const MaterialApp(home: MyEyesOnlyScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tags masqués'), findsNothing);
    },
  );

  testWidgets(
    'affiche la section "Tags masqués" (Tâche 25) avec une action "Ne plus '
    'masquer ce tag" par tag',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkListProvider.overrideWith(() => _FakeBookmarkList([])),
            hiddenTagsProvider.overrideWith((ref) async => const ['secret']),
          ],
          child: const MaterialApp(home: MyEyesOnlyScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tags masqués'), findsOneWidget);
      expect(find.text('secret'), findsOneWidget);
      expect(find.byTooltip('Ne plus masquer ce tag'), findsOneWidget);
    },
  );
}
