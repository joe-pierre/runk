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
    this.isHidden = false,
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

  /// Vrai si ce bookmark est masqué dans la section "My Eyes Only" (Tâche
  /// 22, voir DECISIONS.md) : n'apparaît alors plus dans `HomeScreen`, mais
  /// reste synchronisé avec Supabase comme n'importe quel autre champ (voir
  /// `BookmarkRepository`) — seul le code d'accès local ne l'est jamais.
  final bool isHidden;

  /// Tags associés par l'utilisateur.
  final List<String> tags;

  /// Date de création du bookmark.
  final DateTime createdAt;

  /// Date de dernière modification du bookmark.
  final DateTime updatedAt;

  /// Note libre optionnelle.
  final String? note;

  /// Retourne une copie de ce bookmark, en remplaçant uniquement les champs
  /// fournis — utilisé notamment par `bookmark_context_menu.dart` pour
  /// modifier les tags sans altérer les autres champs avant de les
  /// transmettre à `BookmarkRepository.updateBookmark`.
  VideoBookmark copyWith({
    String? title,
    String? thumbnailUrl,
    bool? isPartial,
    bool? isHidden,
    List<String>? tags,
    String? note,
  }) {
    return VideoBookmark(
      id: id,
      url: url,
      title: title ?? this.title,
      source: source,
      createdAt: createdAt,
      updatedAt: updatedAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isPartial: isPartial ?? this.isPartial,
      isHidden: isHidden ?? this.isHidden,
      tags: tags ?? this.tags,
      note: note ?? this.note,
    );
  }
}
