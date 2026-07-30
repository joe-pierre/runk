import 'package:flutter_test/flutter_test.dart';
import 'package:runk/core/models/video_source.dart';
import 'package:runk/core/services/metadata/metadata_service.dart';
import 'package:runk/core/services/metadata/providers/generic_fallback_provider.dart';
import 'package:runk/core/services/metadata/providers/metadata_provider.dart';
import 'package:runk/core/services/metadata/video_metadata.dart';

/// Provider de test toujours capable de traiter l'URL, dont le comportement
/// de [fetchMetadata] est piloté par le test (succès, exception ou délai).
class _FakeProvider implements MetadataProvider {
  _FakeProvider({
    this.throwsOnFetch = false,
    this.delay = Duration.zero,
    this.result,
  });

  final bool throwsOnFetch;
  final Duration delay;
  final VideoMetadata? result;

  @override
  bool canHandle(String url) => true;

  @override
  Future<VideoMetadata> fetchMetadata(String url) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (throwsOnFetch) {
      throw Exception('échec réseau simulé');
    }
    return result!;
  }
}

void main() {
  group('MetadataService', () {
    test('retourne le résultat du provider sélectionné quand il réussit', () async {
      const expected = VideoMetadata(
        title: 'Titre trouvé',
        thumbnailUrl: 'https://exemple.com/thumb.jpg',
        source: VideoSource.youtube,
        isPartial: false,
      );
      final service = MetadataService(
        providers: [_FakeProvider(result: expected)],
      );

      final metadata = await service.fetch('https://www.youtube.com/watch?v=abc');

      expect(metadata, same(expected));
    });

    test('bascule vers le fallback si le provider principal lève une exception', () async {
      final service = MetadataService(
        providers: [_FakeProvider(throwsOnFetch: true)],
      );

      final metadata = await service.fetch('https://www.youtube.com/watch?v=abc');

      expect(metadata.isPartial, isTrue);
      expect(metadata.title, GenericFallbackProvider.defaultTitle);
    });

    test('bascule vers le fallback si le provider principal dépasse le timeout', () async {
      final service = MetadataService(
        providers: [_FakeProvider(delay: const Duration(milliseconds: 50))],
        timeout: const Duration(milliseconds: 10),
      );

      final metadata = await service.fetch('https://www.youtube.com/watch?v=abc');

      expect(metadata.isPartial, isTrue);
      expect(metadata.title, GenericFallbackProvider.defaultTitle);
    });

    test('bascule vers le fallback si aucun provider ne gère l\'URL', () async {
      final service = MetadataService(providers: const []);

      final metadata = await service.fetch('https://exemple-non-supporte.com/x');

      expect(metadata.isPartial, isTrue);
      expect(metadata.title, GenericFallbackProvider.defaultTitle);
      expect(metadata.source, VideoSource.unknown);
    });
  });
}
