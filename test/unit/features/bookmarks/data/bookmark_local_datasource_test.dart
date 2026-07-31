import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/data/bookmark_local_datasource.dart';

void main() {
  late Directory tempDirectory;
  late Isar isar;
  late BookmarkLocalDatasource datasource;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('runk_isar_test');
    isar = await Isar.open(
      [BookmarkEntitySchema],
      directory: tempDirectory.path,
      inspector: false,
    );
    datasource = BookmarkLocalDatasource(isar);
  });

  tearDown(() async {
    await isar.close();
    tempDirectory.deleteSync(recursive: true);
  });

  BookmarkEntity entity({
    required String remoteId,
    String? userId,
    bool isSynced = false,
    bool isDeletedLocally = false,
    String title = 'Titre',
    List<String> tags = const [],
  }) {
    return BookmarkEntity()
      ..remoteId = remoteId
      ..userId = userId
      ..url = 'https://www.youtube.com/watch?v=$remoteId'
      ..title = title
      ..source = VideoSource.youtube.name
      ..tags = tags
      ..createdAt = DateTime(2026)
      ..updatedAt = DateTime(2026)
      ..isSynced = isSynced
      ..isDeletedLocally = isDeletedLocally;
  }

  group('getAllPendingUpload', () {
    test('retourne les entités non synchronisées et non supprimées', () async {
      await datasource.upsert(entity(remoteId: 'a', isSynced: false));
      await datasource.upsert(
        entity(remoteId: 'b', isSynced: false, isDeletedLocally: true),
      );
      await datasource.upsert(entity(remoteId: 'c', isSynced: true));

      final pending = await datasource.getAllPendingUpload();

      expect(pending.map((e) => e.remoteId), ['a']);
    });
  });

  group('getAllPendingDeletion', () {
    test('retourne uniquement les entités marquées isDeletedLocally', () async {
      await datasource.upsert(
        entity(remoteId: 'a', isDeletedLocally: true),
      );
      await datasource.upsert(entity(remoteId: 'b'));

      final pending = await datasource.getAllPendingDeletion();

      expect(pending.map((e) => e.remoteId), ['a']);
    });
  });

  group('getAllSyncedRemoteIds', () {
    test(
      'retourne les remoteId des entités synchronisées et non supprimées',
      () async {
        await datasource.upsert(entity(remoteId: 'a', isSynced: true));
        await datasource.upsert(entity(remoteId: 'b', isSynced: false));
        await datasource.upsert(
          entity(remoteId: 'c', isSynced: true, isDeletedLocally: true),
        );

        final syncedIds = await datasource.getAllSyncedRemoteIds();

        expect(syncedIds, ['a']);
      },
    );
  });

  group('searchByTitleOrTags', () {
    test('trouve par titre, insensible à la casse', () async {
      await datasource.upsert(
        entity(remoteId: 'a', title: 'Recette de cuisine'),
      );
      await datasource.upsert(entity(remoteId: 'b', title: 'Tutoriel'));

      final results = await datasource.searchByTitleOrTags('RECETTE');

      expect(results.map((e) => e.remoteId), ['a']);
    });

    test('trouve par tag', () async {
      await datasource.upsert(
        entity(remoteId: 'a', title: 'Vidéo', tags: const ['cuisine']),
      );
      await datasource.upsert(entity(remoteId: 'b', title: 'Autre'));

      final results = await datasource.searchByTitleOrTags('cuisine');

      expect(results.map((e) => e.remoteId), ['a']);
    });

    test('exclut les bookmarks supprimés localement', () async {
      await datasource.upsert(
        entity(remoteId: 'a', title: 'Recette', isDeletedLocally: true),
      );

      final results = await datasource.searchByTitleOrTags('recette');

      expect(results, isEmpty);
    });
  });
}
