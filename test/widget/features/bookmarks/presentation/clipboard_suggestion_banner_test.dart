import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/features/bookmarks/presentation/clipboard_suggestion_banner.dart';
import 'package:runk/features/bookmarks/presentation/clipboard_suggestion_provider.dart';

/// Notifier de test qui court-circuite `ClipboardService` : expose
/// directement un état contrôlé par le test via [set], comme
/// `_FakeBookmarkList` le fait déjà pour `BookmarkList` dans
/// `home_screen_test.dart` (voir CONVENTIONS.md section Tests).
class _FakeClipboardSuggestion extends ClipboardSuggestion {
  @override
  String? build() => null;

  void set(String? value) => state = value;

  @override
  Future<void> markAsSeen(String url) async {
    state = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<({ProviderContainer container, _FakeClipboardSuggestion notifier})>
  pumpBanner(WidgetTester tester) async {
    final notifier = _FakeClipboardSuggestion();
    final container = ProviderContainer(
      overrides: [clipboardSuggestionProvider.overrideWith(() => notifier)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: ClipboardSuggestionBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return (container: container, notifier: notifier);
  }

  testWidgets(
    'n\'affiche rien tant qu\'aucune suggestion n\'est active',
    (tester) async {
      await pumpBanner(tester);

      expect(find.byType(MaterialBanner), findsNothing);
    },
  );

  testWidgets(
    'affiche la bannière avec une couleur d\'accent distincte du fond par '
    'défaut',
    (tester) async {
      final built = await pumpBanner(tester);

      built.notifier.set('https://youtube.com/watch?v=abc');
      await tester.pumpAndSettle();

      final banner = tester.widget<MaterialBanner>(
        find.byType(MaterialBanner),
      );
      final colorScheme = Theme.of(
        tester.element(find.byType(MaterialBanner)),
      ).colorScheme;
      expect(banner.backgroundColor, colorScheme.primaryContainer);
    },
  );

  testWidgets(
    'l\'apparition d\'une suggestion se fait par transition, pas '
    'instantanément',
    (tester) async {
      final built = await pumpBanner(tester);

      built.notifier.set('https://youtube.com/watch?v=abc');
      await tester.pump();
      // Immédiatement après le changement d'état, l'animation d'entrée
      // vient tout juste de démarrer : la bannière n'est pas encore
      // pleinement opaque.
      final fadeTransition = tester.widget<FadeTransition>(
        find.ancestor(
          of: find.byType(MaterialBanner),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fadeTransition.opacity.value, lessThan(1.0));

      await tester.pumpAndSettle();
      final settledFadeTransition = tester.widget<FadeTransition>(
        find.ancestor(
          of: find.byType(MaterialBanner),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(settledFadeTransition.opacity.value, 1.0);
    },
  );

  testWidgets(
    'déclenche un retour haptique une seule fois par nouvelle suggestion, '
    'jamais à un simple rebuild',
    (tester) async {
      final hapticCalls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              hapticCalls.add(call.arguments as String);
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final built = await pumpBanner(tester);
      expect(hapticCalls, isEmpty);

      built.notifier.set('https://youtube.com/watch?v=abc');
      await tester.pumpAndSettle();
      expect(hapticCalls, hasLength(1));

      // Rebuilds successifs sans changement d'état : pas de nouveau
      // déclenchement.
      await tester.pump();
      await tester.pump();
      expect(hapticCalls, hasLength(1));

      // La disparition (Ignorer/Ajouter) ne déclenche jamais de haptique.
      await built.notifier.markAsSeen('https://youtube.com/watch?v=abc');
      await tester.pumpAndSettle();
      expect(hapticCalls, hasLength(1));

      // Une nouvelle suggestion déclenche de nouveau le retour haptique.
      built.notifier.set('https://www.tiktok.com/@user/video/123');
      await tester.pumpAndSettle();
      expect(hapticCalls, hasLength(2));
    },
  );
}
