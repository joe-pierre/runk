import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/core/services/clipboard_history_store.dart';
import 'package:runk/core/services/clipboard_service.dart';
import 'package:runk/core/services/clipboard_service_provider.dart';
import 'package:runk/features/bookmarks/presentation/clipboard_suggestion_provider.dart';
import 'package:runk/features/bookmarks/presentation/share_intent_processing_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _mockClipboardValue(String value) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': value};
        }
        return null;
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({ProviderContainer container, ClipboardService service})>
  buildContainer() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = ClipboardService(ClipboardHistoryStore(preferences));

    final container = ProviderContainer(
      overrides: [clipboardServiceProvider.overrideWith((ref) async => service)],
    );
    addTearDown(container.dispose);
    addTearDown(service.dispose);

    // Force l'initialisation du provider (lazy par défaut).
    container.listen(clipboardSuggestionProvider, (previous, next) {});
    await pumpEventQueue();

    return (container: container, service: service);
  }

  group('ClipboardSuggestion', () {
    test(
      'un Share Intent en cours empêche temporairement la bannière',
      () async {
        final built = await buildContainer();

        built.container.read(shareIntentProcessingProvider.notifier).set(true);

        _mockClipboardValue('https://www.tiktok.com/@user/video/123');
        built.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await pumpEventQueue();

        expect(built.container.read(clipboardSuggestionProvider), isNull);
      },
    );

    test(
      'affiche la suggestion quand aucun Share Intent n\'est en cours',
      () async {
        final built = await buildContainer();

        _mockClipboardValue('https://www.tiktok.com/@user/video/123');
        built.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await pumpEventQueue();

        expect(
          built.container.read(clipboardSuggestionProvider),
          'https://www.tiktok.com/@user/video/123',
        );
      },
    );

    test('markAsSeen referme la bannière et mémorise le lien', () async {
      final built = await buildContainer();

      _mockClipboardValue('https://www.tiktok.com/@user/video/123');
      built.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(built.container.read(clipboardSuggestionProvider), isNotNull);

      await built.container
          .read(clipboardSuggestionProvider.notifier)
          .markAsSeen('https://www.tiktok.com/@user/video/123');

      expect(built.container.read(clipboardSuggestionProvider), isNull);

      // Un nouveau retour au premier plan ne reproprose plus ce lien.
      built.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(built.container.read(clipboardSuggestionProvider), isNull);
    });
  });
}
