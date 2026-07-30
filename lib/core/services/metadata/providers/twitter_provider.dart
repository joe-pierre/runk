import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../models/video_source.dart';
import '../../../utils/source_detector.dart';
import '../video_metadata.dart';
import 'metadata_provider.dart';

/// Fournisseur de métadonnées pour les posts X (Twitter), via l'endpoint
/// oEmbed officiel (`https://publish.twitter.com/oembed`) — aucune clé d'API
/// requise.
class TwitterProvider implements MetadataProvider {
  /// Crée le provider. [httpClient] est injectable pour les tests (mock des
  /// réponses HTTP) ; par défaut un `http.Client()` réel est utilisé.
  TwitterProvider({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static const _oembedEndpoint = 'https://publish.twitter.com/oembed';

  final http.Client _httpClient;

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
    return VideoMetadata(
      title: authorName != null ? 'Post de $authorName sur X' : 'Post X (Twitter)',
      // L'oEmbed officiel de X/Twitter ne renvoie aucune image de
      // prévisualisation (contrairement à YouTube/TikTok, voir
      // DECISIONS.md, entrée "Tâche 7") : `thumbnailUrl` reste `null`, ce
      // qui n'est pas traité comme un échec (`isPartial` reste `false`),
      // puisque le titre a bien été récupéré via l'endpoint officiel.
      thumbnailUrl: null,
      source: VideoSource.twitter,
      isPartial: false,
    );
  }
}
