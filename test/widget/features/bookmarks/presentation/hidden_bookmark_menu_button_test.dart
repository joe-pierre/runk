import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/data/bookmark_local_datasource.dart';
import 'package:runk/features/bookmarks/data/bookmark_repository.dart';
import 'package:runk/features/bookmarks/data/bookmark_repository_provider.dart';
import 'package:runk/features/bookmarks/domain/video_bookmark.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_list_provider.dart';
import 'package:runk/features/bookmarks/presentation/hidden_bookmark_menu_button.dart';
import 'package:runk/features/tags/data/tag_local_datasource.dart';

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

  // Même raison que `bookmark_context_menu_test.dart` : les opérations Isar
  // réelles ont besoin d'un vrai tour d'event loop, jamais disponible sous
  // le simple `pump()` de `AutomatedTestWidgetsFlutterBinding`.
  Future<void> pumpFrames(WidgetTester tester, [int count = 20]) async {
    for (var i = 0; i < count; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      await tester.pump(const Duration(milliseconds: 25));
    }
  }

  // `bookmarkListProvider` est `@riverpod` (auto-dispose) : sans lecteur
  // actif, il serait recréé/disposé entre les deux `await` de
  // `HiddenBookmarkMenuButton._unhide`/`_delete`, faisant planter
  // `refresh()` (`UnmountedRefException`). En usage réel, l'écran englobant
  // (`MyEyesOnlyScreen`) le garde vivant via son propre `ref.watch` — ce
  // `Consumer` reproduit fidèlement ce contexte pour le widget testé isolément.
  Future<void> pumpButton(WidgetTester tester, VideoBookmark bookmark) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarkRepositoryProvider.overrideWith((ref) async => repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                ref.watch(bookmarkListProvider);
                return HiddenBookmarkMenuButton(bookmark: bookmark);
              },
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('"Ne plus masquer" démasque le bookmark via BookmarkRepository', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final created = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=abc',
        title: 'Ma vidéo secrète',
        source: VideoSource.youtube,
      );
      await repository.updateBookmark(created.copyWith(isHidden: true));

      await pumpButton(tester, created.copyWith(isHidden: true));
      await pumpFrames(tester);

      await tester.tap(
        find.byWidgetPredicate((widget) => widget is PopupMenuButton),
      );
      await pumpFrames(tester);
      await tester.tap(find.text('Ne plus masquer'));
      await pumpFrames(tester);

      List<VideoBookmark> updated;
      var attempts = 0;
      do {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        updated = await repository.getAllBookmarks();
        attempts++;
      } while (updated.single.isHidden && attempts < 100);
      expect(updated.single.isHidden, isFalse);
    });
  });

  testWidgets(
    '"Supprimer" ne retire rien tant que la confirmation n\'est pas donnée',
    (tester) async {
      await tester.runAsync(() async {
        final created = await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=abc',
          title: 'Ma vidéo secrète',
          source: VideoSource.youtube,
        );
        await repository.updateBookmark(created.copyWith(isHidden: true));

        await pumpButton(tester, created.copyWith(isHidden: true));
        await pumpFrames(tester);

        await tester.tap(
          find.byWidgetPredicate((widget) => widget is PopupMenuButton),
        );
        await pumpFrames(tester);
        await tester.tap(find.text('Supprimer'));
        await pumpFrames(tester);

        expect(find.text('Cette action est définitive.'), findsOneWidget);
        await tester.tap(find.text('Annuler'));
        await pumpFrames(tester);

        expect(await repository.getAllBookmarks(), hasLength(1));
      });
    },
  );

  testWidgets('"Supprimer" confirmé supprime définitivement le bookmark', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final created = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=abc',
        title: 'Ma vidéo secrète',
        source: VideoSource.youtube,
      );
      await repository.updateBookmark(created.copyWith(isHidden: true));

      await pumpButton(tester, created.copyWith(isHidden: true));
      await pumpFrames(tester);

      await tester.tap(
        find.byWidgetPredicate((widget) => widget is PopupMenuButton),
      );
      await pumpFrames(tester);
      await tester.tap(find.text('Supprimer'));
      await pumpFrames(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
      await pumpFrames(tester);

      List<VideoBookmark> remaining;
      var attempts = 0;
      do {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        remaining = await repository.getAllBookmarks();
        attempts++;
      } while (remaining.isNotEmpty && attempts < 100);
      expect(remaining, isEmpty);
    });
  });
}
