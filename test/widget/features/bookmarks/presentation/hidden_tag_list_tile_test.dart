import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/data/bookmark_local_datasource.dart';
import 'package:runk/features/bookmarks/data/bookmark_repository.dart';
import 'package:runk/features/bookmarks/data/bookmark_repository_provider.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_list_provider.dart';
import 'package:runk/features/bookmarks/presentation/hidden_tag_list_tile.dart';
import 'package:runk/features/tags/data/tag_local_datasource.dart';
import 'package:runk/features/tags/data/tag_repository.dart';
import 'package:runk/features/tags/data/tag_repository_provider.dart';
import 'package:runk/features/tags/presentation/hidden_tags_provider.dart';

import '../../../../unit/features/bookmarks/data/bookmark_repository_test.dart'
    show FakeBookmarkRemoteDatasource;

void main() {
  late Directory tempDirectory;
  late Isar isar;
  late BookmarkRepository bookmarkRepository;
  late TagRepository tagRepository;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('runk_isar_test');
    isar = await Isar.open(
      [BookmarkEntitySchema, TagEntitySchema],
      directory: tempDirectory.path,
      inspector: false,
    );
    final bookmarkLocalDatasource = BookmarkLocalDatasource(isar);
    final tagLocalDatasource = TagLocalDatasource(isar);
    bookmarkRepository = BookmarkRepository(
      isar: isar,
      localDatasource: bookmarkLocalDatasource,
      remoteDatasource: FakeBookmarkRemoteDatasource(),
      tagLocalDatasource: tagLocalDatasource,
      getCurrentUserId: () => null,
    );
    tagRepository = TagRepository(
      isar: isar,
      tagLocalDatasource: tagLocalDatasource,
      bookmarkLocalDatasource: bookmarkLocalDatasource,
    );
  });

  tearDown(() async {
    await isar.close();
    tempDirectory.deleteSync(recursive: true);
  });

  // Même raison que `hidden_bookmark_menu_button_test.dart` : les opérations
  // Isar réelles ont besoin d'un vrai tour d'event loop, jamais disponible
  // sous le simple `pump()` de `AutomatedTestWidgetsFlutterBinding`.
  Future<void> pumpFrames(WidgetTester tester, [int count = 20]) async {
    for (var i = 0; i < count; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      await tester.pump(const Duration(milliseconds: 25));
    }
  }

  // Même raison que `hidden_bookmark_menu_button_test.dart` : sans lecteur
  // actif des providers `@riverpod` auto-dispose consultés par
  // `HiddenTagListTile._unhide`, ils seraient recréés entre les deux `await`
  // de la méthode.
  Future<void> pumpTile(WidgetTester tester, String tagName) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarkRepositoryProvider.overrideWith(
            (ref) async => bookmarkRepository,
          ),
          tagRepositoryProvider.overrideWith((ref) async => tagRepository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                ref.watch(bookmarkListProvider);
                ref.watch(hiddenTagsProvider);
                return HiddenTagListTile(tagName: tagName);
              },
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    '"Ne plus masquer ce tag" appelle TagRepository.unhideTag et démasque '
    'les bookmarks concernés',
    (tester) async {
      await tester.runAsync(() async {
        await bookmarkRepository.createBookmark(
          url: 'https://www.youtube.com/watch?v=abc',
          title: 'Vidéo secrète',
          source: VideoSource.youtube,
          tags: const ['secret'],
        );
        await tagRepository.hideTag('secret');

        await pumpTile(tester, 'secret');
        await pumpFrames(tester);

        expect(find.text('secret'), findsOneWidget);

        await tester.tap(find.byTooltip('Ne plus masquer ce tag'));
        await pumpFrames(tester);

        List<String> hiddenNames;
        var attempts = 0;
        do {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          hiddenNames = await tagRepository.getHiddenTagNames();
          attempts++;
        } while (hiddenNames.isNotEmpty && attempts < 100);
        expect(hiddenNames, isEmpty);

        final bookmarks = await bookmarkRepository.getAllBookmarks();
        expect(bookmarks.single.isHidden, isFalse);
      });
    },
  );
}
