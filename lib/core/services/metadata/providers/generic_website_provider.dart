import 'package:http/http.dart' as http;

import '../../../models/video_source.dart';
import '../video_metadata.dart';
import 'metadata_provider.dart';
import 'og_tag_scraper.dart';

/// Fournisseur de métadonnées pour tout site web qui n'est ni l'une des 6
/// plateformes vidéo connues, ni Google Maps (Tâche 39, périmètre séparé),
/// par scraping des balises Open Graph (`og:title`/`og:image`) — même
/// technique qu'Instagram/Facebook/Threads (voir SPEC.md section 8).
///
/// Doit rester le dernier provider consulté par `MetadataService` : son
/// `canHandle` accepte toute URL `http`/`https` valide, ce qui ferait de
/// l'ombre aux 6 providers spécifiques s'il était placé avant eux.
///
/// Aucune exception de scraping ne remonte jamais à l'appelant : tout échec
/// (réseau, timeout, balise `og:title` absente) produit directement un
/// résultat `isPartial: true` depuis ce provider, plutôt que de compter sur
/// le fallback de `MetadataService` (voir DECISIONS.md, entrée "Tâche 7").
class GenericWebsiteProvider implements MetadataProvider {
  /// Crée le provider. [httpClient] est injectable pour les tests (mock des
  /// réponses HTTP) ; par défaut un `http.Client()` réel est utilisé.
  GenericWebsiteProvider({http.Client? httpClient})
    : _scraper = OgTagScraper(httpClient: httpClient);

  final OgTagScraper _scraper;

  /// Titre par défaut attribué quand la récupération automatique échoue —
  /// propre à ce provider, distinct de `GenericFallbackProvider.defaultTitle`
  /// (voir DECISIONS.md, entrée "Tâche 7", pour la justification de cette
  /// distinction).
  static const defaultTitle = 'Page web sans titre';

  @override
  bool canHandle(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  @override
  Future<VideoMetadata> fetchMetadata(String url) async {
    final tags = await _scraper.scrape(url);
    final title = tags.title;
    if (title == null) {
      return const VideoMetadata(
        title: defaultTitle,
        thumbnailUrl: null,
        source: VideoSource.website,
        isPartial: true,
      );
    }

    return VideoMetadata(
      title: title,
      thumbnailUrl: tags.imageUrl,
      source: VideoSource.website,
      isPartial: false,
    );
  }
}
