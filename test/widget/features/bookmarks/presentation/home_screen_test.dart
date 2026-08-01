import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/core/services/deep_link_service.dart';
import 'package:runk/core/services/deep_link_service_provider.dart';
import 'package:runk/features/bookmarks/domain/video_bookmark.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_list_provider.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_tag_filter_provider.dart';
import 'package:runk/features/bookmarks/presentation/home_screen.dart';
import 'package:runk/features/bookmarks/presentation/manual_add_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
}
