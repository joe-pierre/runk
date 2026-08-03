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

  /// Site web quelconque qui n'est ni l'une des 6 plateformes vidéo
  /// ci-dessus, ni Google Maps (Tâche 39, périmètre séparé).
  ///
  /// Contrairement aux autres valeurs, jamais déduite par `SourceDetector`
  /// (qui ne connaît que les 6 plateformes vidéo et retombe sur `unknown`) —
  /// assignée explicitement par `GenericWebsiteProvider` en cas de succès du
  /// scraping `og:` (voir DECISIONS.md, entrée "Tâche 38").
  website,

  /// Lieu ou itinéraire Google Maps (Tâche 39).
  ///
  /// Aucune miniature n'est **jamais** récupérée pour cette source — décision
  /// produit assumée, pas une dégradation : les pages Google Maps sont
  /// fortement rendues en JavaScript côté client, sans `og:image`
  /// exploitable de façon fiable par scraping, et l'API Static Maps
  /// (payante, à clé) est volontairement écartée pour ce périmètre (voir
  /// DECISIONS.md, entrée "Tâche 39"). `MapsProvider.fetchMetadata` ne
  /// renseigne donc jamais `VideoMetadata.thumbnailUrl`, quel que soit le
  /// succès de la récupération du titre.
  maps,
  unknown,
}
