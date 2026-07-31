import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/domain/video_bookmark.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_list_provider.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_tag_filter_provider.dart';
import 'package:runk/features/tags/presentation/tags_screen.dart';

/// Court-circuite `BookmarkRepository`, comme dans
/// `distinct_tags_provider_test.dart` (voir CONVENTIONS.md section Tests).
class _FakeBookmarkList extends BookmarkList {
  _FakeBookmarkList(this._bookmarks);

  final List<VideoBookmark> _bookmarks;

  @override
  Future<List<VideoBookmark>> build() async => _bookmarks;
}

void main() {
  testWidgets(
    'un tap sur un tag active le filtre puis revient sur Home',
    (tester) async {
      final bookmark = VideoBookmark(
        id: '1',
        url: 'https://www.youtube.com/watch?v=abc',
        title: 'Vidéo',
        source: VideoSource.youtube,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        tags: const ['cuisine'],
      );
      final container = ProviderContainer(
        overrides: [
          bookmarkListProvider.overrideWith(
            () => _FakeBookmarkList([bookmark]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/tags',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Text('Home')),
          GoRoute(
            path: '/tags',
            builder: (context, state) => const TagsScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('cuisine'), findsOneWidget);

      await tester.tap(find.text('cuisine'));
      await tester.pumpAndSettle();

      expect(container.read(bookmarkTagFilterProvider), 'cuisine');
      expect(find.text('Home'), findsOneWidget);
    },
  );

  testWidgets('affiche un message quand aucun tag n\'existe', (tester) async {
    final container = ProviderContainer(
      overrides: [
        bookmarkListProvider.overrideWith(() => _FakeBookmarkList(const [])),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TagsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Ajoutez des tags à vos bookmarks pour les retrouver ici.'),
      findsOneWidget,
    );
  });
}
