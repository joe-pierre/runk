import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/domain/video_bookmark.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_list_provider.dart';
import 'package:runk/features/bookmarks/presentation/home_screen.dart';

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
}
