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
import 'package:runk/features/bookmarks/presentation/home_screen.dart';
import 'package:runk/features/tags/data/tag_local_datasource.dart';
import 'package:runk/features/tags/data/tag_repository.dart';
import 'package:runk/features/tags/data/tag_repository_provider.dart';

import '../../../../unit/features/bookmarks/data/bookmark_repository_test.dart'
    show FakeBookmarkRemoteDatasource;

/// Court-circuite `TagRepository` (donc Isar) — voir même choix documenté
/// dans `bookmark_context_menu_test.dart`.
class _FakeTagRepository implements TagRepository {
  @override
  Future<List<String>> getManagedTagNames() async => const [];

  @override
  Future<List<String>> getHiddenTagNames() async => const [];

  @override
  Future<void> createTag(String name) => throw UnimplementedError();

  @override
  Future<int> countBookmarksForTag(String name) => throw UnimplementedError();

  @override
  Future<void> renameTag(String oldName, String newName) =>
      throw UnimplementedError();

  @override
  Future<void> deleteTag(String name) => throw UnimplementedError();

  @override
  Future<void> hideTag(String name) => throw UnimplementedError();

  @override
  Future<void> unhideTag(String name) => throw UnimplementedError();
}

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

  Future<void> pumpHomeScreen(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookmarkRepositoryProvider.overrideWith((ref) async => repository),
          tagRepositoryProvider.overrideWith(
            (ref) async => _FakeTagRepository(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
  }

  // Même raison que `bookmark_context_menu_test.dart` : isar_community
  // résout ses opérations natives via un port réel, jamais un `Timer` —
  // sous `AutomatedTestWidgetsFlutterBinding`, seul `tester.runAsync` laisse
  // ce port aboutir, et `pumpFrames` avance des frames réelles au lieu de
  // `pumpAndSettle()` (qui ne « settle » jamais sous `runAsync`, voir
  // DECISIONS.md, entrée « Tâche 10 »).
  Future<void> pumpFrames(WidgetTester tester, [int count = 20]) async {
    for (var i = 0; i < count; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
      await tester.pump(const Duration(milliseconds: 25));
    }
  }

  Finder checkboxFor(String title) => find.descendant(
    of: find.ancestor(of: find.text(title), matching: find.byType(Card)),
    matching: find.byType(Checkbox),
  );

  testWidgets(
    'l\'icône de l\'AppBar active le mode sélection et affiche une case à '
    'cocher par carte, sans jamais proposer le masquage',
    (tester) async {
      await tester.runAsync(() async {
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=1',
          title: 'Un',
          source: VideoSource.youtube,
        );
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=2',
          title: 'Deux',
          source: VideoSource.youtube,
        );

        await pumpHomeScreen(tester);
        await pumpFrames(tester);

        expect(find.byType(Checkbox), findsNothing);

        await tester.tap(find.byIcon(Icons.checklist));
        await pumpFrames(tester);

        expect(find.byType(Checkbox), findsNWidgets(2));
        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.text('Masquer'), findsNothing);
        expect(find.text('Ne plus masquer'), findsNothing);
      });
    },
  );

  testWidgets(
    'la croix quitte le mode sélection et vide la sélection en cours',
    (tester) async {
      await tester.runAsync(() async {
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=1',
          title: 'Un',
          source: VideoSource.youtube,
        );

        await pumpHomeScreen(tester);
        await pumpFrames(tester);

        await tester.tap(find.byIcon(Icons.checklist));
        await pumpFrames(tester);
        await tester.tap(checkboxFor('Un'));
        await pumpFrames(tester);

        expect(find.text('Supprimer (1)'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await pumpFrames(tester);

        expect(find.byIcon(Icons.checklist), findsOneWidget);
        expect(find.byType(Checkbox), findsNothing);
        expect(find.text('Supprimer (1)'), findsNothing);
      });
    },
  );

  testWidgets(
    '"Supprimer (N)" confirmé supprime tous les bookmarks cochés, sans '
    'toucher aux autres, puis quitte le mode sélection',
    (tester) async {
      await tester.runAsync(() async {
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=1',
          title: 'Un',
          source: VideoSource.youtube,
        );
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=2',
          title: 'Deux',
          source: VideoSource.youtube,
        );
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=3',
          title: 'Trois',
          source: VideoSource.youtube,
        );

        await pumpHomeScreen(tester);
        await pumpFrames(tester);

        await tester.tap(find.byIcon(Icons.checklist));
        await pumpFrames(tester);
        await tester.tap(checkboxFor('Un'));
        await pumpFrames(tester);
        await tester.tap(checkboxFor('Deux'));
        await pumpFrames(tester);

        expect(find.text('Supprimer (2)'), findsOneWidget);

        await tester.tap(find.text('Supprimer (2)'));
        await pumpFrames(tester);

        expect(find.text('Supprimer 2 bookmarks ?'), findsOneWidget);
        expect(find.text('Cette action est définitive.'), findsOneWidget);

        await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
        await pumpFrames(tester);

        List<VideoBookmark> remaining;
        var attempts = 0;
        do {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          remaining = await repository.getAllBookmarks();
          attempts++;
        } while (remaining.length > 1 && attempts < 100);
        expect(remaining.map((b) => b.title), ['Trois']);

        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomeScreen)),
        );
        await container.read(bookmarkListProvider.notifier).refresh();
        await pumpFrames(tester);

        expect(find.text('Un'), findsNothing);
        expect(find.text('Deux'), findsNothing);
        expect(find.text('Trois'), findsOneWidget);
        // Mode sélection quitté automatiquement (voir critère d'acceptation
        // de la Tâche 26).
        expect(find.byIcon(Icons.checklist), findsOneWidget);
        expect(find.byType(Checkbox), findsNothing);
      });
    },
  );

  testWidgets(
    '"Ajouter un tag (N)" ajoute le tag saisi à tous les bookmarks cochés '
    'en union avec leurs tags existants, sans en effacer aucun',
    (tester) async {
      await tester.runAsync(() async {
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=1',
          title: 'Un',
          source: VideoSource.youtube,
          tags: const ['existant'],
        );
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=2',
          title: 'Deux',
          source: VideoSource.youtube,
        );

        await pumpHomeScreen(tester);
        await pumpFrames(tester);

        await tester.tap(find.byIcon(Icons.checklist));
        await pumpFrames(tester);
        await tester.tap(checkboxFor('Un'));
        await pumpFrames(tester);
        await tester.tap(checkboxFor('Deux'));
        await pumpFrames(tester);

        await tester.tap(find.text('Ajouter un tag (2)'));
        await pumpFrames(tester);

        expect(find.text('Ajouter un tag à 2 bookmarks'), findsOneWidget);

        // find.byType(TextField) seul est désormais ambigu depuis la Tâche
        // 30 : HomeScreen porte aussi le champ de recherche intégré — on
        // cible celui du dialogue "Ajouter un tag" (AlertDialog).
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
          'nouveau',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await pumpFrames(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
        await pumpFrames(tester);

        List<VideoBookmark> updated;
        var attempts = 0;
        do {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          updated = await repository.getAllBookmarks();
          attempts++;
        } while (
            !updated.every((b) => b.tags.contains('nouveau')) &&
            attempts < 100);

        final un = updated.firstWhere((b) => b.title == 'Un');
        final deux = updated.firstWhere((b) => b.title == 'Deux');
        expect(un.tags, containsAll(['existant', 'nouveau']));
        expect(deux.tags, ['nouveau']);

        // Mode sélection quitté automatiquement après l'action groupée.
        await pumpFrames(tester);
        expect(find.byIcon(Icons.checklist), findsOneWidget);
        expect(find.byType(Checkbox), findsNothing);
      });
    },
  );
}
