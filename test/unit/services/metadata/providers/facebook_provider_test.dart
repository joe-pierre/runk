import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/core/services/metadata/providers/facebook_provider.dart';

void main() {
  group('FacebookProvider', () {
    test('canHandle retourne vrai uniquement pour une URL Facebook', () {
      final provider = FacebookProvider();
      expect(
        provider.canHandle('https://www.facebook.com/watch/?v=123'),
        isTrue,
      );
      expect(provider.canHandle('https://fb.watch/abc123/'), isTrue);
      expect(
        provider.canHandle('https://www.youtube.com/watch?v=abc123'),
        isFalse,
      );
    });

    test('fetchMetadata retourne titre et miniature si les balises og: sont présentes', () async {
      final mockClient = MockClient((request) async {
        return http.Response('''
          <meta property="og:title" content="Ma vidéo Facebook" />
          <meta property="og:image" content="https://facebook.com/thumb.jpg" />
        ''', 200);
      });
      final provider = FacebookProvider(httpClient: mockClient);

      final metadata = await provider.fetchMetadata(
        'https://www.facebook.com/watch/?v=123',
      );

      expect(metadata.title, 'Ma vidéo Facebook');
      expect(metadata.thumbnailUrl, 'https://facebook.com/thumb.jpg');
      expect(metadata.source, VideoSource.facebook);
      expect(metadata.isPartial, isFalse);
    });

    test(
      'fetchMetadata retourne isPartial: true sans exception si le scraping échoue '
      '(cas fréquent et attendu pour Facebook)',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('Login required', 302);
        });
        final provider = FacebookProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://www.facebook.com/watch/?v=123',
        );

        expect(metadata.isPartial, isTrue);
        expect(metadata.source, VideoSource.facebook);
      },
    );
  });
}
