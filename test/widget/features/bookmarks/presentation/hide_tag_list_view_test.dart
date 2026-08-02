import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/data/bookmark_local_datasource.dart';
import 'package:runk/features/bookmarks/data/bookmark_repository.dart';
import 'package:runk/features/bookmarks/data/bookmark_repository_provider.dart';
import 'package:runk/features/bookmarks/presentation/hide_tag_list_view.dart';
import 'package:runk/features/tags/data/tag_local_datasource.dart';
import 'package:runk/features/tags/data/tag_repository.dart';
import 'package:runk/features/tags/data/tag_repository_provider.dart';

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

  Future<void> pumpFrames(WidgetTester tester, [int count = 20]) async {
    for (var i = 0; i < count; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      await tester.pump(const Duration(milliseconds: 25));
    }
  }

  Future<void> pumpView(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarkRepositoryProvider.overrideWith(
            (ref) async => bookmarkRepository,
          ),
          tagRepositoryProvider.overrideWith((ref) async => tagRepository),
        ],
        child: const MaterialApp(home: Scaffold(body: HideTagListView())),
      ),
    );
  }

  testWidgets(
    'liste les tags visibles et un tap masque le tag choisi, en cascade '
    'sur les bookmarks qui le portent',
    (tester) async {
      await tester.runAsync(() async {
        await bookmarkRepository.createBookmark(
          url: 'https://www.youtube.com/watch?v=abc',
          title: 'Vidéo',
          source: VideoSource.youtube,
          tags: const ['cuisine', 'voyage'],
        );

        await pumpView(tester);
        await pumpFrames(tester);

        expect(find.text('cuisine'), findsOneWidget);
        expect(find.text('voyage'), findsOneWidget);

        await tester.tap(find.text('cuisine'));
        await pumpFrames(tester);

        List<String> hiddenNames;
        var attempts = 0;
        do {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          hiddenNames = await tagRepository.getHiddenTagNames();
          attempts++;
        } while (hiddenNames.isEmpty && attempts < 100);
        expect(hiddenNames, ['cuisine']);

        final bookmarks = await bookmarkRepository.getAllBookmarks();
        expect(bookmarks.single.isHidden, isTrue);
      });
    },
  );

  testWidgets('affiche un message si aucun tag à masquer', (tester) async {
    await tester.runAsync(() async {
      await pumpView(tester);
      await pumpFrames(tester);

      expect(find.text('Aucun tag à masquer.'), findsOneWidget);
    });
  });
}
