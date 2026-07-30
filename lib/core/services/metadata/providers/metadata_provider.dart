import '../video_metadata.dart';

/// Interface commune à tout fournisseur de métadonnées spécifique à une
/// plateforme (YouTube, TikTok, et futures plateformes de la Tâche 7).
///
/// Chaque implémentation ne connaît que sa propre plateforme — aucune
/// référence croisée entre providers (voir SPEC.md section 5). Le choix du
/// provider adapté et la gestion du fallback en cas d'échec sont de la seule
/// responsabilité de `MetadataService`.
abstract class MetadataProvider {
  /// Vrai si ce provider sait traiter [url] (généralement basé sur le
  /// domaine, voir `SourceDetector`).
  bool canHandle(String url);

  /// Récupère les métadonnées de la vidéo à [url]. Peut lever une exception
  /// (réseau, réponse invalide) — c'est à l'appelant (`MetadataService`) de
  /// gérer le repli vers le fallback générique.
  Future<VideoMetadata> fetchMetadata(String url);
}
