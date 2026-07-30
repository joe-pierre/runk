import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/core/services/metadata/providers/instagram_provider.dart';

void main() {
  group('InstagramProvider', () {
    test('canHandle retourne vrai uniquement pour une URL Instagram', () {
      final provider = InstagramProvider();
      expect(provider.canHandle('https://www.instagram.com/reel/abc/'), isTrue);
      expect(
        provider.canHandle('https://www.youtube.com/watch?v=abc123'),
        isFalse,
      );
    });

    test('fetchMetadata retourne titre et miniature si les balises og: sont présentes', () async {
      final mockClient = MockClient((request) async {
        return http.Response('''
          <meta property="og:title" content="Mon reel Instagram" />
          <meta property="og:image" content="https://instagram.com/thumb.jpg" />
        ''', 200);
      });
      final provider = InstagramProvider(httpClient: mockClient);

      final metadata = await provider.fetchMetadata(
        'https://www.instagram.com/reel/abc/',
      );

      expect(metadata.title, 'Mon reel Instagram');
      expect(metadata.thumbnailUrl, 'https://instagram.com/thumb.jpg');
      expect(metadata.source, VideoSource.instagram);
      expect(metadata.isPartial, isFalse);
    });

    test(
      'fetchMetadata retourne isPartial: true sans exception si le scraping échoue',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('Not Found', 404);
        });
        final provider = InstagramProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://www.instagram.com/reel/abc/',
        );

        expect(metadata.isPartial, isTrue);
        expect(metadata.source, VideoSource.instagram);
      },
    );

    test(
      'fetchMetadata retourne isPartial: true sans exception si og:title est absent',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('<html><head></head></html>', 200);
        });
        final provider = InstagramProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://www.instagram.com/reel/abc/',
        );

        expect(metadata.isPartial, isTrue);
      },
    );
  });
}
