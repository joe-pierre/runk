import '../../models/video_source.dart';

/// Métadonnées récupérées automatiquement pour une vidéo partagée.
///
/// Résultat produit par un `MetadataProvider` ou par `MetadataService`.
/// Distinct du futur modèle applicatif `VideoBookmark` (Tâche 5) : ne
/// contient que ce qui provient de la récupération automatique, pas les
/// champs propres à la persistance (id, tags, note, dates).
class VideoMetadata {
  /// Crée des métadonnées de vidéo. [title] ne doit jamais être vide — un
  /// titre par défaut est fourni par `GenericFallbackProvider` si la
  /// récupération automatique échoue.
  const VideoMetadata({
    required this.title,
    required this.source,
    required this.isPartial,
    this.thumbnailUrl,
    this.canonicalUrl,
  });

  /// Titre de la vidéo, récupéré automatiquement ou titre par défaut.
  final String title;

  /// URL de l'image de prévisualisation, ou `null` si indisponible.
  final String? thumbnailUrl;

  /// Plateforme d'origine détectée.
  final VideoSource source;

  /// Vrai si les métadonnées n'ont pas pu être récupérées entièrement (voir
  /// SPEC.md section 4 règle 3 — dégradation propre, jamais de blocage).
  final bool isPartial;

  /// URL longue résolue après suivi des redirections HTTP de l'URL
  /// d'origine, ou `null` si non résolue (voir DECISIONS.md, entrée « Tâche
  /// 31 »). Seul `TiktokProvider` la renseigne pour l'instant — nécessaire
  /// pour construire un deep link natif précis à partir d'un lien court
  /// `vm.tiktok.com` (voir Tâche 16), qui ne contient pas l'identifiant
  /// vidéo.
  final String? canonicalUrl;
}
