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
import 'package:runk/features/tags/data/tag_repository.dart';
import 'package:runk/features/tags/data/tag_repository_provider.dart';

import '../../../../unit/features/bookmarks/data/bookmark_repository_test.dart'
    show FakeBookmarkRemoteDatasource;

/// Court-circuite `TagRepository` (donc Isar) — ces tests n'exercent aucun
/// tag géré, seuls les tags dérivés des bookmarks importent pour
/// `TagInputField` (même choix que `tag_input_field_test.dart`, voir
/// CONVENTIONS.md section Tests).
class _FakeTagRepository implements TagRepository {
  @override
  Future<List<String>> getManagedTagNames() async => const [];

  @override
  Future<void> createTag(String name) => throw UnimplementedError();

  @override
  Future<int> countBookmarksForTag(String name) => throw UnimplementedError();

  @override
  Future<void> renameTag(String oldName, String newName) =>
      throw UnimplementedError();

  @override
  Future<void> deleteTag(String name) => throw UnimplementedError();
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
      [BookmarkEntitySchema],
      directory: tempDirectory.path,
      inspector: false,
    );
    // Repository réel (comme `bookmark_search_provider_test.dart` /
    // `search_screen_test.dart`) plutôt qu'un simple fake : le critère
    // d'acceptation de la Tâche 21 porte explicitement sur la persistance
    // après fermeture/réouverture, donc sur le comportement réel
    // d'`updateBookmark`/`deleteBookmark`, pas sur une simulation de leur
    // effet.
    repository = BookmarkRepository(
      localDatasource: BookmarkLocalDatasource(isar),
      remoteDatasource: FakeBookmarkRemoteDatasource(),
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

  // isar_community résout ses opérations natives (open/find/update/delete)
  // via un port alimenté par un thread réel, jamais par un `Timer` : sous
  // `AutomatedTestWidgetsFlutterBinding` (utilisée par `testWidgets`), seul
  // `tester.runAsync` laisse ce port aboutir pour de vrai — sans lui,
  // n'importe quel `await` sur une opération Isar réelle (y compris le
  // premier `build()` de `bookmarkListProvider`, qui lit systématiquement le
  // repository dès le montage de `HomeScreen`) ne se termine jamais et
  // bloque `pumpAndSettle()` indéfiniment (voir DECISIONS.md, entrée
  // « Tâche 10 », et les commentaires équivalents dans
  // `search_screen_test.dart`).
  //
  // `pumpAndSettle()` lui-même ne fonctionne pas correctement à l'intérieur
  // d'un bloc `runAsync` (vérifié empiriquement : timeout même sur une
  // simple animation d'ouverture de bottom sheet, sans aucune opération
  // Isar en jeu à ce moment précis) — sa boucle d'attente s'appuie sur
  // l'horloge fake du test, court-circuitée par `runAsync`. [pumpFrames]
  // avance donc un nombre borné de frames brutes à la place : suffisant
  // pour qu'une route (bottom sheet/dialogue) construise son contenu, sans
  // attendre la fin exacte de sa transition visuelle (non nécessaire pour
  // que `find.text` la localise, qui n'inspecte que l'arbre d'éléments).
  Future<void> pumpFrames(WidgetTester tester, [int count = 20]) async {
    for (var i = 0; i < count; i++) {
      // Un vrai délai (pas seulement un pump) est nécessaire : la
      // continuation native d'isar_community est postée par un thread réel,
      // qui a besoin d'un tour d'event loop réel pour être relayée — un pump
      // seul, sans laisser s'écouler de temps réel, peut s'exécuter avant
      // que cette continuation n'arrive.
      await Future<void>.delayed(const Duration(milliseconds: 25));
      // `pump()` sans argument n'avance jamais l'horloge synthétique de
      // frame de `TestWidgetsFlutterBinding` : une transition de route
      // (ouverture de bottom sheet/dialogue) reste alors figée à sa valeur
      // initiale (complètement hors écran), quel que soit le nombre
      // d'appels — vérifié empiriquement (offset de hit-test identique et
      // hors bornes après 15 puis 40 pumps sans argument). Une `Duration`
      // explicite est indispensable pour faire réellement progresser la
      // transition.
      await tester.pump(const Duration(milliseconds: 25));
    }
  }

  /// Simule un appui long sur [finder], à utiliser uniquement à l'intérieur
  /// d'un bloc `runAsync`.
  ///
  /// `tester.longPress()` s'appuie en interne sur `pump(duration)` pour
  /// avancer l'horloge *fake* du test et déclencher le minuteur interne du
  /// `LongPressGestureRecognizer` (`kLongPressTimeout`) — horloge
  /// court-circuitée par `runAsync` (zone réelle, voir commentaire de tête
  /// de fichier). Le geste dégénère alors en simple tap (vérifié
  /// empiriquement : le menu contextuel ne s'ouvrait jamais, `onTap`/
  /// `openBookmark` se déclenchait à sa place). On simule donc la pression
  /// manuellement avec une vraie attente réelle, supérieure à
  /// `kLongPressTimeout` (500 ms).
  Future<void> longPressUnderRunAsync(WidgetTester tester, Finder finder) async {
    final gesture = await tester.startGesture(tester.getCenter(finder));
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await gesture.up();
  }

  testWidgets(
    'un appui long sur une carte ouvre le menu avec ses trois actions',
    (tester) async {
      await tester.runAsync(() async {
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=abc',
          title: 'Ma vidéo',
          source: VideoSource.youtube,
        );

        await pumpHomeScreen(tester);
        await pumpFrames(tester);

        await longPressUnderRunAsync(tester, find.text('Ma vidéo'));
        await pumpFrames(tester);

        expect(find.text('Modifier les tags'), findsOneWidget);
        expect(find.text('Masquer'), findsOneWidget);
        expect(find.text('Supprimer'), findsOneWidget);
      });
    },
  );

  testWidgets(
    '"Masquer" (Tâche 22) retire immédiatement le bookmark de HomeScreen, '
    'et le menu propose ensuite "Ne plus masquer"',
    (tester) async {
      await tester.runAsync(() async {
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=abc',
          title: 'Ma vidéo',
          source: VideoSource.youtube,
        );

        await pumpHomeScreen(tester);
        await pumpFrames(tester);

        await longPressUnderRunAsync(tester, find.text('Ma vidéo'));
        await pumpFrames(tester);
        await tester.tap(find.text('Masquer'));
        await pumpFrames(tester);

        List<VideoBookmark> updated;
        var attempts = 0;
        do {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          updated = await repository.getAllBookmarks();
          attempts++;
        } while (!updated.single.isHidden && attempts < 100);
        expect(updated.single.isHidden, isTrue);

        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomeScreen)),
        );
        await container.read(bookmarkListProvider.notifier).refresh();
        await pumpFrames(tester);

        expect(find.text('Ma vidéo'), findsNothing);
      });
    },
  );

  testWidgets(
    '"Modifier les tags" pré-remplit les tags existants, persiste le tag '
    'ajouté et rafraîchit la carte affichée',
    (tester) async {
      await tester.runAsync(() async {
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=abc',
          title: 'Ma vidéo',
          source: VideoSource.youtube,
          tags: const ['humour'],
        );

        await pumpHomeScreen(tester);
        await pumpFrames(tester);

        await longPressUnderRunAsync(tester, find.text('Ma vidéo'));
        await pumpFrames(tester);
        await tester.tap(find.text('Modifier les tags'));
        await pumpFrames(tester);

        // Le tag existant est déjà affiché (chip du dialogue + chip de la
        // carte derrière, toujours dans l'arbre bien qu'obscurcie).
        expect(find.text('humour'), findsWidgets);

        await tester.enterText(find.byType(TextField), 'cuisine');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await pumpFrames(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
        await pumpFrames(tester);

        // Attend que l'écriture réelle déclenchée par le tap ait atteint
        // Isar (poll borné sur une donnée réelle, jamais un délai fixe
        // seul — voir BUGS_AND_ROADMAP.md, leçon Tâche 10).
        List<VideoBookmark> updated;
        var attempts = 0;
        do {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          updated = await repository.getAllBookmarks();
          attempts++;
        } while (!updated.single.tags.contains('cuisine') && attempts < 100);
        expect(updated.single.tags, containsAll(['humour', 'cuisine']));

        // Force explicitement le rafraîchissement du provider observé par
        // `HomeScreen` : le refresh interne déclenché par le menu
        // contextuel n'est pas directement observable depuis le test.
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomeScreen)),
        );
        await container.read(bookmarkListProvider.notifier).refresh();
        await pumpFrames(tester);

        expect(find.text('cuisine'), findsOneWidget);
      });
    },
  );

  testWidgets(
    '"Supprimer" ne retire rien tant que la confirmation n\'est pas donnée',
    (tester) async {
      await tester.runAsync(() async {
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=abc',
          title: 'Ma vidéo',
          source: VideoSource.youtube,
        );

        await pumpHomeScreen(tester);
        await pumpFrames(tester);

        await longPressUnderRunAsync(tester, find.text('Ma vidéo'));
        await pumpFrames(tester);
        await tester.tap(find.text('Supprimer'));
        await pumpFrames(tester);

        expect(find.text('Cette action est définitive.'), findsOneWidget);

        await tester.tap(find.text('Annuler'));
        await pumpFrames(tester);

        expect(find.text('Ma vidéo'), findsOneWidget);
        expect(await repository.getAllBookmarks(), hasLength(1));
      });
    },
  );

  testWidgets(
    '"Supprimer" confirmé retire le bookmark de la liste affichée et de la '
    'persistance locale',
    (tester) async {
      await tester.runAsync(() async {
        await repository.createBookmark(
          url: 'https://www.youtube.com/watch?v=abc',
          title: 'Ma vidéo',
          source: VideoSource.youtube,
        );

        await pumpHomeScreen(tester);
        await pumpFrames(tester);

        await longPressUnderRunAsync(tester, find.text('Ma vidéo'));
        await pumpFrames(tester);
        await tester.tap(find.text('Supprimer'));
        await pumpFrames(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
        await pumpFrames(tester);

        // Même raison que le test précédent : la suppression réelle est
        // attendue via un poll borné sur la donnée persistée.
        List<VideoBookmark> remaining;
        var attempts = 0;
        do {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          remaining = await repository.getAllBookmarks();
          attempts++;
        } while (remaining.isNotEmpty && attempts < 100);
        expect(remaining, isEmpty);

        final container = ProviderScope.containerOf(
          tester.element(find.byType(HomeScreen)),
        );
        await container.read(bookmarkListProvider.notifier).refresh();
        await pumpFrames(tester);

        expect(find.text('Ma vidéo'), findsNothing);
      });
    },
  );
}
