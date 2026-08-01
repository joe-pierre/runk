import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/data/bookmark_local_datasource.dart';
import 'package:runk/features/tags/data/tag_local_datasource.dart';
import 'package:runk/features/tags/data/tag_repository.dart';

/// Crée une [BookmarkEntity] minimale valide, persistée via [datasource] —
/// mêmes valeurs par défaut que `bookmark_repository_test.dart`, seuls
/// [remoteId] et [tags] varient d'un appel à l'autre dans ces tests.
Future<BookmarkEntity> _seedBookmark(
  BookmarkLocalDatasource datasource, {
  required String remoteId,
  required List<String> tags,
}) async {
  final entity = BookmarkEntity()
    ..remoteId = remoteId
    ..url = 'https://www.youtube.com/watch?v=$remoteId'
    ..title = 'Vidéo $remoteId'
    ..source = VideoSource.youtube.name
    ..tags = tags
    ..createdAt = DateTime(2026)
    ..updatedAt = DateTime(2026)
    ..isSynced = true
    ..isDeletedLocally = false;
  await datasource.upsert(entity);
  return entity;
}

void main() {
  late Directory tempDirectory;
  late Isar isar;
  late BookmarkLocalDatasource bookmarkLocalDatasource;
  late TagLocalDatasource tagLocalDatasource;
  late TagRepository repository;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync('runk_isar_tag_test');
    isar = await Isar.open(
      [BookmarkEntitySchema, TagEntitySchema],
      directory: tempDirectory.path,
      inspector: false,
    );
    bookmarkLocalDatasource = BookmarkLocalDatasource(isar);
    tagLocalDatasource = TagLocalDatasource(isar);
    repository = TagRepository(
      isar: isar,
      tagLocalDatasource: tagLocalDatasource,
      bookmarkLocalDatasource: bookmarkLocalDatasource,
    );
  });

  tearDown(() async {
    await isar.close();
    tempDirectory.deleteSync(recursive: true);
  });

  group('createTag', () {
    test('crée un tag géré visible sans aucun bookmark associé', () async {
      await repository.createTag('cuisine');

      expect(await repository.getManagedTagNames(), ['cuisine']);
    });

    test(
      'no-op silencieux si un tag équivalent existe déjà (casse différente)',
      () async {
        await repository.createTag('Cuisine');
        await repository.createTag('cuisine');

        expect(await repository.getManagedTagNames(), ['Cuisine']);
      },
    );
  });

  group('renameTag', () {
    test('propage le nouveau nom sur tous les bookmarks concernés', () async {
      await repository.createTag('cuisine');
      await _seedBookmark(
        bookmarkLocalDatasource,
        remoteId: 'b1',
        tags: const ['cuisine', 'facile'],
      );
      await _seedBookmark(
        bookmarkLocalDatasource,
        remoteId: 'b2',
        tags: const ['cuisine'],
      );
      await _seedBookmark(
        bookmarkLocalDatasource,
        remoteId: 'b3',
        tags: const ['dessert'],
      );

      await repository.renameTag('cuisine', 'gastronomie');

      expect(await repository.getManagedTagNames(), ['gastronomie']);
      final b1 = await bookmarkLocalDatasource.findByRemoteId('b1');
      final b2 = await bookmarkLocalDatasource.findByRemoteId('b2');
      final b3 = await bookmarkLocalDatasource.findByRemoteId('b3');
      expect(b1!.tags, ['gastronomie', 'facile']);
      expect(b2!.tags, ['gastronomie']);
      expect(b3!.tags, ['dessert']);
      // Les bookmarks modifiés doivent être remarqués comme en attente de
      // synchronisation (voir SPEC.md section 4 règle 2, offline-first).
      expect(b1.isSynced, isFalse);
      expect(b2.isSynced, isFalse);
      expect(b3.isSynced, isTrue);
    });

    test(
      'renommer un tag purement dérivé (sans TagEntity) crée ce TagEntity',
      () async {
        await _seedBookmark(
          bookmarkLocalDatasource,
          remoteId: 'b1',
          tags: const ['brouillon'],
        );
        expect(await tagLocalDatasource.findByName('brouillon'), isNull);

        await repository.renameTag('brouillon', 'publié');

        expect(await repository.getManagedTagNames(), ['publié']);
        final b1 = await bookmarkLocalDatasource.findByRemoteId('b1');
        expect(b1!.tags, ['publié']);
      },
    );
  });

  group('deleteTag', () {
    test('countBookmarksForTag compte les bookmarks impactés', () async {
      await _seedBookmark(
        bookmarkLocalDatasource,
        remoteId: 'b1',
        tags: const ['voyage'],
      );
      await _seedBookmark(
        bookmarkLocalDatasource,
        remoteId: 'b2',
        tags: const ['voyage', 'plage'],
      );
      await _seedBookmark(
        bookmarkLocalDatasource,
        remoteId: 'b3',
        tags: const ['plage'],
      );

      expect(await repository.countBookmarksForTag('voyage'), 2);
      expect(await repository.countBookmarksForTag('inexistant'), 0);
    });

    test(
      'retire le tag (cascade) de tous les bookmarks concernés et supprime '
      'le TagEntity',
      () async {
        await repository.createTag('voyage');
        await _seedBookmark(
          bookmarkLocalDatasource,
          remoteId: 'b1',
          tags: const ['voyage'],
        );
        await _seedBookmark(
          bookmarkLocalDatasource,
          remoteId: 'b2',
          tags: const ['voyage', 'plage'],
        );
        await _seedBookmark(
          bookmarkLocalDatasource,
          remoteId: 'b3',
          tags: const ['plage'],
        );

        await repository.deleteTag('voyage');

        expect(await tagLocalDatasource.findByName('voyage'), isNull);
        final b1 = await bookmarkLocalDatasource.findByRemoteId('b1');
        final b2 = await bookmarkLocalDatasource.findByRemoteId('b2');
        final b3 = await bookmarkLocalDatasource.findByRemoteId('b3');
        expect(b1!.tags, isEmpty);
        expect(b2!.tags, ['plage']);
        expect(b3!.tags, ['plage']);
      },
    );

    test(
      'supprimer un tag purement dérivé (sans TagEntity) le retire quand '
      'même de tous les bookmarks',
      () async {
        await _seedBookmark(
          bookmarkLocalDatasource,
          remoteId: 'b1',
          tags: const ['brouillon'],
        );

        await repository.deleteTag('brouillon');

        final b1 = await bookmarkLocalDatasource.findByRemoteId('b1');
        expect(b1!.tags, isEmpty);
      },
    );
  });
}
