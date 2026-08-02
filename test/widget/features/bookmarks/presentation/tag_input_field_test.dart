import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/domain/video_bookmark.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_list_provider.dart';
import 'package:runk/features/bookmarks/presentation/tag_input_field.dart';
import 'package:runk/features/tags/data/tag_repository.dart';
import 'package:runk/features/tags/data/tag_repository_provider.dart';

/// Court-circuite `BookmarkRepository` pour alimenter `distinctTagsProvider`
/// avec des tags fixes, comme `distinct_tags_provider_test.dart` (voir
/// CONVENTIONS.md section Tests).
class _FakeBookmarkList extends BookmarkList {
  _FakeBookmarkList(this._bookmarks);

  final List<VideoBookmark> _bookmarks;

  @override
  Future<List<VideoBookmark>> build() async => _bookmarks;
}

/// Court-circuite `TagRepository` (donc Isar) — aucun tag géré dans ces
/// tests, seuls les tags dérivés des bookmarks sont exercés (voir
/// `distinct_tags_provider_test.dart`).
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

VideoBookmark _bookmarkWithTags(List<String> tags) {
  return VideoBookmark(
    id: '1',
    url: 'https://www.youtube.com/watch?v=abc',
    title: 'Vidéo',
    source: VideoSource.youtube,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    tags: tags,
  );
}

Future<void> _pumpTagInputField(
  WidgetTester tester, {
  required List<String> existingTags,
  required List<String> tags,
  required ValueChanged<List<String>> onTagsChanged,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        bookmarkListProvider.overrideWith(
          () => _FakeBookmarkList([_bookmarkWithTags(existingTags)]),
        ),
        tagRepositoryProvider.overrideWith((ref) async => _FakeTagRepository()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: TagInputField(tags: tags, onTagsChanged: onTagsChanged),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('affiche une suggestion dont le texte tapé est un préfixe', (
    tester,
  ) async {
    await _pumpTagInputField(
      tester,
      existingTags: const ['cuisine', 'dev'],
      tags: const [],
      onTagsChanged: (_) {},
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'cui');
    await tester.pumpAndSettle();

    expect(find.text('cuisine'), findsOneWidget);
    expect(find.text('dev'), findsNothing);
  });

  testWidgets(
    'un tap sur une suggestion ajoute le tag et vide le champ de saisie',
    (tester) async {
      List<String>? updatedTags;

      await _pumpTagInputField(
        tester,
        existingTags: const ['cuisine'],
        tags: const [],
        onTagsChanged: (tags) => updatedTags = tags,
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'cui');
      await tester.pumpAndSettle();
      await tester.tap(find.text('cuisine'));
      await tester.pumpAndSettle();

      expect(updatedTags, ['cuisine']);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    },
  );

  testWidgets(
    'un tap sur le bouton "+" ajoute le tag tapé manuellement et vide le '
    'champ',
    (tester) async {
      List<String>? updatedTags;

      await _pumpTagInputField(
        tester,
        existingTags: const [],
        tags: const [],
        onTagsChanged: (tags) => updatedTags = tags,
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'randonnée');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(updatedTags, ['randonnée']);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    },
  );

  testWidgets(
    'ne propose pas un tag déjà ajouté, et ne permet pas de le dupliquer',
    (tester) async {
      var callCount = 0;

      await _pumpTagInputField(
        tester,
        existingTags: const ['cuisine'],
        tags: const ['cuisine'],
        onTagsChanged: (_) => callCount++,
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'cui');
      await tester.pumpAndSettle();

      // Seul le chip déjà ajouté affiche "cuisine" — aucune suggestion en
      // double n'apparaît sous le champ pour un tag déjà présent.
      expect(find.text('cuisine'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'cuisine');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(callCount, 0);
    },
  );
}
