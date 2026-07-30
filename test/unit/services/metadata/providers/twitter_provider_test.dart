import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/core/services/metadata/providers/twitter_provider.dart';

void main() {
  group('TwitterProvider', () {
    test('canHandle retourne vrai uniquement pour une URL X/Twitter', () {
      final provider = TwitterProvider();
      expect(provider.canHandle('https://twitter.com/user/status/123'), isTrue);
      expect(provider.canHandle('https://x.com/user/status/123'), isTrue);
      expect(
        provider.canHandle('https://www.youtube.com/watch?v=abc123'),
        isFalse,
      );
    });

    test('fetchMetadata retourne un titre basé sur author_name depuis la réponse oEmbed', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.host, 'publish.twitter.com');
        expect(request.url.path, '/oembed');
        return http.Response(
          '{"author_name": "Jean Dupont", "html": "<blockquote></blockquote>"}',
          200,
        );
      });
      final provider = TwitterProvider(httpClient: mockClient);

      final metadata = await provider.fetchMetadata(
        'https://twitter.com/user/status/123',
      );

      expect(metadata.title, 'Post de Jean Dupont sur X');
      expect(metadata.thumbnailUrl, isNull);
      expect(metadata.source, VideoSource.twitter);
      expect(metadata.isPartial, isFalse);
    });

    test('fetchMetadata lève une exception si la réponse est en erreur', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final provider = TwitterProvider(httpClient: mockClient);

      expect(
        () => provider.fetchMetadata('https://twitter.com/user/status/123'),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
