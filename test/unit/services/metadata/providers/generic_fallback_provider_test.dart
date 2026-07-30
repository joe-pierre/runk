import 'package:flutter_test/flutter_test.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/core/services/metadata/providers/generic_fallback_provider.dart';

void main() {
  group('GenericFallbackProvider', () {
    test('canHandle retourne toujours vrai', () {
      final provider = GenericFallbackProvider();
      expect(provider.canHandle('https://example.com/video'), isTrue);
      expect(provider.canHandle('pas une url'), isTrue);
    });

    test(
      'fetchMetadata retourne un résultat partiel avec le titre par défaut',
      () async {
        final provider = GenericFallbackProvider();

        final metadata = await provider.fetchMetadata(
          'https://example.com/video',
        );

        expect(metadata.title, GenericFallbackProvider.defaultTitle);
        expect(metadata.thumbnailUrl, isNull);
        expect(metadata.source, VideoSource.unknown);
        expect(metadata.isPartial, isTrue);
      },
    );

    test('fetchMetadata déduit tout de même la source si détectable', () async {
      final provider = GenericFallbackProvider();

      final metadata = await provider.fetchMetadata(
        'https://www.facebook.com/watch/?v=123',
      );

      expect(metadata.source, VideoSource.facebook);
      expect(metadata.isPartial, isTrue);
    });
  });
}
