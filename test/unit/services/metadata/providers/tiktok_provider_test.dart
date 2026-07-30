import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/core/services/metadata/providers/tiktok_provider.dart';

void main() {
  group('TiktokProvider', () {
    test('canHandle retourne vrai uniquement pour une URL TikTok', () {
      final provider = TiktokProvider();
      expect(provider.canHandle('https://www.tiktok.com/@user/video/1'), isTrue);
      expect(
        provider.canHandle('https://www.youtube.com/watch?v=abc123'),
        isFalse,
      );
    });

    test(
      'fetchMetadata retourne titre et miniature depuis la réponse oEmbed',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.host, 'www.tiktok.com');
          expect(request.url.path, '/oembed');
          return http.Response(
            '{"title": "Ma vidéo TikTok", "thumbnail_url": "https://p.tiktok.com/thumb.jpg"}',
            200,
          );
        });
        final provider = TiktokProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://www.tiktok.com/@user/video/1',
        );

        expect(metadata.title, 'Ma vidéo TikTok');
        expect(metadata.thumbnailUrl, 'https://p.tiktok.com/thumb.jpg');
        expect(metadata.source, VideoSource.tiktok);
        expect(metadata.isPartial, isFalse);
      },
    );

    test('fetchMetadata lève une exception si la réponse est en erreur', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final provider = TiktokProvider(httpClient: mockClient);

      expect(
        () => provider.fetchMetadata('https://www.tiktok.com/@user/video/1'),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
