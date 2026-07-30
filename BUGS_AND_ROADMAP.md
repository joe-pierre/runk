# BUGS CORRIGÉS

- **[2026-07-30]** Conflit de versions bloquant `flutter pub add` de la chaîne Riverpod (génération de code) — `isar_generator` impose `analyzer <6.0.0`, incompatible avec `riverpod_generator` récent — résolu en figeant `flutter_riverpod`/`riverpod_annotation`/`riverpod_generator` en 2.x (voir `DECISIONS.md`) — `pubspec.yaml`
- **[2026-07-30]** `flutter build apk` en échec (namespace manquant, NDK incohérent, cible JVM incohérente) sur des plugins tiers non maintenus (`isar_flutter_libs`, `receive_sharing_intent`, ...) — voir `DECISIONS.md` — `android/build.gradle.kts`, `android/app/build.gradle.kts`

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
- `isar`/`isar_flutter_libs`/`isar_generator` (v3) ne sont plus maintenus depuis la sortie d'Isar v4/`isar_community` — a nécessité de figer Riverpod en 2.x et de patcher `android/build.gradle.kts` pour compiler (voir `DECISIONS.md`, Tâche 1). À surveiller : si un futur upgrade Flutter/AGP casse à nouveau la compilation, envisager une migration vers `isar_community`, à discuter avant exécution (changement de dépendance hors SPEC.md).
- Les schémas de deep link natifs (`instagram://`, `snssdk1233://` pour TikTok, etc.) ne sont pas documentés officiellement par les plateformes et peuvent changer sans préavis — prévoir une vérification périodique (voir `guide.md` section 7.5)
- Le scraping de balises `og:` pour Instagram/Facebook/Threads est fragile par nature : surveiller le taux de `is_partial = true` en production comme indicateur de santé de chaque provider
- Politique de conservation des données à clarifier si une fonctionnalité d'export ou de partage entre utilisateurs est ajoutée (RGPD si expansion vers l'UE)
