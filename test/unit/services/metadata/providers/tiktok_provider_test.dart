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
      'fetchMetadata retourne titre et miniature depuis la réponse oEmbed, '
      'sans URL canonique quand la résolution ne redirige pas',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/oembed') {
            expect(request.url.host, 'www.tiktok.com');
            return http.Response(
              '{"title": "Ma vidéo TikTok", "thumbnail_url": "https://p.tiktok.com/thumb.jpg"}',
              200,
            );
          }
          // Requête de résolution de l'URL canonique : pas de redirection.
          return http.Response('', 200);
        });
        final provider = TiktokProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://www.tiktok.com/@user/video/1',
        );

        expect(metadata.title, 'Ma vidéo TikTok');
        expect(metadata.thumbnailUrl, 'https://p.tiktok.com/thumb.jpg');
        expect(metadata.source, VideoSource.tiktok);
        expect(metadata.isPartial, isFalse);
        expect(metadata.canonicalUrl, 'https://www.tiktok.com/@user/video/1');
      },
    );

    test('fetchMetadata lève une exception si la réponse oEmbed est en erreur', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/oembed') {
          return http.Response('Not Found', 404);
        }
        return http.Response('', 200);
      });
      final provider = TiktokProvider(httpClient: mockClient);

      expect(
        () => provider.fetchMetadata('https://www.tiktok.com/@user/video/1'),
        throwsA(isA<http.ClientException>()),
      );
    });

    test(
      'fetchMetadata renseigne canonicalUrl avec l\'URL longue résolue à '
      'partir d\'un lien court vm.tiktok.com (voir DECISIONS.md, Tâche 31)',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/oembed') {
            return http.Response(
              '{"title": "Ma vidéo TikTok", "thumbnail_url": null}',
              200,
            );
          }
          if (request.url.host == 'vm.tiktok.com') {
            return http.Response(
              '',
              301,
              headers: {
                'location': 'https://www.tiktok.com/@user/video/9876543210',
              },
            );
          }
          return http.Response('', 200);
        });
        final provider = TiktokProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://vm.tiktok.com/ZS4BB5Rc7/',
        );

        expect(
          metadata.canonicalUrl,
          'https://www.tiktok.com/@user/video/9876543210',
        );
      },
    );

    test(
      'fetchMetadata suit plusieurs sauts de redirection avant de résoudre '
      'canonicalUrl',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/oembed') {
            return http.Response('{"title": "T", "thumbnail_url": null}', 200);
          }
          if (request.url.host == 'vm.tiktok.com') {
            return http.Response(
              '',
              302,
              headers: {'location': 'https://www.tiktok.com/redirect/abc'},
            );
          }
          if (request.url.path == '/redirect/abc') {
            return http.Response(
              '',
              302,
              headers: {
                'location': 'https://www.tiktok.com/@user/video/111',
              },
            );
          }
          return http.Response('', 200);
        });
        final provider = TiktokProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://vm.tiktok.com/ZS4BB5Rc7/',
        );

        expect(metadata.canonicalUrl, 'https://www.tiktok.com/@user/video/111');
      },
    );

    test(
      'fetchMetadata laisse canonicalUrl à null si la résolution échoue '
      'côté réseau, sans faire échouer la sauvegarde (comportement oEmbed '
      'inchangé, voir DECISIONS.md, Tâche 31)',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/oembed') {
            return http.Response(
              '{"title": "Ma vidéo TikTok", "thumbnail_url": "https://p.tiktok.com/thumb.jpg"}',
              200,
            );
          }
          throw http.ClientException('Erreur réseau simulée');
        });
        final provider = TiktokProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://vm.tiktok.com/ZS4BB5Rc7/',
        );

        expect(metadata.title, 'Ma vidéo TikTok');
        expect(metadata.thumbnailUrl, 'https://p.tiktok.com/thumb.jpg');
        expect(metadata.isPartial, isFalse);
        expect(metadata.canonicalUrl, isNull);
      },
    );

    test(
      'fetchMetadata laisse canonicalUrl à null si la résolution dépasse '
      'trop de sauts de redirection',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.path == '/oembed') {
            return http.Response('{"title": "T", "thumbnail_url": null}', 200);
          }
          // Redirige indéfiniment vers elle-même.
          return http.Response(
            '',
            301,
            headers: {'location': 'https://vm.tiktok.com/loop/'},
          );
        });
        final provider = TiktokProvider(httpClient: mockClient);

        final metadata = await provider.fetchMetadata(
          'https://vm.tiktok.com/loop/',
        );

        expect(metadata.canonicalUrl, isNotNull);
      },
    );
  });
}
