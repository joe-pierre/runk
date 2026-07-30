import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/core/services/metadata/providers/youtube_provider.dart';

void main() {
  group('YoutubeProvider', () {
    test('canHandle retourne vrai uniquement pour une URL YouTube', () {
      final provider = YoutubeProvider();
      expect(
        provider.canHandle('https://www.youtube.com/watch?v=abc123'),
        isTrue,
      );
      expect(provider.canHandle('https://www.tiktok.com/@user/video/1'), isFalse);
    });

    test(
      'fetchMetadata retourne titre et miniature depuis la réponse oEmbed',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.host, 'www.youtube.com');
          expect(request.url.path, '/oembed');
          return http.Response(
            '{"title": "Ma vidéo YouTube", "thumbnail_url": "https://img.youtube.com/thumb.jpg"}',
            200,
          );
        });
        final provider = YoutubeProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://www.youtube.com/watch?v=abc123',
        );

        expect(metadata.title, 'Ma vidéo YouTube');
        expect(metadata.thumbnailUrl, 'https://img.youtube.com/thumb.jpg');
        expect(metadata.source, VideoSource.youtube);
        expect(metadata.isPartial, isFalse);
      },
    );

    test('fetchMetadata lève une exception si la réponse est en erreur', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final provider = YoutubeProvider(httpClient: mockClient);

      expect(
        () => provider.fetchMetadata('https://www.youtube.com/watch?v=abc123'),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
