import 'package:flutter_test/flutter_test.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/core/services/deep_link_service.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  group('DeepLinkService', () {
    test(
      'ouvre le schéma natif quand une app le gère (Instagram)',
      () async {
        final launchedUris = <Uri>[];
        final service = DeepLinkService(
          canLaunchUrl: (uri) async => uri.scheme == 'instagram',
          launchUrl: (uri, {mode = LaunchMode.platformDefault}) async {
            launchedUris.add(uri);
            return true;
          },
        );

        final opened = await service.openInSource(
          'https://www.instagram.com/p/abc123/',
          VideoSource.instagram,
        );

        expect(opened, isTrue);
        expect(launchedUris, [
          Uri.parse('instagram://www.instagram.com/p/abc123/'),
        ]);
      },
    );

    test(
      'construit le schéma natif TikTok avec l\'id vidéo (lien long)',
      () async {
        final launchedUris = <Uri>[];
        final service = DeepLinkService(
          canLaunchUrl: (uri) async => true,
          launchUrl: (uri, {mode = LaunchMode.platformDefault}) async {
            launchedUris.add(uri);
            return true;
          },
        );

        final opened = await service.openInSource(
          'https://www.tiktok.com/@user/video/1234567890123456789',
          VideoSource.tiktok,
        );

        expect(opened, isTrue);
        expect(launchedUris, [
          Uri.parse('snssdk1233://aweme/detail/1234567890123456789?refer=web'),
        ]);
      },
    );

    test(
      'bascule vers le navigateur si le lancement du schéma natif échoue',
      () async {
        final launchedUris = <Uri>[];
        final service = DeepLinkService(
          canLaunchUrl: (uri) async => true,
          launchUrl: (uri, {mode = LaunchMode.platformDefault}) async {
            launchedUris.add(uri);
            return uri.scheme != 'twitter';
          },
        );

        final opened = await service.openInSource(
          'https://x.com/user/status/123',
          VideoSource.twitter,
        );

        expect(opened, isTrue);
        expect(launchedUris, [
          Uri.parse('twitter://status?id=123'),
          Uri.parse('https://x.com/user/status/123'),
        ]);
      },
    );

    test(
      'construit le schéma natif X/Twitter avec l\'id du statut, quel que soit l\'hôte',
      () async {
        for (final url in [
          'https://twitter.com/user/status/1234567890',
          'https://x.com/user/status/1234567890',
          'https://mobile.twitter.com/user/status/1234567890',
        ]) {
          final launchedUris = <Uri>[];
          final service = DeepLinkService(
            canLaunchUrl: (uri) async => true,
            launchUrl: (uri, {mode = LaunchMode.platformDefault}) async {
              launchedUris.add(uri);
              return true;
            },
          );

          final opened = await service.openInSource(url, VideoSource.twitter);

          expect(opened, isTrue);
          expect(launchedUris, [Uri.parse('twitter://status?id=1234567890')]);
        }
      },
    );

    test(
      'bascule vers le navigateur si le lien TikTok court n\'est pas résolu (pas d\'id extractible)',
      () async {
        final launchedUris = <Uri>[];
        final service = DeepLinkService(
          canLaunchUrl: (uri) async => true,
          launchUrl: (uri, {mode = LaunchMode.platformDefault}) async {
            launchedUris.add(uri);
            return true;
          },
        );

        final opened = await service.openInSource(
          'https://vm.tiktok.com/ZMabcdefg/',
          VideoSource.tiktok,
        );

        expect(opened, isTrue);
        expect(launchedUris, [
          Uri.parse('https://vm.tiktok.com/ZMabcdefg/'),
        ]);
      },
    );

    test(
      'bascule vers le navigateur si canLaunchUrl lève une exception',
      () async {
        final launchedUris = <Uri>[];
        final service = DeepLinkService(
          canLaunchUrl: (uri) async => throw Exception('canal indisponible'),
          launchUrl: (uri, {mode = LaunchMode.platformDefault}) async {
            launchedUris.add(uri);
            return true;
          },
        );

        final opened = await service.openInSource(
          'https://www.facebook.com/watch/?v=123',
          VideoSource.facebook,
        );

        expect(opened, isTrue);
        expect(launchedUris, [
          Uri.parse('https://www.facebook.com/watch/?v=123'),
        ]);
      },
    );

    test(
      'passe directement au navigateur pour Threads (aucun schéma natif connu)',
      () async {
        final launchedUris = <Uri>[];
        final service = DeepLinkService(
          canLaunchUrl: (uri) async => true,
          launchUrl: (uri, {mode = LaunchMode.platformDefault}) async {
            launchedUris.add(uri);
            return true;
          },
        );

        final opened = await service.openInSource(
          'https://www.threads.net/@user/post/123',
          VideoSource.threads,
        );

        expect(opened, isTrue);
        expect(launchedUris, [
          Uri.parse('https://www.threads.net/@user/post/123'),
        ]);
      },
    );

    test(
      'retourne false sans planter si ni le schéma natif ni le navigateur ne fonctionnent',
      () async {
        final service = DeepLinkService(
          canLaunchUrl: (uri) async => true,
          launchUrl: (uri, {mode = LaunchMode.platformDefault}) async => false,
        );

        final opened = await service.openInSource(
          'https://www.instagram.com/p/abc123/',
          VideoSource.instagram,
        );

        expect(opened, isFalse);
      },
    );

    test(
      'retourne false sans planter si le repli navigateur lève une exception',
      () async {
        final service = DeepLinkService(
          canLaunchUrl: (uri) async => false,
          launchUrl: (uri, {mode = LaunchMode.platformDefault}) async =>
              throw Exception('aucun navigateur disponible'),
        );

        final opened = await service.openInSource(
          'https://www.youtube.com/watch?v=abc123',
          VideoSource.youtube,
        );

        expect(opened, isFalse);
      },
    );

    test(
      'construit le schéma natif Facebook via facewebmodal, pas la reconstruction générique',
      () async {
        final launchedUris = <Uri>[];
        final service = DeepLinkService(
          canLaunchUrl: (uri) async => true,
          launchUrl: (uri, {mode = LaunchMode.platformDefault}) async {
            launchedUris.add(uri);
            return true;
          },
        );

        await service.openInSource(
          'https://www.facebook.com/watch/?v=123',
          VideoSource.facebook,
        );

        expect(launchedUris, [
          Uri.parse(
            'fb://facewebmodal/f?href=https://www.facebook.com/watch/?v=123',
          ),
        ]);
      },
    );
  });
}
