import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'metadata_service.dart';
import 'video_metadata.dart';

part 'metadata_service_provider.g.dart';

/// Instance unique de [MetadataService] pour toute l'application.
///
/// `keepAlive: true` : le service n'a aucun état par requête, pas de raison
/// de le recréer entre deux ouvertures de `AddBookmarkSheet`.
@Riverpod(keepAlive: true)
MetadataService metadataService(Ref ref) => MetadataService();

/// Récupère les métadonnées de la vidéo à [url] via [metadataServiceProvider].
///
/// Provider `family` `autoDispose` (par défaut) : chaque URL a son propre
/// résultat, libéré dès que plus aucun widget ne l'écoute (ex: fermeture de
/// `AddBookmarkSheet`).
@riverpod
Future<VideoMetadata> videoMetadata(Ref ref, String url) {
  return ref.watch(metadataServiceProvider).fetch(url);
}
