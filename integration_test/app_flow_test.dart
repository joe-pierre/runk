import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';
import 'package:runk/core/services/share_intent_service.dart';
import 'package:runk/core/services/share_intent_service_provider.dart';
import 'package:runk/features/bookmarks/data/bookmark_local_datasource.dart';
import 'package:runk/features/bookmarks/data/bookmark_repository.dart';
import 'package:runk/features/bookmarks/data/bookmark_repository_provider.dart';
import 'package:runk/features/bookmarks/presentation/home_screen.dart';
import 'package:runk/features/bookmarks/presentation/share_intent_gate.dart';
import 'package:runk/features/tags/data/tag_local_datasource.dart';

import '../test/unit/features/bookmarks/data/bookmark_repository_test.dart'
    show FakeBookmarkRemoteDatasource;

/// Fake de [ShareIntentService] pilotable depuis un test, via [emit].
///
/// Contourne entièrement le canal natif `receive_sharing_intent` (aucune app
/// tierce réelle impliquée, voir contrainte de la Tâche 10) : [initialize] ne
/// fait rien et [sharedUrlStream] est backé par un [StreamController] propre
/// à ce fake, jamais celui — privé — de la classe de base.
class FakeShareIntentService extends ShareIntentService {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  @override
  Stream<String> get sharedUrlStream => _controller.stream;

  @override
  Future<void> initialize() async {}

  /// Simule la réception d'une URL déjà validée via un partage natif.
  void emit(String url) => _controller.add(url);

  @override
  void dispose() {
    _controller.close();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late Isar isar;
  late BookmarkRepository repository;
  late FakeShareIntentService fakeShareIntentService;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDirectory = Directory.systemTemp.createTempSync(
      'runk_integration_test',
    );
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
    );
    fakeShareIntentService = FakeShareIntentService();
  });

  tearDown(() async {
    await isar.close();
    tempDirectory.deleteSync(recursive: true);
  });

  testWidgets(
    'Share Intent → Metadata → Save → affichage : une URL reçue via le '
    'stream de ShareIntentService ouvre la modale, crée une entrée dans le '
    'repository et apparaît dans HomeScreen',
    (tester) async {
      const sharedUrl = 'https://example.com/une-video-de-test';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkRepositoryProvider.overrideWith((ref) async => repository),
            shareIntentServiceProvider.overrideWithValue(
              fakeShareIntentService,
            ),
          ],
          child: const MaterialApp(home: ShareIntentGate(child: HomeScreen())),
        ),
      );
      await tester.pumpAndSettle();

      // État initial : aucun bookmark.
      expect(
        find.text('Partagez une vidéo vers Runk pour commencer.'),
        findsOneWidget,
      );
      expect(await repository.getAllBookmarks(), isEmpty);

      // Simule l'émission d'une URL valide dans le stream de
      // ShareIntentService, comme le ferait un partage natif réel.
      fakeShareIntentService.emit(sharedUrl);
      await tester.pumpAndSettle();

      // La modale d'ajout s'est ouverte, pré-remplie (URL de domaine
      // inconnu : GenericFallbackProvider répond sans aucun appel réseau,
      // voir DECISIONS.md Tâche 7).
      expect(find.text('Ajouter'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Titre'), findsOneWidget);

      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();

      // La sauvegarde a créé une entrée dans le repository...
      final savedBookmarks = await repository.getAllBookmarks();
      expect(savedBookmarks, hasLength(1));
      expect(savedBookmarks.single.url, sharedUrl);

      // ...et HomeScreen affiche le nouveau bookmark, modale refermée.
      expect(find.text('Ajouter'), findsNothing);
      expect(find.text(savedBookmarks.single.title), findsOneWidget);
    },
  );
}
