import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:runk/core/services/metadata/providers/og_tag_scraper.dart';

void main() {
  group('OgTagScraper', () {
    test('extrait og:title et og:image quel que soit l\'ordre des attributs', () async {
      final mockClient = MockClient((request) async {
        return http.Response('''
          <html><head>
            <meta property="og:title" content="Titre trouvé" />
            <meta content="https://exemple.com/thumb.jpg" property="og:image" />
          </head></html>
        ''', 200);
      });
      final scraper = OgTagScraper(httpClient: mockClient);

      final tags = await scraper.scrape('https://exemple.com/post/1');

      expect(tags.title, 'Titre trouvé');
      expect(tags.imageUrl, 'https://exemple.com/thumb.jpg');
    });

    test('retourne des champs null si les balises og: sont absentes', () async {
      final mockClient = MockClient((request) async {
        return http.Response('<html><head></head></html>', 200);
      });
      final scraper = OgTagScraper(httpClient: mockClient);

      final tags = await scraper.scrape('https://exemple.com/post/1');

      expect(tags.title, isNull);
      expect(tags.imageUrl, isNull);
    });

    test('retourne des champs null (jamais d\'exception) si la réponse est en erreur', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final scraper = OgTagScraper(httpClient: mockClient);

      final tags = await scraper.scrape('https://exemple.com/post/1');

      expect(tags.title, isNull);
      expect(tags.imageUrl, isNull);
    });

    test('retourne des champs null (jamais d\'exception) si le délai est dépassé', () async {
      final mockClient = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response('<meta property="og:title" content="Trop tard" />', 200);
      });
      final scraper = OgTagScraper(
        httpClient: mockClient,
        timeout: const Duration(milliseconds: 10),
      );

      final tags = await scraper.scrape('https://exemple.com/post/1');

      expect(tags.title, isNull);
      expect(tags.imageUrl, isNull);
    });
  });
}
