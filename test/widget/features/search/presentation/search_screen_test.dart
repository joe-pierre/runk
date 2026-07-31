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
import 'package:runk/features/search/presentation/search_screen.dart';
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
      [BookmarkEntitySchema],
      directory: tempDirectory.path,
      inspector: false,
    );
    repository = BookmarkRepository(
      localDatasource: BookmarkLocalDatasource(isar),
      remoteDatasource: FakeBookmarkRemoteDatasource(),
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
      await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=abc',
        title: 'Recette de cuisine',
        source: VideoSource.youtube,
        tags: const ['cuisine'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkRepositoryProvider.overrideWith((ref) async => repository),
          ],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'recette');
      await tester.pumpAndSettle();

      expect(find.text('Recette de cuisine'), findsOneWidget);
    },
  );

  testWidgets(
    'un tap sur un résultat délègue la réouverture à DeepLinkService',
    (tester) async {
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

      await tester.enterText(find.byType(TextField), 'reel');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Un reel'));
      await tester.pumpAndSettle();

      expect(launchedUris, [
        Uri.parse('instagram://www.instagram.com/p/abc123/'),
      ]);
    },
  );
}
