import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/core/services/metadata/providers/maps_provider.dart';

void main() {
  group('MapsProvider', () {
    test('canHandle retourne vrai uniquement pour un lien Google Maps', () {
      final provider = MapsProvider();
      expect(
        provider.canHandle('https://maps.app.goo.gl/QS9xeZqTY7BzB6Vq6'),
        isTrue,
      );
      expect(
        provider.canHandle(
          'https://www.google.com/maps/place/Eiffel+Tower/@48.8584,2.2945,17z',
        ),
        isTrue,
      );
    });

    test(
      'canHandle retourne faux pour un lien google.com non-Maps ou une autre plateforme',
      () {
        final provider = MapsProvider();
        expect(provider.canHandle('https://www.google.com/search?q=chat'), isFalse);
        expect(
          provider.canHandle('https://www.youtube.com/watch?v=abc123'),
          isFalse,
        );
      },
    );

    test(
      'fetchMetadata retourne le titre sans jamais renseigner thumbnailUrl, même si og:image est présent',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('''
            <meta property="og:title" content="Tour Eiffel" />
            <meta property="og:image" content="https://exemple.com/carte.jpg" />
          ''', 200);
        });
        final provider = MapsProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://maps.app.goo.gl/QS9xeZqTY7BzB6Vq6',
        );

        expect(metadata.title, 'Tour Eiffel');
        expect(metadata.thumbnailUrl, isNull);
        expect(metadata.source, VideoSource.maps);
        expect(metadata.isPartial, isFalse);
      },
    );

    test(
      'fetchMetadata retourne isPartial: true avec un titre de repli si og:title est absent',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('<html><head></head></html>', 200);
        });
        final provider = MapsProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://maps.app.goo.gl/QS9xeZqTY7BzB6Vq6',
        );

        expect(metadata.title, MapsProvider.defaultTitle);
        expect(metadata.thumbnailUrl, isNull);
        expect(metadata.isPartial, isTrue);
      },
    );

    test(
      'fetchMetadata retourne isPartial: true sans exception si le scraping échoue',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('Not Found', 404);
        });
        final provider = MapsProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://maps.app.goo.gl/QS9xeZqTY7BzB6Vq6',
        );

        expect(metadata.title, MapsProvider.defaultTitle);
        expect(metadata.isPartial, isTrue);
      },
    );
  });
}
