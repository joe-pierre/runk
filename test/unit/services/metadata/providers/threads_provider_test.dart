import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/core/services/metadata/providers/threads_provider.dart';

void main() {
  group('ThreadsProvider', () {
    test('canHandle retourne vrai uniquement pour une URL Threads', () {
      final provider = ThreadsProvider();
      expect(
        provider.canHandle('https://www.threads.net/@user/post/123'),
        isTrue,
      );
      expect(
        provider.canHandle('https://www.youtube.com/watch?v=abc123'),
        isFalse,
      );
    });

    test('fetchMetadata retourne titre et miniature si les balises og: sont présentes', () async {
      final mockClient = MockClient((request) async {
        return http.Response('''
          <meta property="og:title" content="Mon post Threads" />
          <meta property="og:image" content="https://threads.net/thumb.jpg" />
        ''', 200);
      });
      final provider = ThreadsProvider(httpClient: mockClient);

      final metadata = await provider.fetchMetadata(
        'https://www.threads.net/@user/post/123',
      );

      expect(metadata.title, 'Mon post Threads');
      expect(metadata.thumbnailUrl, 'https://threads.net/thumb.jpg');
      expect(metadata.source, VideoSource.threads);
      expect(metadata.isPartial, isFalse);
    });

    test(
      'fetchMetadata retourne isPartial: true sans exception si le scraping échoue '
      '(cas fréquent et attendu pour Threads)',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('Not Found', 404);
        });
        final provider = ThreadsProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://www.threads.net/@user/post/123',
        );

        expect(metadata.isPartial, isTrue);
        expect(metadata.source, VideoSource.threads);
      },
    );
  });
}
