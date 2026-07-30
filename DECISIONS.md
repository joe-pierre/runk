# Décisions techniques et bugs résolus

## [CHOIX] Flutter plutôt que React Native / Expo

**Contexte :** le porteur du projet n'est pas à l'aise avec React, React Native ni Expo.
**Alternatives :** React Native + Expo (proposé initialement), Flutter.
**Décision :** Flutter, avec Supabase comme backend (SDK Flutter officiel bien maintenu, évite d'écrire un backend custom).
**Leçon :** le confort et la vitesse d'exécution du développeur priment sur un avantage technique marginal d'une stack qu'il ne maîtrise pas.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Nom de l'application : Runk

**Contexte :** plusieurs noms candidats (VidVault, ReelKeeper, Reelio, MyReels, Clipfolio, Vidnest, Loopvault) se sont révélés déjà utilisés par des apps concurrentes ou quasi-identiques dans leur fonction (sauvegarde de reels avec réouverture dans l'app source).
**Cause :** le champ lexical "Reel/Vid + mot simple" est extrêmement saturé sur les stores mobiles.
**Décision :** adoption de **Runk**, du wolof signifiant "garder / archiver" — aucun concurrent fonctionnel trouvé lors de la recherche, domaine `runkapp.com` disponible.
**Leçon :** sortir des conventions de nommage anglo-saxonnes évidentes réduit fortement le risque de collision de marque. Vérifier systématiquement (recherche web + disponibilité domaine) avant de s'attacher à un nom.
**Statut :** ✅ Résolu

---

## [CHOIX] Architecture en providers pour la récupération de métadonnées

**Contexte :** chaque plateforme (YouTube, TikTok, Instagram, Facebook, X, Threads) a des méthodes de récupération de métadonnées très différentes en fiabilité (oEmbed officiel vs scraping fragile de balises `og:`).
**Problème évité :** un service monolithique unique aurait rendu la maintenance impossible dès qu'une plateforme change son comportement (cas fréquent pour Instagram/Facebook/Threads).
**Décision :** pattern stratégie — une interface `MetadataProvider` commune, une implémentation par plateforme, un `MetadataService` orchestrateur qui délègue et un `GenericFallbackProvider` systématique en cas d'échec.
**Leçon :** isoler la volatilité (comportement changeant des plateformes tierces) dans des unités remplaçables indépendamment, sans jamais bloquer le flux utilisateur principal.
**Statut :** ✅ Résolu

---

## [CHOIX] Dégradation gracieuse des métadonnées (`is_partial`)

**Contexte :** Facebook et Threads ne fournissent pas d'API de métadonnées publique fiable ; le scraping échoue fréquemment.
**Alternatives envisagées :** (1) bloquer l'ajout si les métadonnées ne peuvent pas être récupérées, (2) créer le bookmark avec un titre par défaut et un flag `is_partial`.
**Décision :** option 2. L'utilisateur peut toujours sauvegarder n'importe quel lien, quitte à devoir renseigner un titre manuellement si l'auto-récupération échoue.
**Leçon :** ne jamais laisser une dépendance externe non fiable bloquer l'action principale de l'utilisateur.
**Statut :** ✅ Résolu

---

## [CHOIX] Ordre de développement : Share Intent avant Metadata Service complet

**Contexte :** de nombreuses plateformes à intégrer (6) pouvaient donner l'impression qu'il fallait toutes les développer en parallèle avant d'avoir un flux testable.
**Décision :** prioriser le Share Intent (cœur de l'expérience) avec seulement YouTube + TikTok pour la métadonnée (fiables via oEmbed), afin d'obtenir un flux de bout en bout fonctionnel rapidement. Les plateformes restantes (Instagram, Facebook, X, Threads) sont ajoutées une par une ensuite, testées isolément.
**Leçon :** un flux complet mais limité en couverture vaut mieux qu'une couverture large mais un flux principal non validé.
**Statut :** 🔵 Choix assumé

---

## [RÉSOLU] Riverpod 2.x plutôt que 3.x, pour compatibilité avec `isar_generator`

**Contexte :** Tâche 1, ajout des dépendances. `flutter pub add` résout par défaut `flutter_riverpod`/`riverpod_annotation` en version 3.x (la plus récente).
**Symptôme / Problème :** `flutter pub add ... dev:riverpod_generator dev:isar_generator` échoue en conflit de versions. `isar_generator` (dernière publication : `3.1.0+1`, package `isar` non maintenu depuis Isar v3) fige `analyzer` à `<6.0.0`. Aucune version de `riverpod_generator` compatible avec `riverpod_annotation ^3.x`/`^4.x` n'accepte un `analyzer` aussi ancien.
**Cause :** `isar`/`isar_generator` (mandatés par SPEC.md section 2) n'ont pas été mis à jour depuis la sortie de Riverpod 3 ; aucune version de la chaîne d'outils Riverpod récente ne peut donc coexister avec la génération de code Isar.
**Alternatives envisagées :** (1) remplacer `isar`/`isar_generator` par le fork communautaire `isar_community` (plus maintenu, compatible Riverpod 3) — écarté car changement de dépendance non listée dans SPEC.md, à ne pas trancher silencieusement ; (2) abandonner la génération de code Riverpod (`riverpod_generator`) — écarté, alourdirait tout le code futur en écriture manuelle ; (3) figer toute la chaîne Riverpod en 2.x, compatible avec l'`analyzer` imposé par `isar_generator`.
**Décision :** option 3. `flutter_riverpod: ^2.6.1`, `riverpod_annotation: ^2.6.1`, `riverpod_generator: ^2.4.0` (résolus conjointement par `pub` pour rester dans un `analyzer <6.0.0`). Toutes les dépendances de SPEC.md section 2 restent présentes, sans ajout ni suppression — seule leur version diffère de la toute dernière disponible.
**Leçon :** avec un package non maintenu dans la liste imposée (`isar`), toujours résoudre les dépendances de génération de code (`build_runner`-based) ensemble en une seule commande `pub add`, jamais une par une — le solveur ne peut arbitrer un conflit transitif s'il n'a pas tous les paquets à satisfaire simultanément.
**Statut :** 🟡 Révisé — voir "Migration vers `isar_community`" ci-dessous, qui lève cette contrainte. Entrée conservée pour l'historique, ne pas supprimer.

---

## [RÉSOLU] Migration vers `isar_community` — Riverpod 3.x de nouveau possible

**Contexte :** branche `chore/isar-community-migration`, partie de `dev`. Suite à l'entrée "Riverpod 2.x" ci-dessus, test de `isar_community` (fork communautaire actif du package `isar` original, https://pub.dev/packages/isar_community) pour vérifier s'il lève la contrainte qui figeait Riverpod en 2.x.
**Étape 1 — test isolé de résolution de dépendances :** remplacement dans `pubspec.yaml` de `isar`→`isar_community`, `isar_flutter_libs`→`isar_community_flutter_libs`, `isar_generator`→`isar_community_generator`, puis `flutter pub add isar_community isar_community_flutter_libs dev:isar_community_generator flutter_riverpod riverpod_annotation dev:riverpod_generator dev:build_runner` en une seule commande (même leçon que l'entrée précédente : tout résoudre ensemble).
**Résultat :** ✅ succès, aucun conflit du solveur. Versions obtenues : `isar_community ^3.3.0`, `isar_community_flutter_libs ^3.3.0`, `isar_community_generator ^3.3.0`, `flutter_riverpod ^3.1.0`, `riverpod_annotation ^4.0.0`, `riverpod_generator ^4.0.0+1` — la chaîne Riverpod repasse en 3.x.
**Étape 2 — vérifications :**
- Aucun fichier du code applicatif n'importait `package:isar` à ce stade (aucun modèle Isar n'existe encore, Phase 4 de `TODO.md`) : rien à migrer côté code, `build_runner` tourne sans erreur (no-op).
- `flutter analyze` et `flutter test` : propres.
- `flutter build apk --debug` : échoue d'abord avec une **nouvelle contrainte non anticipée** — `isar_community_flutter_libs` impose `minSdk 23` (Android 6.0), alors que le projet était configuré en `minSdk` par défaut (21, via `flutter.minSdkVersion`). Corrigé en fixant `minSdk = 23` explicitement dans `android/app/build.gradle.kts` (voir aussi `BUGS_AND_ROADMAP.md`, ce point réduit la couverture d'appareils Android < 6.0).
- Correctifs Gradle de l'entrée "Build Android" ci-dessus, revérifiés empiriquement (retrait temporaire puis nouveau test, pas supposé) :
  - le correctif de déduction de `namespace` **n'est plus nécessaire** : `isar_community_flutter_libs` déclare son propre `namespace` (`dev.isar.isar_community_flutter_libs`) — retiré de `android/build.gradle.kts` ;
  - le correctif NDK (`ndkVersion = "27.0.12077973"`) **reste nécessaire** : `isar_community_flutter_libs` réclame toujours NDK 27, comme l'ancien `isar_flutter_libs`, tout comme `app_links`/`path_provider_android`/`receive_sharing_intent`/`shared_preferences_android`/`url_launcher_android` (sans lien avec Isar) — conservé ;
  - le correctif d'alignement de cible JVM (Java/Kotlin 11) **reste nécessaire**, mais uniquement à cause de `receive_sharing_intent` (toujours sans cible explicite) — sans lien avec Isar non plus. Conservé, commentaire mis à jour pour ne plus mentionner `isar_flutter_libs`.
**Décision :** migration adoptée. `isar`/`isar_flutter_libs`/`isar_generator` remplacés par `isar_community`/`isar_community_flutter_libs`/`isar_community_generator` dans `pubspec.yaml` et `SPEC.md` section 2. Riverpod remonté en 3.x.
**Leçon :** ne jamais supposer qu'un correctif de contournement reste valable après un changement de dépendance qui l'a motivé — le revérifier empiriquement (ici, un des trois correctifs Android est devenu obsolète, les deux autres non, et un tout nouveau problème est apparu ailleurs).
**Statut :** ✅ Résolu

---

## [RÉSOLU] Build Android : `namespace` manquant, NDK et cible JVM incohérente sur des plugins tiers non maintenus

**Contexte :** Tâche 1, vérification `flutter build apk --debug`. Trois échecs successifs, tous causés par des plugins tiers mandatés par SPEC.md (`isar_flutter_libs`, `receive_sharing_intent`, entre autres) qui n'ont pas été mis à jour pour les exigences récentes d'Android Gradle Plugin (AGP 8.7.3, imposé par le template Flutter actuel).
**Symptôme / Problème :**
1. `isar_flutter_libs` ne déclare pas de `namespace` (obligatoire depuis AGP 8) → échec de configuration Gradle.
2. `isar_flutter_libs`, `receive_sharing_intent`, `path_provider_android`, `url_launcher_android`, etc. réclament un NDK plus récent (27.0.12077973) que celui utilisé par défaut par le projet.
3. `receive_sharing_intent` ne déclare aucune cible Java/Kotlin explicite : son code Java compile en 1.8 (défaut historique) pendant que son code Kotlin compile avec le JDK courant → « Inconsistent JVM-target compatibility ».
**Cause :** ces plugins sont antérieurs aux exigences actuelles d'AGP/Kotlin Gradle Plugin et ne seront probablement plus mis à jour (`isar_flutter_libs` notamment, cf. décision ci-dessus sur Isar).
**Alternatives envisagées :** patcher directement les fichiers Gradle du cache pub (`~/.pub-cache/...`) — écarté, non versionné et écrasé à chaque `flutter pub get` chez tout autre développeur clonant le repo.
**Décision :** injecter les correctifs depuis `android/build.gradle.kts` (racine, versionné), appliqués à tous les sous-projets de plugins (jamais à `:app`, qui garde sa propre configuration) :
- déduction automatique du `namespace` manquant depuis l'attribut `package` du `AndroidManifest.xml` de chaque plugin ;
- `ndkVersion = "27.0.12077973"` fixé explicitement dans `android/app/build.gradle.kts` ;
- alignement de `compileOptions` (Java) et `KotlinCompile.compilerOptions.jvmTarget` (Kotlin) sur Java 11 pour tous les modules de plugins, via `android/build.gradle.kts`.
**Leçon :** avec des dépendances imposées par la spec mais non maintenues, préférer un correctif central et versionné dans le `build.gradle.kts` racine plutôt que de modifier le cache pub ou de forker le plugin — reproductible pour toute personne qui clone le repo et lance `flutter pub get`.
**Statut :** 🟡 Révisé — voir "Migration vers `isar_community`" ci-dessus : le correctif de `namespace` (point 1) est devenu inutile après la migration, les correctifs NDK et JVM (points 2-3) restent nécessaires. Entrée conservée pour l'historique, ne pas supprimer.

---

## [CHOIX] Intent-filters Android `SEND`/`SEND_MULTIPLE` restreints au mimeType `text/plain`

**Contexte :** Tâche 2, configuration des intent-filters dans `AndroidManifest.xml` pour faire apparaître Runk dans le menu de partage natif Android. Le prompt de tâche ne précisait pas quel(s) `mimeType` déclarer.
**Alternatives envisagées :** (1) `android:mimeType="*/*"` pour accepter tout type de contenu partagé (fichiers, images, texte) ; (2) `android:mimeType="text/plain"`.
**Décision :** option 2. Instagram, TikTok, YouTube, etc. partagent un lien vidéo comme texte brut (jamais comme fichier) — un `mimeType` large ferait apparaître Runk dans le menu de partage système pour des contenus hors périmètre (photos, documents), ce qui contredit la règle métier 1 de `SPEC.md` (aucun fichier vidéo stocké, uniquement des URLs).
**Leçon :** ne pas élargir un intent-filter par prudence — un `mimeType` trop permissif pollue le menu de partage système avec des contenus que l'app ne sait pas traiter.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 3 — Share Extension iOS : préparation des fichiers sans Xcode + portée de l'extension

**Contexte :** Tâche 3, équivalent iOS du Share Intent Android (Tâche 2). La session s'exécute sur une machine Linux, sans Xcode ni `xcodebuild`/`pod` disponibles.
**Problème :** la création d'un nouveau target Xcode (`RunkShareExtension`, Share Extension) et l'activation de la capability App Group se font exclusivement dans l'éditeur graphique Xcode — aucune commande ne les remplace, et un `project.pbxproj` reconstruit à la main ne peut pas être vérifié sans Xcode pour le compiler. Une tentative d'édition manuelle du `.pbxproj` aurait pu casser le projet `Runner` existant sans qu'aucune vérification ne soit possible dans cette session.
**Alternatives envisagées :** (1) éditer `project.pbxproj` directement à la main — écarté après validation explicite avec l'utilisateur, car invérifiable et risqué pour un fichier généré normalement par Xcode ; (2) préparer tout le contenu ne nécessitant pas Xcode (fichiers applicatifs de l'extension, entrées `Info.plist` de `Runner`) et documenter précisément dans `guide.md` (section 4.2) les étapes qui doivent être faites à la main dans Xcode sur une machine macOS — retenue.
**Décision :** option 2. Fichiers créés dans cette session : `ios/RunkShareExtension/Info.plist`, `ios/RunkShareExtension/ShareViewController.swift` (sous-classe de `RSIShareViewController` du package `receive_sharing_intent`, en suivant son propre exemple officiel), `ios/RunkShareExtension/Base.lproj/MainInterface.storyboard`. `ios/Runner/Info.plist` mis à jour (clé `AppGroupId` + `CFBundleURLTypes` avec le schéma `ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)` requis par le package pour rediriger vers l'app hôte). La création du target Xcode lui-même, l'activation de la capability App Group sur les deux targets, l'ajustement du Podfile et l'ordre des Build Phases restent à faire manuellement dans Xcode — instructions détaillées dans `guide.md` section 4.2.
**Choix de portée additionnels, documentés pour ne rien trancher silencieusement :**
- `NSExtensionActivationRule` de l'extension restreint à `NSExtensionActivationSupportsText` + `NSExtensionActivationSupportsWebURLWithMaxCount = 1` uniquement (pas d'image/vidéo/fichier) — symétrique du choix déjà fait pour Android (`mimeType="text/plain"`, voir entrée ci-dessus) et cohérent avec la règle métier 1 de `SPEC.md` (Runk ne stocke jamais de fichier vidéo, uniquement des liens).
- `AppGroupId` codé en dur (`group.com.senluxtech.runk`) directement dans les deux `Info.plist`, plutôt que via une variable de build `$(CUSTOM_GROUP_ID)` (pattern utilisé dans l'exemple officiel du package) — évite d'avoir à déclarer un réglage "User-Defined" dans Xcode en plus de la capability. Un identifiant d'App Group n'est pas une donnée secrète (à la différence d'une clé Supabase), aucune violation de la règle "aucune clé secrète en dur".
- `ios/Runner/AppDelegate.swift` non modifié : l'exemple officiel du package y ajoute une surcharge de `application(_:open:options:)`, mais son propre commentaire précise que ce n'est nécessaire que si une **autre** librairie a aussi besoin d'intercepter cet appel. Runk n'en a pas — `registrar.addApplicationDelegate` (déjà appelé par le plugin via `GeneratedPluginRegistrant`) suffit à acheminer l'URL de redirection vers `ShareIntentService`. À revoir si une future dépendance (ex: un SDK d'auth tiers) a besoin du même hook.
**Leçon :** face à un outillage plateforme totalement absent de l'environnement (ici Xcode/macOS), séparer strictement ce qui peut être fait et vérifié à distance (fichiers texte versionnés) de ce qui ne peut être fait que dans l'outil natif — et documenter ce dernier comme une procédure manuelle précise plutôt que de tenter un contournement invérifiable.
**Statut :** 🟡 Partiel — fichiers Dart/iOS applicatifs prêts, création du target Xcode et test sur appareil physique restant à faire par l'utilisateur (voir `BUGS_AND_ROADMAP.md`).

---

## [CHOIX] Offline-first avec Isar + synchronisation last-write-wins vers Supabase

**Contexte :** l'usage attendu (partage rapide de vidéo depuis une autre app) doit fonctionner même sans connexion réseau stable.
**Décision :** toute écriture passe d'abord par Isar (local), puis synchronisation asynchrone vers Supabase quand la connexion est disponible. En cas de conflit d'écriture concurrente entre appareils, la résolution est **last-write-wins** basée sur `updated_at` — pas de fusion intelligente en V1.
**Leçon :** accepter une limitation connue et documentée (perte potentielle d'une modification concurrente rare) plutôt que de complexifier prématurément avec un système de résolution de conflits avancé non justifié par l'usage réel attendu (utilisateur individuel, rarement multi-appareils simultanés).
**Statut :** 🔵 Choix assumé
