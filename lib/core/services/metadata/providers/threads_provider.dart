import 'package:http/http.dart' as http;

import '../../../models/video_source.dart';
import '../../../utils/source_detector.dart';
import '../video_metadata.dart';
import 'metadata_provider.dart';
import 'og_tag_scraper.dart';

/// Fournisseur de métadonnées pour les vidéos Threads, par scraping des
/// balises Open Graph (`og:title`/`og:image`) — Threads n'expose aucun
/// endpoint oEmbed public fiable pour ce contenu (voir SPEC.md section 8).
///
/// Aucune exception de scraping ne remonte jamais à l'appelant : tout échec
/// (réseau, timeout, balise `og:title` absente) produit directement un
/// résultat `isPartial: true` depuis ce provider, plutôt que de compter sur
/// le fallback de `MetadataService` (voir DECISIONS.md, entrée "Tâche 7").
/// `isPartial: true` est un résultat **fréquent et attendu** pour Threads,
/// pas un bug.
class ThreadsProvider implements MetadataProvider {
  /// Crée le provider. [httpClient] est injectable pour les tests (mock des
  /// réponses HTTP) ; par défaut un `http.Client()` réel est utilisé.
  ThreadsProvider({http.Client? httpClient})
    : _scraper = OgTagScraper(httpClient: httpClient);

  final OgTagScraper _scraper;

  @override
  bool canHandle(String url) => SourceDetector.detect(url) == VideoSource.threads;

  @override
  Future<VideoMetadata> fetchMetadata(String url) async {
    final tags = await _scraper.scrape(url);
    final title = tags.title;
    if (title == null) {
      return const VideoMetadata(
        title: 'Vidéo Threads sans titre',
        thumbnailUrl: null,
        source: VideoSource.threads,
        isPartial: true,
      );
    }

    return VideoMetadata(
      title: title,
      thumbnailUrl: tags.imageUrl,
      source: VideoSource.threads,
      isPartial: false,
    );
  }
}
