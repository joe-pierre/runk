import '../../../core/models/video_source.dart';

/// Modèle applicatif pur d'une vidéo sauvegardée dans Runk.
///
/// Ne dépend d'aucune technologie de persistance (Isar) ni de backend
/// (Supabase) — voir SPEC.md section 3.1. Le mapping vers/depuis ces
/// technologies vit exclusivement dans `features/bookmarks/data/` (voir
/// `BookmarkRepository`).
class VideoBookmark {
  /// Crée un bookmark. [title] ne doit jamais être vide (validé en amont,
  /// voir CONVENTIONS.md section Validation).
  const VideoBookmark({
    required this.id,
    required this.url,
    required this.title,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailUrl,
    this.isPartial = false,
    this.tags = const [],
    this.note,
  });

  /// Identifiant unique, généré côté client (UUID) — sert aussi de clé
  /// primaire côté Supabase (`bookmarks.id`).
  final String id;

  /// URL originale partagée par l'utilisateur.
  final String url;

  /// Titre auto-récupéré ou saisi manuellement par l'utilisateur.
  final String title;

  /// URL de l'image de prévisualisation, ou `null` si indisponible.
  final String? thumbnailUrl;

  /// Plateforme d'origine détectée (voir `SourceDetector`).
  final VideoSource source;

  /// Vrai si les métadonnées n'ont pas pu être récupérées entièrement (voir
  /// SPEC.md section 4 règle 3).
  final bool isPartial;

  /// Tags associés par l'utilisateur.
  final List<String> tags;

  /// Date de création du bookmark.
  final DateTime createdAt;

  /// Date de dernière modification du bookmark.
  final DateTime updatedAt;

  /// Note libre optionnelle.
  final String? note;
}
