import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../models/video_source.dart';
import '../../../utils/source_detector.dart';
import '../video_metadata.dart';
import 'metadata_provider.dart';

/// Fournisseur de métadonnées pour les vidéos TikTok, via l'endpoint oEmbed
/// officiel (`https://www.tiktok.com/oembed`) — aucune clé d'API requise.
///
/// Tente aussi de résoudre l'URL longue canonique de la vidéo (voir
/// DECISIONS.md, entrée « Tâche 31 ») : un lien court `vm.tiktok.com`
/// (fréquent depuis TikTok Lite, voir Tâche 16) ne contient pas
/// l'identifiant vidéo, présent uniquement dans l'URL obtenue après
/// résolution de la redirection HTTP. Cette résolution tourne en parallèle
/// de l'appel oEmbed et n'échoue jamais bruyamment : tout échec ou timeout
/// laisse simplement `VideoMetadata.canonicalUrl` à `null`, sans affecter le
/// résultat de l'appel oEmbed.
class TiktokProvider implements MetadataProvider {
  /// Crée le provider. [httpClient] est injectable pour les tests (mock des
  /// réponses HTTP) ; par défaut un `http.Client()` réel est utilisé.
  TiktokProvider({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static const _oembedEndpoint = 'https://www.tiktok.com/oembed';

  /// Nombre maximum de sauts de redirection suivis avant d'abandonner la
  /// résolution — évite une boucle infinie sur une chaîne de redirections
  /// malformée ou cyclique.
  static const _maxRedirectHops = 5;

  /// Timeout dédié à la résolution de l'URL canonique, volontairement plus
  /// court que le timeout global de `MetadataService` (5s, voir SPEC.md
  /// section 9) : la résolution tourne en parallèle de l'appel oEmbed, ce
  /// délai plus court laisse de la marge pour ne jamais faire échouer tout
  /// `fetchMetadata` à cause d'un lien court TikTok qui traîne à répondre.
  static const _canonicalUrlResolutionTimeout = Duration(seconds: 3);

  final http.Client _httpClient;

  @override
  bool canHandle(String url) => SourceDetector.detect(url) == VideoSource.tiktok;

  @override
  Future<VideoMetadata> fetchMetadata(String url) async {
    // Lancées ensemble (avant le premier `await`) pour s'exécuter en
    // parallèle : la résolution de l'URL canonique ne doit pas allonger le
    // temps de réponse global au-delà de ce que l'appel oEmbed prend déjà.
    final oembedFuture = _fetchOembedMetadata(url);
    final canonicalUrlFuture = _resolveCanonicalUrl(url);

    final metadata = await oembedFuture;
    final canonicalUrl = await canonicalUrlFuture;

    return VideoMetadata(
      title: metadata.title,
      thumbnailUrl: metadata.thumbnailUrl,
      source: metadata.source,
      isPartial: metadata.isPartial,
      canonicalUrl: canonicalUrl,
    );
  }

  Future<VideoMetadata> _fetchOembedMetadata(String url) async {
    final oembedUri = Uri.parse(
      _oembedEndpoint,
    ).replace(queryParameters: {'url': url});

    final response = await _httpClient.get(oembedUri);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Réponse oEmbed TikTok invalide : ${response.statusCode}',
        oembedUri,
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return VideoMetadata(
      title: body['title'] as String,
      thumbnailUrl: body['thumbnail_url'] as String?,
      source: VideoSource.tiktok,
      isPartial: false,
    );
  }

  /// Résout l'URL longue en suivant manuellement les redirections HTTP
  /// (`Location` des réponses 3xx) depuis [url] — jamais via le suivi
  /// automatique d'un client HTTP, pour rester déterministe et testable via
  /// `MockClient`. Retourne `null` si la résolution échoue, dépasse
  /// [_canonicalUrlResolutionTimeout], ou dépasse [_maxRedirectHops] —
  /// jamais d'exception remontée à l'appelant.
  Future<String?> _resolveCanonicalUrl(String url) async {
    try {
      return await _followRedirects(
        url,
      ).timeout(_canonicalUrlResolutionTimeout);
    } on Exception {
      return null;
    }
  }

  Future<String> _followRedirects(String url) async {
    var currentUri = Uri.parse(url);
    for (var hop = 0; hop < _maxRedirectHops; hop++) {
      final request = http.Request('GET', currentUri)
        ..followRedirects = false;
      final streamedResponse = await _httpClient.send(request);
      await streamedResponse.stream.drain<void>();

      final isRedirect =
          streamedResponse.statusCode >= 300 &&
          streamedResponse.statusCode < 400;
      if (!isRedirect) return currentUri.toString();

      final location = streamedResponse.headers['location'];
      if (location == null) return currentUri.toString();
      currentUri = currentUri.resolve(location);
    }
    return currentUri.toString();
  }
}
