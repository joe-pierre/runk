import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/data/bookmark_local_datasource.dart';
import 'package:runk/features/bookmarks/data/bookmark_remote_datasource.dart';
import 'package:runk/features/bookmarks/data/bookmark_repository.dart';
import 'package:runk/features/bookmarks/domain/bookmark_not_found_exception.dart';
import 'package:runk/features/bookmarks/domain/video_bookmark.dart';

/// Fake du datasource distant : n'effectue jamais d'appel Supabase réel.
/// Permet de vérifier le comportement offline-first de `BookmarkRepository`
/// sans dépendre d'une connexion réseau (voir critère d'acceptation de la
/// Tâche 5).
class FakeBookmarkRemoteDatasource implements BookmarkRemoteDatasource {
  final List<Map<String, dynamic>> insertedRows = [];
  final List<String> updatedIds = [];
  final List<String> deletedIds = [];

  /// Si vrai, chaque appel lève une exception — simule une absence de
  /// connexion réseau.
  bool shouldFail = false;

  @override
  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) async {
    if (shouldFail) throw Exception('Réseau indisponible (simulation)');
    insertedRows.add(data);
    return data;
  }

  @override
  Future<List<Map<String, dynamic>>> selectAll() async {
    if (shouldFail) throw Exception('Réseau indisponible (simulation)');
    return insertedRows;
  }

  @override
  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (shouldFail) throw Exception('Réseau indisponible (simulation)');
    updatedIds.add(id);
    return data;
  }

  @override
  Future<void> delete(String id) async {
    if (shouldFail) throw Exception('Réseau indisponible (simulation)');
    deletedIds.add(id);
  }
}

void main() {
  late Directory tempDirectory;
  late Isar isar;
  late BookmarkLocalDatasource localDatasource;
  late FakeBookmarkRemoteDatasource remoteDatasource;
  late BookmarkRepository repository;

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
    localDatasource = BookmarkLocalDatasource(isar);
    remoteDatasource = FakeBookmarkRemoteDatasource();
    repository = BookmarkRepository(
      localDatasource: localDatasource,
      remoteDatasource: remoteDatasource,
    );
  });

  tearDown(() async {
    await isar.close();
    tempDirectory.deleteSync(recursive: true);
  });

  group('BookmarkRepository', () {
    test('create → read → update → delete', () async {
      final created = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=abc123',
        title: 'Ma vidéo',
        source: VideoSource.youtube,
        thumbnailUrl: 'https://img.youtube.com/thumb.jpg',
        tags: const ['drôle'],
      );

      expect(created.url, 'https://www.youtube.com/watch?v=abc123');
      expect(created.title, 'Ma vidéo');
      expect(created.source, VideoSource.youtube);
      expect(created.tags, ['drôle']);

      final afterCreate = await repository.getAllBookmarks();
      expect(afterCreate, hasLength(1));
      expect(afterCreate.single.id, created.id);

      final updated = await repository.updateBookmark(
        VideoBookmark(
          id: created.id,
          url: created.url,
          title: 'Titre modifié',
          source: created.source,
          createdAt: created.createdAt,
          updatedAt: created.updatedAt,
          thumbnailUrl: created.thumbnailUrl,
          tags: const ['drôle', 'préférée'],
        ),
      );
      expect(updated.title, 'Titre modifié');
      expect(updated.tags, ['drôle', 'préférée']);

      final afterUpdate = await repository.getAllBookmarks();
      expect(afterUpdate.single.title, 'Titre modifié');

      await repository.deleteBookmark(created.id);

      final afterDelete = await repository.getAllBookmarks();
      expect(afterDelete, isEmpty);
    });

    test(
      'updateBookmark lève BookmarkNotFoundException pour un id inconnu',
      () async {
        expect(
          () => repository.updateBookmark(
            VideoBookmark(
              id: 'id-inexistant',
              url: 'https://www.youtube.com/watch?v=x',
              title: 'Titre',
              source: VideoSource.youtube,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
          throwsA(isA<BookmarkNotFoundException>()),
        );
      },
    );

    test(
      'sans utilisateur authentifié, aucune tentative de synchronisation '
      'distante n\'est faite et le bookmark reste disponible localement',
      () async {
        await repository.createBookmark(
          url: 'https://www.tiktok.com/@user/video/1',
          title: 'Vidéo TikTok',
          source: VideoSource.tiktok,
        );

        expect(remoteDatasource.insertedRows, isEmpty);
        expect(await repository.getAllBookmarks(), hasLength(1));
      },
    );

    test('un échec réseau lors de la création laisse le bookmark disponible '
        'localement (offline-first)', () async {
      remoteDatasource.shouldFail = true;

      final created = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=offline',
        title: 'Créé hors ligne',
        source: VideoSource.youtube,
      );

      final bookmarks = await repository.getAllBookmarks();
      expect(bookmarks, hasLength(1));
      expect(bookmarks.single.id, created.id);
    });
  });
}
