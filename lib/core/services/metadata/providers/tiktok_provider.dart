import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../models/video_source.dart';
import '../../../utils/source_detector.dart';
import '../video_metadata.dart';
import 'metadata_provider.dart';

/// Fournisseur de métadonnées pour les vidéos TikTok, via l'endpoint oEmbed
/// officiel (`https://www.tiktok.com/oembed`) — aucune clé d'API requise.
class TiktokProvider implements MetadataProvider {
  /// Crée le provider. [httpClient] est injectable pour les tests (mock des
  /// réponses HTTP) ; par défaut un `http.Client()` réel est utilisé.
  TiktokProvider({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static const _oembedEndpoint = 'https://www.tiktok.com/oembed';

  final http.Client _httpClient;

  @override
  bool canHandle(String url) => SourceDetector.detect(url) == VideoSource.tiktok;

  @override
  Future<VideoMetadata> fetchMetadata(String url) async {
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
}
