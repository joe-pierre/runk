/// Plateforme d'origine d'une vidéo partagée vers Runk.
///
/// Détectée automatiquement à partir du domaine de l'URL partagée (voir
/// `SourceDetector`, jamais par un choix manuel de l'utilisateur — voir
/// SPEC.md section 4 règle 4). Partagé entre `core/` (détection, métadonnées)
/// et le futur modèle applicatif `VideoBookmark` (Tâche 5), pour éviter que
/// `core/` ne dépende de `features/`.
enum VideoSource {
  youtube,
  tiktok,
  instagram,
  facebook,
  twitter,
  threads,
  unknown,
}
