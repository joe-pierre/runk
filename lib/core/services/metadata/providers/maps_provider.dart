import 'package:http/http.dart' as http;

import '../../../models/video_source.dart';
import '../../../utils/source_detector.dart';
import '../video_metadata.dart';
import 'metadata_provider.dart';
import 'og_tag_scraper.dart';

/// Fournisseur de métadonnées pour les liens de lieu/itinéraire Google Maps
/// (Tâche 39), par scraping du seul `og:title` — jamais `og:image`.
///
/// Contrairement à tous les autres providers, l'absence de miniature n'est
/// **pas** une dégradation : c'est une décision produit assumée (voir
/// DECISIONS.md, entrée "Tâche 39"). Les pages Google Maps sont fortement
/// rendues en JavaScript côté client, sans `og:image` exploitable de façon
/// fiable par scraping, et l'API Static Maps (payante, à clé) est
/// volontairement hors périmètre. `fetchMetadata` n'extrait donc jamais
/// `OgTags.imageUrl`, même quand il est présent dans la réponse — pas
/// seulement en cas d'échec.
///
/// Aucune exception de scraping ne remonte jamais à l'appelant, même
/// pattern que les autres providers basés sur `OgTagScraper` (voir
/// DECISIONS.md, entrée "Tâche 7").
class MapsProvider implements MetadataProvider {
  /// Crée le provider. [httpClient] est injectable pour les tests (mock des
  /// réponses HTTP) ; par défaut un `http.Client()` réel est utilisé.
  MapsProvider({http.Client? httpClient})
    : _scraper = OgTagScraper(httpClient: httpClient);

  final OgTagScraper _scraper;

  /// Titre par défaut attribué quand la récupération automatique du titre
  /// échoue — propre à ce provider, distinct de
  /// `GenericFallbackProvider.defaultTitle` (voir DECISIONS.md, entrée
  /// "Tâche 7", pour la justification de cette distinction).
  static const defaultTitle = 'Lieu sans titre';

  @override
  bool canHandle(String url) => SourceDetector.detect(url) == VideoSource.maps;

  @override
  Future<VideoMetadata> fetchMetadata(String url) async {
    final tags = await _scraper.scrape(url);
    final title = tags.title;
    if (title == null) {
      return const VideoMetadata(
        title: defaultTitle,
        thumbnailUrl: null,
        source: VideoSource.maps,
        isPartial: true,
      );
    }

    return VideoMetadata(
      title: title,
      thumbnailUrl: null,
      source: VideoSource.maps,
      isPartial: false,
    );
  }
}
