import 'package:flutter_test/flutter_test.dart';
import 'package:runk/core/services/clipboard_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ClipboardHistoryStore', () {
    test('hasBeenSeen renvoie faux pour un lien jamais marqué', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ClipboardHistoryStore(await SharedPreferences.getInstance());

      expect(await store.hasBeenSeen('https://tiktok.com/@a/video/1'), isFalse);
    });

    test('markAsSeen rend hasBeenSeen vrai pour ce lien uniquement', () async {
      SharedPreferences.setMockInitialValues({});
      final store = ClipboardHistoryStore(await SharedPreferences.getInstance());

      await store.markAsSeen('https://tiktok.com/@a/video/1');

      expect(await store.hasBeenSeen('https://tiktok.com/@a/video/1'), isTrue);
      expect(await store.hasBeenSeen('https://tiktok.com/@a/video/2'), isFalse);
    });

    test('marquer deux fois le même lien ne le duplique pas', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = ClipboardHistoryStore(preferences);

      await store.markAsSeen('https://tiktok.com/@a/video/1');
      await store.markAsSeen('https://tiktok.com/@a/video/1');

      expect(preferences.getStringList('clipboard_seen_urls'), [
        'https://tiktok.com/@a/video/1',
      ]);
    });
  });
}
