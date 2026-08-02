import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/data/bookmark_local_datasource.dart';
import 'package:runk/features/bookmarks/data/bookmark_repository.dart';
import 'package:runk/features/bookmarks/data/bookmark_repository_provider.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_search_provider.dart';
import 'package:runk/features/tags/data/tag_local_datasource.dart';

import '../data/bookmark_repository_test.dart'
    show FakeBookmarkRemoteDatasource;

void main() {
  late Directory tempDirectory;
  late Isar isar;
  late BookmarkRepository repository;
  late ProviderContainer container;

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
    repository = BookmarkRepository(
      isar: isar,
      localDatasource: BookmarkLocalDatasource(isar),
      remoteDatasource: FakeBookmarkRemoteDatasource(),
      tagLocalDatasource: TagLocalDatasource(isar),
      getCurrentUserId: () => null,
    );
    container = ProviderContainer(
      overrides: [
        bookmarkRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await isar.close();
    tempDirectory.deleteSync(recursive: true);
  });

  test(
    'une requête vide retourne une liste vide sans appeler le repository',
    () async {
      final results = await container.read(bookmarkSearchProvider('').future);
      expect(results, isEmpty);
    },
  );

  test(
    'délègue au repository et retourne les résultats correspondants',
    () async {
      await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=abc',
        title: 'Recette de cuisine',
        source: VideoSource.youtube,
        tags: const ['cuisine'],
      );

      final results = await container.read(
        bookmarkSearchProvider('recette').future,
      );

      expect(results.map((b) => b.title), ['Recette de cuisine']);
    },
  );

  test('exclut un bookmark "My Eyes Only" des résultats, même sans code saisi '
      'dans la session', () async {
    final bookmark = await repository.createBookmark(
      url: 'https://www.youtube.com/watch?v=hidden',
      title: 'Recette secrète',
      source: VideoSource.youtube,
      tags: const ['secret'],
    );
    await repository.updateBookmark(bookmark.copyWith(isHidden: true));

    final resultsByTitle = await container.read(
      bookmarkSearchProvider('recette').future,
    );
    final resultsByTag = await container.read(
      bookmarkSearchProvider('secret').future,
    );

    expect(resultsByTitle, isEmpty);
    expect(resultsByTag, isEmpty);
  });
}
