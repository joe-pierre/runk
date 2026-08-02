import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/data/bookmark_local_datasource.dart';
import 'package:runk/features/bookmarks/data/bookmark_remote_datasource.dart';
import 'package:runk/features/bookmarks/data/bookmark_repository.dart';
import 'package:runk/features/bookmarks/domain/bookmark_not_found_exception.dart';
import 'package:runk/features/bookmarks/domain/video_bookmark.dart';
import 'package:runk/features/tags/data/tag_local_datasource.dart';

/// Fake du datasource distant : n'effectue jamais d'appel Supabase réel.
/// Permet de vérifier le comportement offline-first de `BookmarkRepository`
/// sans dépendre d'une connexion réseau (voir critère d'acceptation de la
/// Tâche 5).
class FakeBookmarkRemoteDatasource implements BookmarkRemoteDatasource {
  final List<Map<String, dynamic>> insertedRows = [];
  final List<String> updatedIds = [];
  final List<String> deletedIds = [];
  final List<Map<String, dynamic>> upsertedRows = [];

  /// Ordre chronologique de tous les appels (`insert:<id>`, `update:<id>`,
  /// `delete:<id>`, `upsert:<id>`) — utilisé par `sync_service_test.dart`
  /// pour vérifier que les suppressions en attente sont bien traitées avant
  /// tout autre envoi (voir SPEC.md section 13).
  final List<String> callOrder = [];

  /// État actuel de la table distante simulée, indexé par `id` — permet de
  /// représenter des lignes déjà présentes côté serveur (ex: créées par un
  /// autre appareil) sans passer par `insert`/`upsert` de ce fake, pour
  /// tester `BookmarkRepository.pullRemoteChanges`.
  final Map<String, Map<String, dynamic>> remoteRows = {};

  /// Si vrai, chaque appel lève une exception — simule une absence de
  /// connexion réseau.
  bool shouldFail = false;

  @override
  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) async {
    if (shouldFail) throw Exception('Réseau indisponible (simulation)');
    insertedRows.add(data);
    remoteRows[data['id'] as String] = data;
    callOrder.add('insert:${data['id']}');
    return data;
  }

  @override
  Future<List<Map<String, dynamic>>> selectAll() async {
    if (shouldFail) throw Exception('Réseau indisponible (simulation)');
    return remoteRows.values.toList();
  }

  @override
  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (shouldFail) throw Exception('Réseau indisponible (simulation)');
    updatedIds.add(id);
    remoteRows[id] = data;
    callOrder.add('update:$id');
    return data;
  }

  @override
  Future<void> delete(String id) async {
    if (shouldFail) throw Exception('Réseau indisponible (simulation)');
    deletedIds.add(id);
    remoteRows.remove(id);
    callOrder.add('delete:$id');
  }

  @override
  Future<void> upsert(Map<String, dynamic> data) async {
    if (shouldFail) throw Exception('Réseau indisponible (simulation)');
    upsertedRows.add(data);
    remoteRows[data['id'] as String] = data;
    callOrder.add('upsert:${data['id']}');
  }
}

void main() {
  late Directory tempDirectory;
  late Isar isar;
  late BookmarkLocalDatasource localDatasource;
  late TagLocalDatasource tagLocalDatasource;
  late FakeBookmarkRemoteDatasource remoteDatasource;
  late BookmarkRepository repository;

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
    localDatasource = BookmarkLocalDatasource(isar);
    tagLocalDatasource = TagLocalDatasource(isar);
    remoteDatasource = FakeBookmarkRemoteDatasource();
    repository = BookmarkRepository(
      isar: isar,
      localDatasource: localDatasource,
      remoteDatasource: remoteDatasource,
      tagLocalDatasource: tagLocalDatasource,
      getCurrentUserId: () => null,
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

  group('isHidden (Tâche 22 — My Eyes Only)', () {
    test('un bookmark créé est isHidden: false par défaut', () async {
      final created = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=abc',
        title: 'Vidéo',
        source: VideoSource.youtube,
      );

      expect(created.isHidden, isFalse);
    });

    test('updateBookmark persiste isHidden: true, et il est bien restitué par '
        'getAllBookmarks', () async {
      final created = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=abc',
        title: 'Vidéo',
        source: VideoSource.youtube,
      );

      await repository.updateBookmark(created.copyWith(isHidden: true));

      final bookmarks = await repository.getAllBookmarks();
      expect(bookmarks.single.isHidden, isTrue);
    });

    test('unhideAllBookmarks démasque tous les bookmarks masqués sans toucher '
        'aux autres, ni les supprimer', () async {
      final hidden = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=hidden',
        title: 'Masqué',
        source: VideoSource.youtube,
      );
      final visible = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=visible',
        title: 'Visible',
        source: VideoSource.youtube,
      );
      await repository.updateBookmark(hidden.copyWith(isHidden: true));

      await repository.unhideAllBookmarks();

      final bookmarks = await repository.getAllBookmarks();
      expect(bookmarks, hasLength(2));
      expect(bookmarks.every((bookmark) => !bookmark.isHidden), isTrue);
      expect(
        bookmarks.map((bookmark) => bookmark.id),
        containsAll([hidden.id, visible.id]),
      );
    });

    test(
      'is_hidden est bien mappé vers/depuis la ligne distante Supabase',
      () async {
        final created = await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=abc',
          title: 'Vidéo',
          source: VideoSource.youtube,
        );
        await repository.updateBookmark(created.copyWith(isHidden: true));

        remoteDatasource.remoteRows['remote-hidden'] = {
          'id': 'remote-hidden',
          'user_id': 'user-1',
          'url': 'https://www.youtube.com/watch?v=xyz',
          'title': 'Depuis un autre appareil',
          'thumbnail_url': null,
          'source': VideoSource.youtube.name,
          'tags': <String>[],
          'note': null,
          'is_partial': false,
          'is_hidden': true,
          'created_at': DateTime(2026).toIso8601String(),
          'updated_at': DateTime(2026).toIso8601String(),
        };
        await repository.pullRemoteChanges();

        final bookmarks = await repository.getAllBookmarks();
        final pulled = bookmarks.firstWhere((b) => b.id == 'remote-hidden');
        expect(pulled.isHidden, isTrue);
      },
    );
  });

  group('isHidden via un tag masqué (Tâche 25 — My Eyes Only, tags)', () {
    test('un bookmark créé avec un tag masqué est automatiquement isHidden: '
        'true, sans action supplémentaire', () async {
      await tagLocalDatasource.upsert(
        TagEntity()
          ..name = 'secret'
          ..isHidden = true,
      );

      final created = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=abc',
        title: 'Vidéo',
        source: VideoSource.youtube,
        tags: const ['secret', 'autre'],
      );

      expect(created.isHidden, isTrue);
    });

    test('ajouter un tag masqué à un bookmark existant via updateBookmark le '
        'masque automatiquement, même si isHidden: false est fourni '
        'explicitement (extension de "Modifier les tags", Tâche 21)', () async {
      final created = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=abc',
        title: 'Vidéo',
        source: VideoSource.youtube,
        tags: const ['public'],
      );
      expect(created.isHidden, isFalse);
      await tagLocalDatasource.upsert(
        TagEntity()
          ..name = 'secret'
          ..isHidden = true,
      );

      final updated = await repository.updateBookmark(
        created.copyWith(tags: const ['public', 'secret'], isHidden: false),
      );

      expect(updated.isHidden, isTrue);
      final bookmarks = await repository.getAllBookmarks();
      expect(bookmarks.single.isHidden, isTrue);
    });

    test('retirer le tag masqué d\'un bookmark ne le démasque pas '
        'automatiquement (aucun mécanisme ne distingue pourquoi il est '
        'masqué, voir DECISIONS.md)', () async {
      await tagLocalDatasource.upsert(
        TagEntity()
          ..name = 'secret'
          ..isHidden = true,
      );
      final created = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=abc',
        title: 'Vidéo',
        source: VideoSource.youtube,
        tags: const ['secret'],
      );
      expect(created.isHidden, isTrue);

      final updated = await repository.updateBookmark(
        created.copyWith(tags: const []),
      );

      expect(updated.isHidden, isTrue);
    });
  });

  group('syncPendingChanges', () {
    test('pousse via upsert une entité en attente appartenant à un utilisateur '
        'authentifié, puis la marque isSynced', () async {
      final entity = BookmarkEntity()
        ..remoteId = 'remote-1'
        ..userId = 'user-1'
        ..url = 'https://www.youtube.com/watch?v=abc'
        ..title = 'Vidéo en attente'
        ..source = VideoSource.youtube.name
        ..tags = const []
        ..createdAt = DateTime(2026)
        ..updatedAt = DateTime(2026)
        ..isSynced = false
        ..isDeletedLocally = false;
      await localDatasource.upsert(entity);

      await repository.syncPendingChanges();

      expect(remoteDatasource.upsertedRows, hasLength(1));
      expect(remoteDatasource.upsertedRows.single['id'], 'remote-1');
      final synced = await localDatasource.findByRemoteId('remote-1');
      expect(synced!.isSynced, isTrue);
    });

    test(
      'ignore les entités sans utilisateur authentifié (userId == null)',
      () async {
        final entity = BookmarkEntity()
          ..remoteId = 'remote-anon'
          ..url = 'https://www.youtube.com/watch?v=xyz'
          ..title = 'Anonyme'
          ..source = VideoSource.youtube.name
          ..tags = const []
          ..createdAt = DateTime(2026)
          ..updatedAt = DateTime(2026)
          ..isSynced = false
          ..isDeletedLocally = false;
        await localDatasource.upsert(entity);

        await repository.syncPendingChanges();

        expect(remoteDatasource.upsertedRows, isEmpty);
      },
    );

    test('traite les suppressions en attente avant tout autre envoi '
        '(voir SPEC.md section 13)', () async {
      final toDelete = BookmarkEntity()
        ..remoteId = 'remote-delete'
        ..userId = 'user-1'
        ..url = 'https://www.youtube.com/watch?v=del'
        ..title = 'À supprimer'
        ..source = VideoSource.youtube.name
        ..tags = const []
        ..createdAt = DateTime(2026)
        ..updatedAt = DateTime(2026)
        ..isSynced = true
        ..isDeletedLocally = true;
      final toUpload = BookmarkEntity()
        ..remoteId = 'remote-upload'
        ..userId = 'user-1'
        ..url = 'https://www.youtube.com/watch?v=up'
        ..title = 'À envoyer'
        ..source = VideoSource.youtube.name
        ..tags = const []
        ..createdAt = DateTime(2026)
        ..updatedAt = DateTime(2026)
        ..isSynced = false
        ..isDeletedLocally = false;
      await localDatasource.upsert(toDelete);
      await localDatasource.upsert(toUpload);

      await repository.syncPendingChanges();

      expect(remoteDatasource.callOrder, [
        'delete:remote-delete',
        'upsert:remote-upload',
      ]);
      expect(await localDatasource.findByRemoteId('remote-delete'), isNull);
    });
  });

  group('pullRemoteChanges', () {
    test(
      'rapatrie localement un bookmark créé sur un autre appareil',
      () async {
        remoteDatasource.remoteRows['remote-2'] = {
          'id': 'remote-2',
          'user_id': 'user-1',
          'url': 'https://www.tiktok.com/@user/video/2',
          'title': 'Créé ailleurs',
          'thumbnail_url': null,
          'source': VideoSource.tiktok.name,
          'tags': ['depuis-second-appareil'],
          'note': null,
          'is_partial': false,
          'created_at': DateTime(2026).toIso8601String(),
          'updated_at': DateTime(2026).toIso8601String(),
        };

        await repository.pullRemoteChanges();

        final bookmarks = await repository.getAllBookmarks();
        expect(bookmarks, hasLength(1));
        expect(bookmarks.single.id, 'remote-2');
        expect(bookmarks.single.tags, ['depuis-second-appareil']);
      },
    );

    test('une ligne distante plus récente écrase la copie locale '
        '(last-write-wins, voir SPEC.md section 13)', () async {
      final localEntity = BookmarkEntity()
        ..remoteId = 'remote-3'
        ..userId = 'user-1'
        ..url = 'https://www.youtube.com/watch?v=abc'
        ..title = 'Ancien titre'
        ..source = VideoSource.youtube.name
        ..tags = const []
        ..createdAt = DateTime(2026)
        ..updatedAt = DateTime(2026)
        ..isSynced = true
        ..isDeletedLocally = false;
      await localDatasource.upsert(localEntity);

      remoteDatasource.remoteRows['remote-3'] = {
        'id': 'remote-3',
        'user_id': 'user-1',
        'url': 'https://www.youtube.com/watch?v=abc',
        'title': 'Titre modifié ailleurs',
        'thumbnail_url': null,
        'source': VideoSource.youtube.name,
        'tags': <String>[],
        'note': null,
        'is_partial': false,
        'created_at': DateTime(2026).toIso8601String(),
        'updated_at': DateTime(2026, 1, 2).toIso8601String(),
      };

      await repository.pullRemoteChanges();

      final updated = await localDatasource.findByRemoteId('remote-3');
      expect(updated!.title, 'Titre modifié ailleurs');
    });

    test('supprime localement un bookmark déjà synchronisé mais supprimé sur '
        'un autre appareil', () async {
      final localEntity = BookmarkEntity()
        ..remoteId = 'remote-4'
        ..userId = 'user-1'
        ..url = 'https://www.youtube.com/watch?v=gone'
        ..title = 'Supprimé ailleurs'
        ..source = VideoSource.youtube.name
        ..tags = const []
        ..createdAt = DateTime(2026)
        ..updatedAt = DateTime(2026)
        ..isSynced = true
        ..isDeletedLocally = false;
      await localDatasource.upsert(localEntity);

      await repository.pullRemoteChanges();

      expect(await localDatasource.findByRemoteId('remote-4'), isNull);
    });
  });

  group('searchBookmarks', () {
    test(
      'trouve un bookmark par titre ou par tag, jamais via le réseau',
      () async {
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=abc',
          title: 'Recette de cuisine',
          source: VideoSource.youtube,
          tags: const ['cuisine'],
        );
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=xyz',
          title: 'Tutoriel Flutter',
          source: VideoSource.youtube,
          tags: const ['dev'],
        );

        final byTitle = await repository.searchBookmarks('recette');
        expect(byTitle.map((b) => b.title), ['Recette de cuisine']);

        final byTag = await repository.searchBookmarks('dev');
        expect(byTag.map((b) => b.title), ['Tutoriel Flutter']);

        final noMatch = await repository.searchBookmarks('inexistant');
        expect(noMatch, isEmpty);
      },
    );
  });

  group('deleteBookmarks (Tâche 26 — sélection multiple)', () {
    test('supprime tous les bookmarks dont l\'identifiant est fourni, en '
        'laissant les autres intacts', () async {
      final first = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=1',
        title: 'Un',
        source: VideoSource.youtube,
      );
      final second = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=2',
        title: 'Deux',
        source: VideoSource.youtube,
      );
      final third = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=3',
        title: 'Trois',
        source: VideoSource.youtube,
      );

      await repository.deleteBookmarks([first.id, second.id]);

      final remaining = await repository.getAllBookmarks();
      expect(remaining.map((b) => b.id), [third.id]);
    });

    test('ignore silencieusement un identifiant inconnu parmi le lot',
        () async {
      final created = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=1',
        title: 'Un',
        source: VideoSource.youtube,
      );

      await repository.deleteBookmarks([created.id, 'id-inexistant']);

      expect(await repository.getAllBookmarks(), isEmpty);
    });
  });

  group('addTagsToBookmarks (Tâche 26 — sélection multiple)', () {
    test('ajoute les tags en union avec les tags existants, sans doublon '
        'insensible à la casse, sans toucher aux bookmarks non '
        'sélectionnés', () async {
      final first = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=1',
        title: 'Un',
        source: VideoSource.youtube,
        tags: const ['Existant'],
      );
      final second = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=2',
        title: 'Deux',
        source: VideoSource.youtube,
      );
      final untouched = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=3',
        title: 'Trois',
        source: VideoSource.youtube,
        tags: const ['seul'],
      );

      await repository.addTagsToBookmarks(
        [first.id, second.id],
        ['existant', 'nouveau'],
      );

      final bookmarks = await repository.getAllBookmarks();
      final updatedFirst = bookmarks.firstWhere((b) => b.id == first.id);
      final updatedSecond = bookmarks.firstWhere((b) => b.id == second.id);
      final updatedThird = bookmarks.firstWhere((b) => b.id == untouched.id);

      expect(updatedFirst.tags, ['Existant', 'nouveau']);
      expect(updatedSecond.tags, ['existant', 'nouveau']);
      expect(updatedThird.tags, ['seul']);
    });

    test('force isHidden: true si l\'un des tags ajoutés est un tag masqué '
        '(Tâche 25)', () async {
      await tagLocalDatasource.upsert(
        TagEntity()
          ..name = 'secret'
          ..isHidden = true,
      );
      final created = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=1',
        title: 'Un',
        source: VideoSource.youtube,
      );

      await repository.addTagsToBookmarks([created.id], ['secret']);

      final bookmarks = await repository.getAllBookmarks();
      expect(bookmarks.single.isHidden, isTrue);
    });
  });

  group('authentification (Tâche 28)', () {
    test('createBookmark renseigne userId et synchronise immédiatement si une '
        'session active existe', () async {
      final authenticatedRepository = BookmarkRepository(
        isar: isar,
        localDatasource: localDatasource,
        remoteDatasource: remoteDatasource,
        tagLocalDatasource: tagLocalDatasource,
        getCurrentUserId: () => 'user-1',
      );

      final created = await authenticatedRepository.createBookmark(
        url: 'https://www.youtube.com/watch?v=auth',
        title: 'Créé authentifié',
        source: VideoSource.youtube,
      );

      expect(remoteDatasource.insertedRows, hasLength(1));
      final entity = await localDatasource.findByRemoteId(created.id);
      expect(entity!.userId, 'user-1');
      expect(entity.isSynced, isTrue);
    });

    test(
      'countLocalOnlyBookmarks ne compte que les bookmarks userId == null',
      () async {
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=sans-compte',
          title: 'Sans compte',
          source: VideoSource.youtube,
        );
        final authenticatedRepository = BookmarkRepository(
          isar: isar,
          localDatasource: localDatasource,
          remoteDatasource: remoteDatasource,
          tagLocalDatasource: tagLocalDatasource,
          getCurrentUserId: () => 'user-1',
        );
        await authenticatedRepository.createBookmark(
          url: 'https://www.youtube.com/watch?v=avec-compte',
          title: 'Avec compte',
          source: VideoSource.youtube,
        );

        expect(await repository.countLocalOnlyBookmarks(), 1);
      },
    );

    test('linkLocalBookmarksToUser associe userId et force isSynced à false '
        'sur les bookmarks non liés, sans toucher à ceux déjà liés', () async {
      final unlinked = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=non-lie',
        title: 'Non lié',
        source: VideoSource.youtube,
      );
      final authenticatedRepository = BookmarkRepository(
        isar: isar,
        localDatasource: localDatasource,
        remoteDatasource: remoteDatasource,
        tagLocalDatasource: tagLocalDatasource,
        getCurrentUserId: () => 'user-existant',
      );
      final alreadyLinked = await authenticatedRepository.createBookmark(
        url: 'https://www.youtube.com/watch?v=deja-lie',
        title: 'Déjà lié',
        source: VideoSource.youtube,
      );

      await repository.linkLocalBookmarksToUser('user-nouveau');

      final unlinkedEntity = await localDatasource.findByRemoteId(unlinked.id);
      expect(unlinkedEntity!.userId, 'user-nouveau');
      expect(unlinkedEntity.isSynced, isFalse);

      final alreadyLinkedEntity = await localDatasource.findByRemoteId(
        alreadyLinked.id,
      );
      expect(alreadyLinkedEntity!.userId, 'user-existant');

      expect(await repository.countLocalOnlyBookmarks(), 0);
    });

    test('linkLocalBookmarksToUser ne fait rien si aucun bookmark local '
        'n\'est en attente de rattachement', () async {
      await repository.linkLocalBookmarksToUser('user-1');
      expect(await repository.countLocalOnlyBookmarks(), 0);
    });
  });
}
