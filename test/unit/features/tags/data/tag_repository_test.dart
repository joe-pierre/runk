import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/data/bookmark_local_datasource.dart';
import 'package:runk/features/tags/data/tag_local_datasource.dart';
import 'package:runk/features/tags/data/tag_remote_datasource.dart';
import 'package:runk/features/tags/data/tag_repository.dart';

/// Fake du datasource distant : n'effectue jamais d'appel Supabase réel —
/// même patron que `FakeBookmarkRemoteDatasource`
/// (`bookmark_repository_test.dart`, voir DECISIONS.md, entrée « Mock HTTP
/// des providers »/« Fake du datasource distant »).
class FakeTagRemoteDatasource implements TagRemoteDatasource {
  final List<Map<String, dynamic>> upsertedRows = [];
  final List<String> deletedIds = [];

  /// Ordre chronologique de tous les appels (`upsert:<id>`, `delete:<id>`) —
  /// même rôle que `FakeBookmarkRemoteDatasource.callOrder`, utilisé pour
  /// vérifier que les suppressions en attente sont traitées avant tout autre
  /// envoi (voir SPEC.md section 13).
  final List<String> callOrder = [];

  /// État actuel de la table distante simulée, indexé par `id` — permet de
  /// représenter des lignes déjà présentes côté serveur (ex: créées par un
  /// autre appareil) sans passer par `upsert` de ce fake, pour tester
  /// `TagRepository.pullRemoteChanges`.
  final Map<String, Map<String, dynamic>> remoteRows = {};

  /// Si vrai, chaque appel lève une exception — simule une absence de
  /// connexion réseau.
  bool shouldFail = false;

  @override
  Future<Map<String, dynamic>> insert(Map<String, dynamic> data) async {
    if (shouldFail) throw Exception('Réseau indisponible (simulation)');
    remoteRows[data['id'] as String] = data;
    return data;
  }

  @override
  Future<void> upsert(Map<String, dynamic> data) async {
    if (shouldFail) throw Exception('Réseau indisponible (simulation)');
    upsertedRows.add(data);
    remoteRows[data['id'] as String] = data;
    callOrder.add('upsert:${data['id']}');
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
    remoteRows[id] = data;
    return data;
  }

  @override
  Future<void> delete(String id) async {
    if (shouldFail) throw Exception('Réseau indisponible (simulation)');
    deletedIds.add(id);
    remoteRows.remove(id);
    callOrder.add('delete:$id');
  }
}

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
  late FakeTagRemoteDatasource remoteDatasource;
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
    remoteDatasource = FakeTagRemoteDatasource();
    repository = TagRepository(
      isar: isar,
      tagLocalDatasource: tagLocalDatasource,
      bookmarkLocalDatasource: bookmarkLocalDatasource,
      remoteDatasource: remoteDatasource,
      getCurrentUserId: () => null,
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

    test('retire le tag (cascade) de tous les bookmarks concernés et supprime '
        'le TagEntity', () async {
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
    });

    test('supprimer un tag purement dérivé (sans TagEntity) le retire quand '
        'même de tous les bookmarks', () async {
      await _seedBookmark(
        bookmarkLocalDatasource,
        remoteId: 'b1',
        tags: const ['brouillon'],
      );

      await repository.deleteTag('brouillon');

      final b1 = await bookmarkLocalDatasource.findByRemoteId('b1');
      expect(b1!.tags, isEmpty);
    });
  });

  group('hideTag (Tâche 25 — My Eyes Only, tags)', () {
    test(
      'masque un tag purement dérivé (crée son TagEntity) et tous les '
      'bookmarks qui le portent, comparaison insensible à la casse',
      () async {
        await _seedBookmark(
          bookmarkLocalDatasource,
          remoteId: 'b1',
          tags: const ['Secret', 'autre'],
        );
        await _seedBookmark(
          bookmarkLocalDatasource,
          remoteId: 'b2',
          tags: const ['autre'],
        );
        expect(await tagLocalDatasource.findByName('secret'), isNull);

        await repository.hideTag('secret');

        final tagEntity = await tagLocalDatasource.findByName('secret');
        expect(tagEntity, isNotNull);
        expect(tagEntity!.isHidden, isTrue);
        final b1 = await bookmarkLocalDatasource.findByRemoteId('b1');
        final b2 = await bookmarkLocalDatasource.findByRemoteId('b2');
        expect(b1!.isHidden, isTrue);
        expect(b2!.isHidden, isFalse);
      },
    );

    test(
      'masque un tag déjà géré (TagEntity existant) sans le dupliquer',
      () async {
        await repository.createTag('voyage');
        await _seedBookmark(
          bookmarkLocalDatasource,
          remoteId: 'b1',
          tags: const ['voyage'],
        );

        await repository.hideTag('voyage');

        expect(await repository.getHiddenTagNames(), ['voyage']);
        final b1 = await bookmarkLocalDatasource.findByRemoteId('b1');
        expect(b1!.isHidden, isTrue);
      },
    );

    test('getManagedTagNames exclut les tags masqués, getHiddenTagNames ne '
        'retourne qu\'eux', () async {
      await repository.createTag('a');
      await repository.createTag('b');

      await repository.hideTag('b');

      expect(await repository.getManagedTagNames(), ['a']);
      expect(await repository.getHiddenTagNames(), ['b']);
    });
  });

  group('unhideTag (Tâche 25 — My Eyes Only, tags)', () {
    test(
      'démasque le TagEntity et tous les bookmarks qui le portent',
      () async {
        await _seedBookmark(
          bookmarkLocalDatasource,
          remoteId: 'b1',
          tags: const ['secret'],
        );
        await repository.hideTag('secret');

        await repository.unhideTag('secret');

        final tagEntity = await tagLocalDatasource.findByName('secret');
        expect(tagEntity!.isHidden, isFalse);
        expect(await repository.getManagedTagNames(), ['secret']);
        final b1 = await bookmarkLocalDatasource.findByRemoteId('b1');
        expect(b1!.isHidden, isFalse);
      },
    );

    test(
      'ne démasque pas un bookmark qui porte encore un autre tag masqué',
      () async {
        await _seedBookmark(
          bookmarkLocalDatasource,
          remoteId: 'b1',
          tags: const ['secret1', 'secret2'],
        );
        await repository.hideTag('secret1');
        await repository.hideTag('secret2');

        await repository.unhideTag('secret1');
        var b1 = await bookmarkLocalDatasource.findByRemoteId('b1');
        expect(
          b1!.isHidden,
          isTrue,
          reason: 'secret2 masque encore ce bookmark',
        );

        await repository.unhideTag('secret2');
        b1 = await bookmarkLocalDatasource.findByRemoteId('b1');
        expect(b1!.isHidden, isFalse);
      },
    );
  });

  group('synchronisation (extension tags remote sync, voir DECISIONS.md)', () {
    test(
      'createTag renseigne remoteId/userId et synchronise immédiatement '
      'si une session active existe',
      () async {
        final authenticatedRepository = TagRepository(
          isar: isar,
          tagLocalDatasource: tagLocalDatasource,
          bookmarkLocalDatasource: bookmarkLocalDatasource,
          remoteDatasource: remoteDatasource,
          getCurrentUserId: () => 'user-1',
        );

        await authenticatedRepository.createTag('cuisine');

        expect(remoteDatasource.upsertedRows, hasLength(1));
        final entity = await tagLocalDatasource.findByName('cuisine');
        expect(entity!.userId, 'user-1');
        expect(entity.remoteId, isNotNull);
        expect(entity.isSynced, isTrue);
      },
    );

    test(
      'sans utilisateur authentifié, createTag ne tente aucune '
      'synchronisation distante',
      () async {
        await repository.createTag('cuisine');

        expect(remoteDatasource.upsertedRows, isEmpty);
        final entity = await tagLocalDatasource.findByName('cuisine');
        expect(entity!.isSynced, isFalse);
      },
    );

    group('syncPendingChanges', () {
      test(
        'pousse via upsert une entité en attente appartenant à un '
        'utilisateur authentifié, puis la marque isSynced',
        () async {
          final entity = TagEntity()
            ..name = 'voyage'
            ..remoteId = 'remote-1'
            ..userId = 'user-1'
            ..createdAt = DateTime(2026)
            ..updatedAt = DateTime(2026)
            ..isSynced = false
            ..isDeletedLocally = false;
          await tagLocalDatasource.upsert(entity);

          await repository.syncPendingChanges();

          expect(remoteDatasource.upsertedRows, hasLength(1));
          expect(remoteDatasource.upsertedRows.single['id'], 'remote-1');
          final synced = await tagLocalDatasource.findByName('voyage');
          expect(synced!.isSynced, isTrue);
        },
      );

      test(
        'ignore les entités sans utilisateur authentifié (userId == null)',
        () async {
          final entity = TagEntity()
            ..name = 'anonyme'
            ..createdAt = DateTime(2026)
            ..updatedAt = DateTime(2026)
            ..isSynced = false
            ..isDeletedLocally = false;
          await tagLocalDatasource.upsert(entity);

          await repository.syncPendingChanges();

          expect(remoteDatasource.upsertedRows, isEmpty);
        },
      );

      test(
        'génère un remoteId pour un TagEntity historique qui n\'en a jamais '
        'eu (créé par une version antérieure de l\'app, voir doc de classe '
        'de TagEntity)',
        () async {
          final entity = TagEntity()
            ..name = 'historique'
            ..userId = 'user-1'
            ..createdAt = DateTime(2026)
            ..updatedAt = DateTime(2026)
            ..isSynced = false
            ..isDeletedLocally = false;
          await tagLocalDatasource.upsert(entity);

          await repository.syncPendingChanges();

          final synced = await tagLocalDatasource.findByName('historique');
          expect(synced!.remoteId, isNotNull);
          expect(synced.isSynced, isTrue);
          expect(remoteDatasource.upsertedRows.single['id'], synced.remoteId);
        },
      );

      test(
        'traite les suppressions en attente avant tout autre envoi '
        '(voir SPEC.md section 13)',
        () async {
          final toDelete = TagEntity()
            ..name = 'à-supprimer'
            ..remoteId = 'remote-delete'
            ..userId = 'user-1'
            ..createdAt = DateTime(2026)
            ..updatedAt = DateTime(2026)
            ..isSynced = true
            ..isDeletedLocally = true;
          final toUpload = TagEntity()
            ..name = 'à-envoyer'
            ..remoteId = 'remote-upload'
            ..userId = 'user-1'
            ..createdAt = DateTime(2026)
            ..updatedAt = DateTime(2026)
            ..isSynced = false
            ..isDeletedLocally = false;
          await tagLocalDatasource.upsert(toDelete);
          await tagLocalDatasource.upsert(toUpload);

          await repository.syncPendingChanges();

          expect(remoteDatasource.callOrder, [
            'delete:remote-delete',
            'upsert:remote-upload',
          ]);
          expect(await tagLocalDatasource.findByName('à-supprimer'), isNull);
        },
      );
    });

    group('pullRemoteChanges', () {
      test('rapatrie localement un tag créé sur un autre appareil', () async {
        remoteDatasource.remoteRows['remote-2'] = {
          'id': 'remote-2',
          'user_id': 'user-1',
          'name': 'depuis-second-appareil',
          'is_hidden': false,
          'created_at': DateTime(2026).toIso8601String(),
          'updated_at': DateTime(2026).toIso8601String(),
        };

        await repository.pullRemoteChanges();

        expect(
          await repository.getManagedTagNames(),
          contains('depuis-second-appareil'),
        );
      });

      test(
        'une ligne distante plus récente écrase la copie locale '
        '(last-write-wins, voir SPEC.md section 13)',
        () async {
          final localEntity = TagEntity()
            ..name = 'ancien-nom'
            ..remoteId = 'remote-3'
            ..userId = 'user-1'
            ..createdAt = DateTime(2026)
            ..updatedAt = DateTime(2026)
            ..isSynced = true
            ..isDeletedLocally = false;
          await tagLocalDatasource.upsert(localEntity);

          remoteDatasource.remoteRows['remote-3'] = {
            'id': 'remote-3',
            'user_id': 'user-1',
            'name': 'nom-modifié-ailleurs',
            'is_hidden': false,
            'created_at': DateTime(2026).toIso8601String(),
            'updated_at': DateTime(2026, 1, 2).toIso8601String(),
          };

          await repository.pullRemoteChanges();

          expect(
            await repository.getManagedTagNames(),
            contains('nom-modifié-ailleurs'),
          );
          expect(
            await repository.getManagedTagNames(),
            isNot(contains('ancien-nom')),
          );
        },
      );

      test(
        'une ligne distante plus ancienne que la copie locale ne l\'écrase '
        'pas',
        () async {
          final localEntity = TagEntity()
            ..name = 'nom-local-plus-récent'
            ..remoteId = 'remote-3bis'
            ..userId = 'user-1'
            ..createdAt = DateTime(2026)
            ..updatedAt = DateTime(2026, 1, 5)
            ..isSynced = true
            ..isDeletedLocally = false;
          await tagLocalDatasource.upsert(localEntity);

          remoteDatasource.remoteRows['remote-3bis'] = {
            'id': 'remote-3bis',
            'user_id': 'user-1',
            'name': 'nom-distant-plus-ancien',
            'is_hidden': false,
            'created_at': DateTime(2026).toIso8601String(),
            'updated_at': DateTime(2026, 1, 1).toIso8601String(),
          };

          await repository.pullRemoteChanges();

          expect(
            await repository.getManagedTagNames(),
            contains('nom-local-plus-récent'),
          );
        },
      );

      test(
        'supprime localement un tag déjà synchronisé mais supprimé sur un '
        'autre appareil (absent des lignes distantes rapatriées)',
        () async {
          final localEntity = TagEntity()
            ..name = 'supprimé-ailleurs'
            ..remoteId = 'remote-4'
            ..userId = 'user-1'
            ..createdAt = DateTime(2026)
            ..updatedAt = DateTime(2026)
            ..isSynced = true
            ..isDeletedLocally = false;
          await tagLocalDatasource.upsert(localEntity);

          await repository.pullRemoteChanges();

          expect(await tagLocalDatasource.findByRemoteId('remote-4'), isNull);
        },
      );

      test(
        'un tag local supprimé (isDeletedLocally) pendant que le distant '
        'existe encore n\'est pas ressuscité par le pull',
        () async {
          final localEntity = TagEntity()
            ..name = 'en-cours-de-suppression'
            ..remoteId = 'remote-5'
            ..userId = 'user-1'
            ..createdAt = DateTime(2026)
            ..updatedAt = DateTime(2026)
            ..isSynced = true
            ..isDeletedLocally = true;
          await tagLocalDatasource.upsert(localEntity);
          remoteDatasource.remoteRows['remote-5'] = {
            'id': 'remote-5',
            'user_id': 'user-1',
            'name': 'en-cours-de-suppression',
            'is_hidden': false,
            'created_at': DateTime(2026).toIso8601String(),
            'updated_at': DateTime(2026, 1, 2).toIso8601String(),
          };

          await repository.pullRemoteChanges();

          final entity = await tagLocalDatasource.findByRemoteId('remote-5');
          expect(entity!.isDeletedLocally, isTrue);
        },
      );
    });

    group('rattachement rétroactif (Tâche 28, extension tags)', () {
      test(
        'countLocalOnlyTags ne compte que les tags userId == null',
        () async {
          await repository.createTag('sans-compte');
          final authenticatedRepository = TagRepository(
            isar: isar,
            tagLocalDatasource: tagLocalDatasource,
            bookmarkLocalDatasource: bookmarkLocalDatasource,
            remoteDatasource: remoteDatasource,
            getCurrentUserId: () => 'user-1',
          );
          await authenticatedRepository.createTag('avec-compte');

          expect(await repository.countLocalOnlyTags(), 1);
        },
      );

      test(
        'linkLocalTagsToUser associe userId et force isSynced à false sur '
        'les tags non liés, sans toucher à ceux déjà liés',
        () async {
          await repository.createTag('non-lié');
          final authenticatedRepository = TagRepository(
            isar: isar,
            tagLocalDatasource: tagLocalDatasource,
            bookmarkLocalDatasource: bookmarkLocalDatasource,
            remoteDatasource: remoteDatasource,
            getCurrentUserId: () => 'user-existant',
          );
          await authenticatedRepository.createTag('déjà-lié');

          await repository.linkLocalTagsToUser('user-nouveau');

          final unlinkedEntity = await tagLocalDatasource.findByName(
            'non-lié',
          );
          expect(unlinkedEntity!.userId, 'user-nouveau');
          expect(unlinkedEntity.isSynced, isFalse);

          final alreadyLinkedEntity = await tagLocalDatasource.findByName(
            'déjà-lié',
          );
          expect(alreadyLinkedEntity!.userId, 'user-existant');

          expect(await repository.countLocalOnlyTags(), 0);
        },
      );
    });
  });
}
