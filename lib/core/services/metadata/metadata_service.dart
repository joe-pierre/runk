import 'dart:async';

import 'providers/generic_fallback_provider.dart';
import 'providers/metadata_provider.dart';
import 'providers/tiktok_provider.dart';
import 'providers/youtube_provider.dart';
import 'video_metadata.dart';

/// Orchestrateur unique de récupération de métadonnées vidéo.
///
/// Sélectionne le provider adapté à l'URL via `canHandle`, applique un
/// timeout (5s par défaut, voir SPEC.md section 9) et bascule vers
/// `GenericFallbackProvider` en cas d'exception, de timeout, ou si aucun
/// provider ne gère l'URL.
///
/// N'orchestre que : aucune logique de scraping ou d'appel réseau
/// spécifique à une plateforme ne doit vivre ici (voir SPEC.md section 5 —
/// cette logique vit exclusivement dans chaque `*_provider.dart`).
class MetadataService {
  /// Crée le service. [providers] par défaut : YouTube puis TikTok (Tâche 4
  /// — les autres plateformes seront ajoutées à cette liste en Tâche 7,
  /// sans autre modification de ce fichier, voir SPEC.md section 8).
  /// [fallbackProvider] et [timeout] sont injectables pour les tests.
  MetadataService({
    List<MetadataProvider>? providers,
    MetadataProvider? fallbackProvider,
    Duration timeout = const Duration(seconds: 5),
  }) : _providers = providers ?? [YoutubeProvider(), TiktokProvider()],
       _fallbackProvider = fallbackProvider ?? GenericFallbackProvider(),
       _timeout = timeout;

  final List<MetadataProvider> _providers;
  final MetadataProvider _fallbackProvider;
  final Duration _timeout;

  /// Récupère les métadonnées de la vidéo à [url].
  ///
  /// Retourne toujours un [VideoMetadata] exploitable, jamais d'exception :
  /// si aucun provider ne gère [url], ou si le provider sélectionné échoue
  /// (exception réseau) ou dépasse [_timeout], le résultat du
  /// [_fallbackProvider] est retourné à la place.
  Future<VideoMetadata> fetch(String url) async {
    final provider = _selectProvider(url);
    if (provider == null) {
      return _fallbackProvider.fetchMetadata(url);
    }

    try {
      // `TimeoutException` (levée par `.timeout()`) implémente `Exception` :
      // une seule clause suffit à couvrir échec réseau et dépassement du
      // timeout.
      return await provider.fetchMetadata(url).timeout(_timeout);
    } on Exception {
      return _fallbackProvider.fetchMetadata(url);
    }
  }

  MetadataProvider? _selectProvider(String url) {
    for (final provider in _providers) {
      if (provider.canHandle(url)) return provider;
    }
    return null;
  }
}
