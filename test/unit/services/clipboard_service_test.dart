import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/core/services/clipboard_history_store.dart';
import 'package:runk/core/services/clipboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simule le contenu du presse-papier système en interceptant le canal de
/// méthode `SystemChannels.platform`, comme le fait `Clipboard.getData`
/// sous le capot — évite toute dépendance à un vrai presse-papier natif.
void _mockClipboardValue(String? value) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') {
          return value == null ? null : <String, dynamic>{'text': value};
        }
        return null;
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ClipboardService> buildService() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    return ClipboardService(ClipboardHistoryStore(preferences));
  }

  group('ClipboardService', () {
    test(
      'propose une URL vidéo valide et nouvelle au retour au premier plan',
      () async {
        final service = await buildService();
        final suggestions = <String>[];
        service.suggestedUrlStream.listen(suggestions.add);

        _mockClipboardValue('https://www.tiktok.com/@user/video/123');
        service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await pumpEventQueue();

        expect(suggestions, ['https://www.tiktok.com/@user/video/123']);
        service.dispose();
      },
    );

    test(
      'ignore silencieusement un lien qui n\'est pas une URL vidéo reconnue',
      () async {
        final service = await buildService();
        final suggestions = <String>[];
        service.suggestedUrlStream.listen(suggestions.add);

        _mockClipboardValue('https://example.com/pas-une-video');
        service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await pumpEventQueue();

        expect(suggestions, isEmpty);
        service.dispose();
      },
    );

    test('ignore silencieusement un texte qui n\'est pas une URL', () async {
      final service = await buildService();
      final suggestions = <String>[];
      service.suggestedUrlStream.listen(suggestions.add);

      _mockClipboardValue('juste du texte copié');
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(suggestions, isEmpty);
      service.dispose();
    });

    test('ne propose jamais deux fois un lien déjà marqué comme vu', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final historyStore = ClipboardHistoryStore(preferences);
      await historyStore.markAsSeen('https://www.tiktok.com/@user/video/123');
      final service = ClipboardService(historyStore);

      final suggestions = <String>[];
      service.suggestedUrlStream.listen(suggestions.add);

      _mockClipboardValue('https://www.tiktok.com/@user/video/123');
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(suggestions, isEmpty);
      service.dispose();
    });

    test(
      'ne lit pas le presse-papier hors transition vers resumed',
      () async {
        final service = await buildService();
        final suggestions = <String>[];
        service.suggestedUrlStream.listen(suggestions.add);

        _mockClipboardValue('https://www.tiktok.com/@user/video/123');
        service.didChangeAppLifecycleState(AppLifecycleState.inactive);
        service.didChangeAppLifecycleState(AppLifecycleState.paused);
        await pumpEventQueue();

        expect(suggestions, isEmpty);
        service.dispose();
      },
    );

    test('markAsSeen empêche toute nouvelle proposition du même lien', () async {
      final service = await buildService();
      final suggestions = <String>[];
      service.suggestedUrlStream.listen(suggestions.add);

      const url = 'https://www.tiktok.com/@user/video/123';
      await service.markAsSeen(url);

      _mockClipboardValue(url);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();

      expect(suggestions, isEmpty);
      service.dispose();
    });
  });
}
