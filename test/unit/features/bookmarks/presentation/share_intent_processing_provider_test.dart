import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/features/bookmarks/presentation/share_intent_processing_provider.dart';

void main() {
  test('vaut faux par défaut, vrai après set(true)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(shareIntentProcessingProvider), isFalse);

    container.read(shareIntentProcessingProvider.notifier).set(true);
    expect(container.read(shareIntentProcessingProvider), isTrue);

    container.read(shareIntentProcessingProvider.notifier).set(false);
    expect(container.read(shareIntentProcessingProvider), isFalse);
  });
}
