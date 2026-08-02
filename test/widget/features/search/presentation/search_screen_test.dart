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
import 'package:runk/features/bookmarks/presentation/bookmark_search_provider.dart';
import 'package:runk/features/search/presentation/search_screen.dart';
import 'package:runk/features/tags/data/tag_local_datasource.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../unit/features/bookmarks/data/bookmark_repository_test.dart'
    show FakeBookmarkRemoteDatasource;

void main() {
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
      localDatasource: BookmarkLocalDatasource(isar),
      remoteDatasource: FakeBookmarkRemoteDatasource(),
      tagLocalDatasource: TagLocalDatasource(isar),
    );
  });

  tearDown(() async {
    await isar.close();
    tempDirectory.deleteSync(recursive: true);
  });

  testWidgets(
    'n\'affiche aucun résultat tant qu\'aucune recherche n\'est saisie',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkRepositoryProvider.overrideWith((ref) async => repository),
          ],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Tapez un titre ou un tag pour rechercher.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'la saisie déclenche une recherche locale et affiche les résultats',
    (tester) async {
      // isar_community résout ses opérations async (Isar.open, writeTxn,
      // find...) via un port natif alimenté par un thread en arrière-plan
      // (isar_instance_create_async / isar_txn_begin), jamais par un Timer.
      // AutomatedTestWidgetsFlutterBinding (utilisé par testWidgets) ne
      // fait tourner que l'horloge fake et ne relaie jamais ces messages
      // natifs : sans tester.runAsync, l'await correspondant ne se termine
      // jamais (voir DECISIONS.md, entrée Tâche 10).
      await tester.runAsync(() async {
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=abc',
          title: 'Recette de cuisine',
          source: VideoSource.youtube,
          tags: const ['cuisine'],
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkRepositoryProvider.overrideWith((ref) async => repository),
          ],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // bookmarkSearchProvider('recette') interroge aussi Isar en réel :
      // même raison, on attend explicitement son Future (via le
      // ProviderContainer) à l'intérieur de runAsync, puis un seul pump()
      // hors runAsync suffit à reconstruire l'écran avec le résultat déjà
      // résolu. pumpAndSettle() est à éviter ici : le CircularProgressIndicator
      // affiché pendant l'état `loading` reprogramme une frame en continu et
      // ne « settle » jamais tant que ce Future n'est pas déjà résolu.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SearchScreen)),
      );
      await tester.runAsync(() async {
        await tester.enterText(find.byType(TextField), 'recette');
        await tester.pump();
        await container.read(bookmarkSearchProvider('recette').future);
      });
      await tester.pump();

      expect(find.text('Recette de cuisine'), findsOneWidget);
    },
  );

  testWidgets(
    'un tap sur un résultat délègue la réouverture à DeepLinkService',
    (tester) async {
      // Voir commentaire du test précédent : écriture Isar réelle, doit
      // rester dans runAsync sous testWidgets.
      await tester.runAsync(() async {
        await repository.createBookmark(
          url: 'https://www.instagram.com/p/abc123/',
          title: 'Un reel',
          source: VideoSource.instagram,
        );
      });
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
            bookmarkRepositoryProvider.overrideWith((ref) async => repository),
            deepLinkServiceProvider.overrideWithValue(fakeDeepLinkService),
          ],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Même raison que le test précédent : la recherche Isar réelle doit
      // être attendue dans runAsync avant de reconstruire l'écran.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SearchScreen)),
      );
      await tester.runAsync(() async {
        await tester.enterText(find.byType(TextField), 'reel');
        await tester.pump();
        await container.read(bookmarkSearchProvider('reel').future);
      });
      await tester.pump();

      // Le tap déclenche uniquement le fakeDeepLinkService (aucun accès
      // Isar) : pumpAndSettle() reste approprié ici.
      await tester.tap(find.text('Un reel'));
      await tester.pumpAndSettle();

      expect(launchedUris, [
        Uri.parse('instagram://www.instagram.com/p/abc123/'),
      ]);
    },
  );
}
