import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../models/video_source.dart';
import '../../../utils/source_detector.dart';
import '../video_metadata.dart';
import 'metadata_provider.dart';
import 'og_tag_scraper.dart';

/// Fournisseur de métadonnées pour les posts X (Twitter).
///
/// Le titre provient exclusivement de l'endpoint oEmbed officiel
/// (`https://publish.twitter.com/oembed`, aucune clé d'API requise) — source
/// fiable, jamais remplacée par un titre scrapé. La miniature, elle, est un
/// bonus complémentaire best-effort : l'oEmbed officiel n'en fournit aucune
/// (voir DECISIONS.md, entrée "Tâche 7"), donc un scraping `og:image` de la
/// page du post est tenté en plus via [OgTagScraper] (voir DECISIONS.md,
/// entrée "Tâche 17", qui remplace ce choix initial) — X bloquant
/// fréquemment ce type de requête automatisée, cet échec reste silencieux et
/// n'affecte jamais `isPartial`.
class TwitterProvider implements MetadataProvider {
  /// Crée le provider. [httpClient] est injectable pour les tests (mock des
  /// réponses HTTP) ; par défaut un `http.Client()` réel est utilisé.
  TwitterProvider({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client(),
      _thumbnailScraper = OgTagScraper(
        httpClient: httpClient,
        timeout: const Duration(seconds: 2),
      );

  static const _oembedEndpoint = 'https://publish.twitter.com/oembed';

  final http.Client _httpClient;

  /// Timeout dédié court, indépendant de l'appel oEmbed déjà effectué, pour
  /// ne jamais faire dépasser le budget global de 5s de `MetadataService`
  /// (voir SPEC.md section 9) si seul ce scraping complémentaire traîne.
  final OgTagScraper _thumbnailScraper;

  @override
  bool canHandle(String url) => SourceDetector.detect(url) == VideoSource.twitter;

  @override
  Future<VideoMetadata> fetchMetadata(String url) async {
    final oembedUri = Uri.parse(
      _oembedEndpoint,
    ).replace(queryParameters: {'url': url});

    final response = await _httpClient.get(oembedUri);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Réponse oEmbed X (Twitter) invalide : ${response.statusCode}',
        oembedUri,
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final authorName = body['author_name'] as String?;

    // Scraping complémentaire best-effort : ne fournit jamais le titre
    // (toujours l'oEmbed ci-dessus) et ne fait jamais échouer le provider —
    // `OgTagScraper.scrape` ne lève aucune exception, retourne simplement
    // une image absente (page bloquée, connexion requise, structure
    // absente, cas fréquent sur X).
    final thumbnailTags = await _thumbnailScraper.scrape(url);

    return VideoMetadata(
      title: authorName != null ? 'Post de $authorName sur X' : 'Post X (Twitter)',
      thumbnailUrl: thumbnailTags.imageUrl,
      source: VideoSource.twitter,
      isPartial: false,
    );
  }
}
