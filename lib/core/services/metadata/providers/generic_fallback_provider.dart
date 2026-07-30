import '../../../utils/source_detector.dart';
import '../video_metadata.dart';
import 'metadata_provider.dart';

/// Fournisseur de repli utilisé par `MetadataService` lorsque aucun provider
/// spécifique ne gère l'URL, ou que le provider adapté échoue (exception ou
/// timeout).
///
/// Ne bloque jamais l'utilisateur (voir SPEC.md section 4 règle 3) : retourne
/// toujours un résultat exploitable, marqué `isPartial: true`, avec un titre
/// par défaut modifiable manuellement par l'utilisateur.
class GenericFallbackProvider implements MetadataProvider {
  /// Titre par défaut attribué quand la récupération automatique échoue.
  static const defaultTitle = 'Vidéo sans titre';

  /// Toujours vrai : ce provider est le repli universel, appelé
  /// explicitement par `MetadataService`, jamais via la sélection normale
  /// par `canHandle` des autres providers.
  @override
  bool canHandle(String url) => true;

  @override
  Future<VideoMetadata> fetchMetadata(String url) async {
    return VideoMetadata(
      title: defaultTitle,
      thumbnailUrl: null,
      source: SourceDetector.detect(url),
      isPartial: true,
    );
  }
}
