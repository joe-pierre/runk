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
import 'package:runk/features/bookmarks/presentation/add_to_my_eyes_only_screen.dart';
import 'package:runk/features/tags/data/tag_local_datasource.dart';
import 'package:runk/features/tags/data/tag_repository.dart';
import 'package:runk/features/tags/data/tag_repository_provider.dart';

import '../../../../unit/features/bookmarks/data/bookmark_repository_test.dart'
    show FakeBookmarkRemoteDatasource;

void main() {
  late Directory tempDirectory;
  late Isar isar;
  late BookmarkRepository repository;
  late TagRepository tagRepository;

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
    final bookmarkLocalDatasource = BookmarkLocalDatasource(isar);
    final tagLocalDatasource = TagLocalDatasource(isar);
    repository = BookmarkRepository(
      isar: isar,
      localDatasource: bookmarkLocalDatasource,
      remoteDatasource: FakeBookmarkRemoteDatasource(),
      tagLocalDatasource: tagLocalDatasource,
    );
    tagRepository = TagRepository(
      isar: isar,
      tagLocalDatasource: tagLocalDatasource,
      bookmarkLocalDatasource: bookmarkLocalDatasource,
    );
  });

  tearDown(() async {
    await isar.close();
    tempDirectory.deleteSync(recursive: true);
  });

  // Même raison que les autres tests s'appuyant sur un Isar réel (voir
  // `bookmark_context_menu_test.dart`) : un vrai tour d'event loop est
  // nécessaire pour que les opérations natives isar_community aboutissent
  // sous `AutomatedTestWidgetsFlutterBinding`.
  Future<void> pumpFrames(WidgetTester tester, [int count = 20]) async {
    for (var i = 0; i < count; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      await tester.pump(const Duration(milliseconds: 25));
    }
  }

  /// Pousse `AddToMyEyesOnlyScreen` par-dessus un écran racine trivial —
  /// reproduit le vrai contexte de navigation (`Navigator.push` depuis
  /// `MyEyesOnlyScreen`, voir DECISIONS.md) plutôt que de la placer en
  /// `home` directement, pour que `Navigator.pop()` ait bien une route à
  /// laquelle revenir.
  Future<void> pumpAndOpenScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarkRepositoryProvider.overrideWith((ref) async => repository),
          tagRepositoryProvider.overrideWith((ref) async => tagRepository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddToMyEyesOnlyScreen(),
                  ),
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await pumpFrames(tester);
    await tester.tap(find.text('Ouvrir'));
    await pumpFrames(tester);
  }

  testWidgets('liste uniquement les bookmarks visibles (isHidden == false)', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=abc',
        title: 'Vidéo visible',
        source: VideoSource.youtube,
      );
      final alreadyHidden = await repository.createBookmark(
        url: 'https://www.youtube.com/watch?v=xyz',
        title: 'Vidéo déjà masquée',
        source: VideoSource.youtube,
      );
      await repository.updateBookmark(alreadyHidden.copyWith(isHidden: true));

      await pumpAndOpenScreen(tester);

      expect(find.text('Vidéo visible'), findsOneWidget);
      expect(find.text('Vidéo déjà masquée'), findsNothing);
    });
  });

  testWidgets(
    '"Masquer la sélection" masque les bookmarks cochés puis revient à '
    'l\'écran précédent',
    (tester) async {
      await tester.runAsync(() async {
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=abc',
          title: 'Vidéo à masquer',
          source: VideoSource.youtube,
        );
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=def',
          title: 'Vidéo à laisser visible',
          source: VideoSource.youtube,
        );

        await pumpAndOpenScreen(tester);

        expect(
          find.widgetWithText(FloatingActionButton, 'Masquer la sélection'),
          findsNothing,
        );

        await tester.tap(find.text('Vidéo à masquer'));
        await pumpFrames(tester);

        await tester.tap(
          find.widgetWithText(FloatingActionButton, 'Masquer la sélection'),
        );
        await pumpFrames(tester);

        List<VideoBookmark> updated;
        var attempts = 0;
        do {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          updated = await repository.getAllBookmarks();
          attempts++;
        } while (!updated.any(
              (bookmark) =>
                  bookmark.title == 'Vidéo à masquer' && bookmark.isHidden,
            ) &&
            attempts < 100);

        final hidden = updated.firstWhere(
          (bookmark) => bookmark.title == 'Vidéo à masquer',
        );
        final untouched = updated.firstWhere(
          (bookmark) => bookmark.title == 'Vidéo à laisser visible',
        );
        expect(hidden.isHidden, isTrue);
        expect(untouched.isHidden, isFalse);

        // Retour à l'écran précédent une fois la sélection masquée.
        expect(find.text('Ajouter à My Eyes Only'), findsNothing);
        expect(find.text('Ouvrir'), findsOneWidget);
      });
    },
  );

  testWidgets(
    'le mode "Tags" (Tâche 25) affiche HideTagListView et masque le bouton '
    '"Masquer la sélection"',
    (tester) async {
      await tester.runAsync(() async {
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=abc',
          title: 'Vidéo',
          source: VideoSource.youtube,
          tags: const ['cuisine'],
        );

        await pumpAndOpenScreen(tester);
        expect(find.text('Vidéo'), findsOneWidget);

        await tester.tap(find.text('Tags'));
        await pumpFrames(tester);

        expect(find.text('Vidéo'), findsNothing);
        expect(find.text('cuisine'), findsOneWidget);
        expect(
          find.widgetWithText(FloatingActionButton, 'Masquer la sélection'),
          findsNothing,
        );

        await tester.tap(find.text('cuisine'));
        await pumpFrames(tester);

        List<String> hiddenNames;
        var attempts = 0;
        do {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          hiddenNames = await tagRepository.getHiddenTagNames();
          attempts++;
        } while (hiddenNames.isEmpty && attempts < 100);
        expect(hiddenNames, ['cuisine']);

        final bookmarks = await repository.getAllBookmarks();
        expect(bookmarks.single.isHidden, isTrue);
      });
    },
  );
}
