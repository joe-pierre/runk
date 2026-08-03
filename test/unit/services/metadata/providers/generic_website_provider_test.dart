import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/core/services/metadata/providers/generic_website_provider.dart';

void main() {
  group('GenericWebsiteProvider', () {
    test('canHandle retourne vrai pour toute URL http/https valide', () {
      final provider = GenericWebsiteProvider();
      expect(provider.canHandle('https://exemple-de-blog.com/article'), isTrue);
      expect(provider.canHandle('http://exemple.com/page'), isTrue);
    });

    test('canHandle retourne faux pour une URL invalide ou un autre schéma', () {
      final provider = GenericWebsiteProvider();
      expect(provider.canHandle('pas une url'), isFalse);
      expect(provider.canHandle('ftp://exemple.com/fichier'), isFalse);
    });

    test('fetchMetadata retourne titre et miniature si les balises og: sont présentes', () async {
      final mockClient = MockClient((request) async {
        return http.Response('''
          <meta property="og:title" content="Titre de mon article de blog" />
          <meta property="og:image" content="https://exemple.com/thumb.jpg" />
        ''', 200);
      });
      final provider = GenericWebsiteProvider(httpClient: mockClient);

      final metadata = await provider.fetchMetadata(
        'https://exemple-de-blog.com/article',
      );

      expect(metadata.title, 'Titre de mon article de blog');
      expect(metadata.thumbnailUrl, 'https://exemple.com/thumb.jpg');
      expect(metadata.source, VideoSource.website);
      expect(metadata.isPartial, isFalse);
    });

    test(
      'fetchMetadata retourne isPartial: true sans exception si le scraping échoue',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('Not Found', 404);
        });
        final provider = GenericWebsiteProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://exemple-de-blog.com/article',
        );

        expect(metadata.title, GenericWebsiteProvider.defaultTitle);
        expect(metadata.thumbnailUrl, isNull);
        expect(metadata.source, VideoSource.website);
        expect(metadata.isPartial, isTrue);
      },
    );

    test(
      'fetchMetadata retourne isPartial: true sans exception si og:title est absent',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('<html><head></head></html>', 200);
        });
        final provider = GenericWebsiteProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://exemple-de-blog.com/article',
        );

        expect(metadata.isPartial, isTrue);
      },
    );
  });
}
