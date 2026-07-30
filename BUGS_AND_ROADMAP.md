# BUGS CORRIGÉS

- **[2026-07-30]** Conflit de versions bloquant `flutter pub add` de la chaîne Riverpod (génération de code) — `isar_generator` impose `analyzer <6.0.0`, incompatible avec `riverpod_generator` récent — résolu en figeant `flutter_riverpod`/`riverpod_annotation`/`riverpod_generator` en 2.x (voir `DECISIONS.md`) — `pubspec.yaml` — *devenu obsolète le [2026-07-30], voir migration `isar_community` ci-dessous*
- **[2026-07-30]** `flutter build apk` en échec (namespace manquant, NDK incohérent, cible JVM incohérente) sur des plugins tiers non maintenus (`isar_flutter_libs`, `receive_sharing_intent`, ...) — voir `DECISIONS.md` — `android/build.gradle.kts`, `android/app/build.gradle.kts`
- **[2026-07-30]** Migration `isar`→`isar_community` : lève la contrainte Riverpod 2.x (repasse en 3.x), rend inutile le correctif de `namespace` manquant, mais impose `minSdk 23` (perte du support Android < 6.0) et conserve les correctifs NDK/JVM (dus à `receive_sharing_intent`, sans lien avec Isar) — voir `DECISIONS.md`, entrée "Migration vers isar_community" — `pubspec.yaml`, `SPEC.md`, `android/build.gradle.kts`, `android/app/build.gradle.kts`

# ROADMAP (idées / améliorations futures)

## Monétisation
- Modèle freemium : gratuit jusqu'à un nombre limité de bookmarks, illimité en payant
- Abonnement mensuel (~2-5$/mois) pour la synchronisation cloud multi-appareils et des fonctionnalités avancées
- Alternative : achat unique de l'application sans palier gratuit

## Fonctionnalités futures
- Supabase Realtime pour synchronisation instantanée multi-appareils (voir `SPEC.md` section 6, non implémenté en V1)
- Export des bookmarks (CSV / JSON) pour sauvegarde personnelle
- Partage d'une collection de bookmarks avec un autre utilisateur Runk (lecture seule)
- Détection de doublons (même URL déjà sauvegardée)
- Suggestions de tags basées sur les tags déjà utilisés par l'utilisateur (autocomplétion)
- Widget d'accueil (Android/iOS) affichant les derniers bookmarks ajoutés
- Version web ou tablette légère, en lecture, s'appuyant sur le même backend Supabase

## Points de vigilance techniques identifiés
- Migration effectuée vers `isar_community`/`isar_community_generator` (fork actif du package `isar` v3 original, abandonné) — voir `DECISIONS.md`, entrée "Migration vers isar_community". Le projet nécessite désormais `minSdk 23` (Android 6.0+). **[2026-07-30] Décision produit tranchée : relèvement de minSdk 21 → 23 accepté définitivement.** Raison : Android 5.x (API 21-22) représente une part résiduelle et en déclin du marché actif (estimations entre <0,1 % et ~5 % selon les sources, données 2025-2026 — chiffre exact incertain mais tendance nettement à la baisse) ; le compromis est jugé raisonnable au vu du gain (dépendances Isar maintenues, retour à Riverpod 3.x) contre la perte de couverture, probablement marginale et concentrée sur des appareils très anciens peu compatibles avec les apps tierces ciblées par Runk (YouTube, Instagram, TikTok, etc.). `isar_community` étant lui aussi un projet plus jeune/moins établi que l'écosystème Flutter historique, surveiller son activité de maintenance dans la durée.
- Les schémas de deep link natifs (`instagram://`, `snssdk1233://` pour TikTok, etc.) ne sont pas documentés officiellement par les plateformes et peuvent changer sans préavis — prévoir une vérification périodique (voir `guide.md` section 7.5)
- Le scraping de balises `og:` pour Instagram/Facebook/Threads est fragile par nature : surveiller le taux de `is_partial = true` en production comme indicateur de santé de chaque provider
- Politique de conservation des données à clarifier si une fonctionnalité d'export ou de partage entre utilisateurs est ajoutée (RGPD si expansion vers l'UE)
