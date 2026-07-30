import 'package:http/http.dart' as http;

/// Résultat brut de l'extraction des balises Open Graph d'une page HTML.
///
/// Les deux champs sont `null` si la balise correspondante est absente —
/// distinct d'une chaîne vide, qui signifierait que la balise existe mais
/// contient un contenu vide.
class OgTags {
  /// Crée un résultat d'extraction. Les deux champs sont optionnels : une
  /// page peut exposer `og:title` sans `og:image`, ou aucun des deux.
  const OgTags({this.title, this.imageUrl});

  /// Contenu de la balise `og:title`, ou `null` si absente.
  final String? title;

  /// Contenu de la balise `og:image`, ou `null` si absente.
  final String? imageUrl;
}

/// Utilitaire partagé de scraping des balises Open Graph (`og:title`,
/// `og:image`) d'une page HTML.
///
/// Utilisé par les providers reposant sur le scraping plutôt qu'un endpoint
/// oEmbed officiel (Instagram, Facebook, Threads — voir SPEC.md section 8) :
/// l'extraction des balises `og:` est identique quelle que soit la
/// plateforme, seule l'URL interrogée diffère (propre à chaque provider).
/// Ce n'est pas un `MetadataProvider` lui-même — comparable à
/// `SourceDetector`, un utilitaire de bas niveau partagé, pas une référence
/// croisée entre providers.
class OgTagScraper {
  /// Crée le scraper. [httpClient] est injectable pour les tests (mock des
  /// réponses HTTP) ; par défaut un `http.Client()` réel est utilisé.
  /// [timeout] est volontairement court (voir SPEC.md section 9) puisque le
  /// scraping HTML est moins fiable qu'un endpoint oEmbed officiel.
  OgTagScraper({http.Client? httpClient, Duration timeout = const Duration(seconds: 3)})
    : _httpClient = httpClient ?? http.Client(),
      _timeout = timeout;

  final http.Client _httpClient;
  final Duration _timeout;

  static final _metaTagPattern = RegExp('<meta[^>]*>', caseSensitive: false);
  static final _contentAttributePattern = RegExp(
    '''content=["']([^"']*)["']''',
    caseSensitive: false,
  );

  /// Récupère et parse les balises `og:title`/`og:image` de la page [url].
  ///
  /// Ne lève **jamais** d'exception : toute requête en échec (réseau, code
  /// HTTP hors succès, dépassement de [timeout]) retourne un [OgTags] vide,
  /// à charge pour l'appelant de traiter cette absence comme un échec
  /// partiel (voir SPEC.md section 4 règle 3).
  Future<OgTags> scrape(String url) async {
    try {
      final response = await _httpClient.get(Uri.parse(url)).timeout(_timeout);
      if (response.statusCode != 200) return const OgTags();

      return OgTags(
        title: _extractProperty(response.body, 'og:title'),
        imageUrl: _extractProperty(response.body, 'og:image'),
      );
    } on Exception {
      return const OgTags();
    }
  }

  /// Extrait le `content` de la première balise `<meta>` dont l'attribut
  /// `property` vaut [property], quel que soit l'ordre des attributs dans
  /// le tag (les plateformes scrapées ne le garantissent pas).
  static String? _extractProperty(String html, String property) {
    for (final match in _metaTagPattern.allMatches(html)) {
      final tag = match.group(0)!;
      if (!tag.contains('property="$property"') &&
          !tag.contains("property='$property'")) {
        continue;
      }
      final content = _contentAttributePattern.firstMatch(tag)?.group(1);
      if (content != null) return content;
    }
    return null;
  }
}
