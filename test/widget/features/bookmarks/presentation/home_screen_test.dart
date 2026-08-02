import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/core/services/deep_link_service.dart';
import 'package:runk/core/services/deep_link_service_provider.dart';
import 'package:runk/features/bookmarks/data/bookmark_local_datasource.dart';
import 'package:runk/features/bookmarks/data/bookmark_repository.dart';
import 'package:runk/features/bookmarks/data/bookmark_repository_provider.dart';
import 'package:runk/features/bookmarks/domain/video_bookmark.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_list_provider.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_tag_filter_provider.dart';
import 'package:runk/features/bookmarks/presentation/home_screen.dart';
import 'package:runk/features/bookmarks/presentation/manual_add_dialog.dart';
import 'package:runk/features/tags/data/tag_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../unit/features/bookmarks/data/bookmark_repository_test.dart'
    show FakeBookmarkRemoteDatasource;

/// Notifier de test qui court-circuite `BookmarkRepository` (donc Isar et
/// Supabase) : retourne directement une liste fixe, comme
/// `FakeBookmarkRemoteDatasource` le fait déjà pour `BookmarkRepository`
/// (Tâche 5) — voir CONVENTIONS.md section Tests.
class _FakeBookmarkList extends BookmarkList {
  _FakeBookmarkList(this._bookmarks);

  final List<VideoBookmark> _bookmarks;

  @override
  Future<List<VideoBookmark>> build() async => _bookmarks;
}

void main() {
  testWidgets('affiche un message quand aucun bookmark', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarkListProvider.overrideWith(() => _FakeBookmarkList(const [])),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Partagez une vidéo vers Runk pour commencer.'),
      findsOneWidget,
    );
  });

  testWidgets('affiche les bookmarks fournis par le provider', (tester) async {
    final bookmark = VideoBookmark(
      id: '1',
      url: 'https://youtube.com/watch?v=abc',
      title: 'Ma vidéo',
      source: VideoSource.youtube,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      tags: const ['drole'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarkListProvider.overrideWith(
            () => _FakeBookmarkList([bookmark]),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ma vidéo'), findsOneWidget);
    expect(find.text('drole'), findsOneWidget);
  });

  testWidgets(
    'un tap sur une carte délègue la réouverture à DeepLinkService',
    (tester) async {
      final bookmark = VideoBookmark(
        id: '1',
        url: 'https://www.instagram.com/p/abc123/',
        title: 'Un reel',
        source: VideoSource.instagram,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      final launchedUris = <Uri>[];
      final fakeDeepLinkService = DeepLinkService(
        canLaunchUrl: (uri) async => true,
        launchUrl: (uri, {mode = LaunchMode.platformDefault}) async {
          launchedUris.add(uri);
          return true;
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkListProvider.overrideWith(
              () => _FakeBookmarkList([bookmark]),
            ),
            deepLinkServiceProvider.overrideWithValue(fakeDeepLinkService),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Un reel'));
      await tester.pumpAndSettle();

      expect(launchedUris, [
        Uri.parse('instagram://www.instagram.com/p/abc123/'),
      ]);
    },
  );

  testWidgets(
    'filtre les bookmarks par tag quand bookmarkTagFilterProvider est actif, '
    'et le retire au tap sur le chip',
    (tester) async {
      final withTag = VideoBookmark(
        id: '1',
        url: 'https://youtube.com/watch?v=abc',
        title: 'Vidéo cuisine',
        source: VideoSource.youtube,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        tags: const ['cuisine'],
      );
      final withoutTag = VideoBookmark(
        id: '2',
        url: 'https://youtube.com/watch?v=xyz',
        title: 'Vidéo dev',
        source: VideoSource.youtube,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        tags: const ['dev'],
      );
      final container = ProviderContainer(
        overrides: [
          bookmarkListProvider.overrideWith(
            () => _FakeBookmarkList([withTag, withoutTag]),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(bookmarkTagFilterProvider.notifier).select('cuisine');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vidéo cuisine'), findsOneWidget);
      expect(find.text('Vidéo dev'), findsNothing);
      expect(find.text('Filtré par : cuisine'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.cancel));
      await tester.pumpAndSettle();

      expect(container.read(bookmarkTagFilterProvider), isNull);
      expect(find.text('Vidéo dev'), findsOneWidget);
    },
  );

  testWidgets(
    'un bookmark isHidden: true n\'apparaît pas dans la liste (Tâche 22)',
    (tester) async {
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
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vidéo visible'), findsOneWidget);
      expect(find.text('Vidéo masquée'), findsNothing);
    },
  );

  testWidgets(
    'un appui long sur "Runk" sans code défini propose d\'en créer un '
    '(Tâche 22)',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkListProvider.overrideWith(() => _FakeBookmarkList(const [])),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Runk'));
      await tester.pumpAndSettle();

      expect(find.text('Définir un code'), findsOneWidget);
    },
  );

  testWidgets(
    'un tap sur le bouton flottant "+" ouvre ManualAddDialog',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkListProvider.overrideWith(() => _FakeBookmarkList(const [])),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(ManualAddDialog), findsOneWidget);
    },
  );

  group('Recherche intégrée (Tâche 30, voir DECISIONS.md)', () {
    // Reprend le comportement de l'ancien `SearchScreen`, désormais absorbé
    // par HomeScreen : nécessite un Isar réel (pas `_FakeBookmarkList`) pour
    // exercer `BookmarkRepository.searchBookmarks` via `bookmarkSearchProvider`
    // — même dispositif que `search_screen_test.dart` avant sa suppression.
    late Directory tempDirectory;
    late Isar isar;
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
      repository = BookmarkRepository(
        isar: isar,
        localDatasource: BookmarkLocalDatasource(isar),
        remoteDatasource: FakeBookmarkRemoteDatasource(),
        tagLocalDatasource: TagLocalDatasource(isar),
        getCurrentUserId: () => null,
      );
    });

    tearDown(() async {
      await isar.close();
      tempDirectory.deleteSync(recursive: true);
    });

    // isar_community résout ses opérations natives via un port alimenté par
    // un thread réel, jamais par un `Timer` : le `Future` correspondant reste
    // lié à la zone dans laquelle il a été *déclenché*, pas à celle depuis
    // laquelle on l'attend ensuite — `pumpWidget`/toute interaction qui
    // déclenche un accès Isar réel (donc `bookmarkListProvider`/
    // `bookmarkSearchProvider`) doit donc se trouver **à l'intérieur** du
    // même bloc `runAsync`, jamais seulement le `await` final (vérifié
    // empiriquement : sinon le port natif ne relaie jamais sa réponse,
    // blocage indéfini). `pumpAndSettle()` ne fonctionne pas non plus à
    // l'intérieur de `runAsync` (sa boucle s'appuie sur l'horloge fake,
    // court-circuitée) — voir DECISIONS.md, entrée Tâche 10, et le même
    // commentaire dans `bookmark_context_menu_test.dart`.
    Future<void> pumpFrames(WidgetTester tester, [int count = 20]) async {
      for (var i = 0; i < count; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        await tester.pump(const Duration(milliseconds: 25));
      }
    }

    testWidgets(
      'taper dans la barre de recherche bascule sur bookmarkSearchProvider, '
      'masque le chip de filtre par tag, et revient à la liste normale une '
      'fois la recherche effacée',
      (tester) async {
        await tester.runAsync(() async {
          await repository.createBookmark(
            url: 'https://www.youtube.com/watch?v=abc',
            title: 'Recette de cuisine',
            source: VideoSource.youtube,
            tags: const ['cuisine'],
          );
          await repository.createBookmark(
            url: 'https://www.youtube.com/watch?v=xyz',
            title: 'Vidéo dev',
            source: VideoSource.youtube,
            tags: const ['dev'],
          );

          final container = ProviderContainer(
            overrides: [
              bookmarkRepositoryProvider.overrideWith(
                (ref) async => repository,
              ),
            ],
          );
          addTearDown(container.dispose);
          container.read(bookmarkTagFilterProvider.notifier).select('dev');

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(home: HomeScreen()),
            ),
          );
          await pumpFrames(tester);

          // Requête vide : comportement inchangé, filtre par tag actif.
          expect(find.text('Vidéo dev'), findsOneWidget);
          expect(find.text('Recette de cuisine'), findsNothing);
          expect(find.text('Filtré par : dev'), findsOneWidget);

          await tester.enterText(find.byType(TextField), 'recette');
          await pumpFrames(tester);

          // Requête non vide : bascule sur bookmarkSearchProvider, le chip
          // de filtre par tag disparaît (les deux filtres ne se combinent
          // pas).
          expect(find.text('Recette de cuisine'), findsOneWidget);
          expect(find.text('Vidéo dev'), findsNothing);
          expect(find.text('Filtré par : dev'), findsNothing);

          await tester.enterText(find.byType(TextField), '');
          await pumpFrames(tester);

          // Recherche effacée : retour à la liste normale filtrée par tag.
          expect(find.text('Vidéo dev'), findsOneWidget);
          expect(find.text('Recette de cuisine'), findsNothing);
          expect(find.text('Filtré par : dev'), findsOneWidget);
        });
      },
    );

    testWidgets(
      'une recherche sans résultat affiche le message dédié',
      (tester) async {
        await tester.runAsync(() async {
          await repository.createBookmark(
            url: 'https://www.youtube.com/watch?v=abc',
            title: 'Recette de cuisine',
            source: VideoSource.youtube,
          );

          final container = ProviderContainer(
            overrides: [
              bookmarkRepositoryProvider.overrideWith(
                (ref) async => repository,
              ),
            ],
          );
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(home: HomeScreen()),
            ),
          );
          await pumpFrames(tester);

          await tester.enterText(find.byType(TextField), 'introuvable');
          await pumpFrames(tester);

          expect(
            find.text('Aucun résultat pour "introuvable".'),
            findsOneWidget,
          );
        });
      },
    );

    testWidgets(
      'un tap sur un résultat de recherche délègue la réouverture à '
      'DeepLinkService',
      (tester) async {
        await tester.runAsync(() async {
          await repository.createBookmark(
            url: 'https://www.instagram.com/p/abc123/',
            title: 'Un reel',
            source: VideoSource.instagram,
          );
          final launchedUris = <Uri>[];
          final fakeDeepLinkService = DeepLinkService(
            canLaunchUrl: (uri) async => true,
            launchUrl: (uri, {mode = LaunchMode.platformDefault}) async {
              launchedUris.add(uri);
              return true;
            },
          );

          final container = ProviderContainer(
            overrides: [
              bookmarkRepositoryProvider.overrideWith(
                (ref) async => repository,
              ),
              deepLinkServiceProvider.overrideWithValue(fakeDeepLinkService),
            ],
          );
          addTearDown(container.dispose);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(home: HomeScreen()),
            ),
          );
          await pumpFrames(tester);

          await tester.enterText(find.byType(TextField), 'reel');
          await pumpFrames(tester);

          await tester.tap(find.text('Un reel'));
          await pumpFrames(tester);

          expect(launchedUris, [
            Uri.parse('instagram://www.instagram.com/p/abc123/'),
          ]);
        });
      },
    );
  });
}
