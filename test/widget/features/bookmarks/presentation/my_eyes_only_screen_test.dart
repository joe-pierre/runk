import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/features/bookmarks/domain/video_bookmark.dart';
import 'package:runk/features/bookmarks/presentation/bookmark_list_provider.dart';
import 'package:runk/features/bookmarks/presentation/my_eyes_only_screen.dart';

/// Notifier de test qui court-circuite `BookmarkRepository` (donc Isar et
/// Supabase) — même pattern que `home_screen_test.dart`.
class _FakeBookmarkList extends BookmarkList {
  _FakeBookmarkList(this._bookmarks);

  final List<VideoBookmark> _bookmarks;

  @override
  Future<List<VideoBookmark>> build() async => _bookmarks;
}

void main() {
  testWidgets(
    'affiche un message quand aucun bookmark n\'est masqué',
    (tester) async {
      final visible = VideoBookmark(
        id: '1',
        url: 'https://youtube.com/watch?v=abc',
        title: 'Vidéo visible',
        source: VideoSource.youtube,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookmarkListProvider.overrideWith(
              () => _FakeBookmarkList([visible]),
            ),
          ],
          child: const MaterialApp(home: MyEyesOnlyScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aucun bookmark masqué.'), findsOneWidget);
      expect(find.text('Vidéo visible'), findsNothing);
    },
  );

  testWidgets(
    'affiche uniquement les bookmarks isHidden: true, en réutilisant '
    'BookmarkCard',
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
          child: const MaterialApp(home: MyEyesOnlyScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vidéo masquée'), findsOneWidget);
      expect(find.text('Vidéo visible'), findsNothing);
    },
  );
}
