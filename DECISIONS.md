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

## [CHOIX] Tâche 4 — Emplacement de `VideoSource` et forme de `VideoMetadata`

**Contexte :** Tâche 4, création de `source_detector.dart` et de l'interface `MetadataProvider`. Le prompt de tâche mentionne `VideoSource` et `VideoMetadata` sans préciser où les placer ni la forme exacte de `VideoMetadata` — `features/bookmarks/domain/video_bookmark.dart` (SPEC.md section 3.1, qui déclare `enum VideoSource` et le modèle complet `VideoBookmark`) n'existe pas encore (Tâche 5).
**Symptôme / Problème :** faire vivre `VideoSource` dans `features/bookmarks/domain/` aurait forcé `core/utils/source_detector.dart` et `core/services/metadata/` (Tâche 4) à dépendre de `features/` — inversion de dépendance, `core/` doit rester indépendant des features qui l'utilisent.
**Cause / Alternatives :** (1) dupliquer un enum équivalent dans `core/` et dans `features/bookmarks/domain/` — écarté, source de désynchronisation ; (2) placer `VideoSource` dans `core/models/video_source.dart`, réutilisé tel quel par le futur `VideoBookmark` (Tâche 5) ; pour `VideoMetadata`, soit fusionner avec le futur `VideoBookmark`, soit une classe dédiée propre à la couche metadata.
**Fix / Décision :** option 2 pour les deux. `VideoSource` créé dans `lib/core/models/video_source.dart` (Tâche 5 devra l'importer depuis `core/`, ne pas le redéclarer). `VideoMetadata` créé dans `lib/core/services/metadata/video_metadata.dart` comme classe dédiée (`title`, `thumbnailUrl`, `source`, `isPartial`) — volontairement distincte de `VideoBookmark`, qui ajoutera en Tâche 5 les champs propres à la persistance (id, tags, note, dates) absents du résultat brut d'un provider.
**Leçon :** quand un prompt de tâche référence un type qui appartient formellement à une tâche future, le placer dans la couche la plus basse qui en a besoin maintenant (`core/`), jamais dans la couche qui le consommera plus tard (`features/`) — évite d'avoir à choisir entre dépendance inversée et duplication.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 4 — Mock HTTP des providers via `package:http/testing.dart`

**Contexte :** Tâche 4, tests unitaires de `YoutubeProvider`/`TiktokProvider` nécessitant de simuler des réponses HTTP sans appel réseau réel.
**Alternatives envisagées :** (1) ajouter une dépendance de mocking dédiée (`mocktail`, `mockito`) ; (2) utiliser `MockClient` de `package:http/testing.dart`, déjà inclus dans le package `http` présent dans `pubspec.yaml` depuis la Tâche 1.
**Décision :** option 2. Chaque provider accepte un `http.Client` injectable en constructeur (défaut : `http.Client()` réel), ce qui suffit à intercepter les requêtes en test via `MockClient` sans nouvelle dépendance.
**Leçon :** avant d'ajouter une dépendance de test, vérifier si l'outillage déjà présent (ici `http/testing.dart`, livré avec `http`) couvre déjà le besoin.
**Statut :** ✅ Résolu

---

## [CHOIX] Offline-first avec Isar + synchronisation last-write-wins vers Supabase

**Contexte :** l'usage attendu (partage rapide de vidéo depuis une autre app) doit fonctionner même sans connexion réseau stable.
**Décision :** toute écriture passe d'abord par Isar (local), puis synchronisation asynchrone vers Supabase quand la connexion est disponible. En cas de conflit d'écriture concurrente entre appareils, la résolution est **last-write-wins** basée sur `updated_at` — pas de fusion intelligente en V1.
**Leçon :** accepter une limitation connue et documentée (perte potentielle d'une modification concurrente rare) plutôt que de complexifier prématurément avec un système de résolution de conflits avancé non justifié par l'usage réel attendu (utilisateur individuel, rarement multi-appareils simultanés).
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 5 — `user_id` absent avant l'authentification (`BookmarkEntity.userId` nullable)

**Contexte :** Tâche 5, `BookmarkRepository`. Le schéma Supabase (SPEC.md section 3.2) impose `user_id uuid ... not null`, mais l'authentification (Phase 6 du TODO) n'est pas encore implémentée — aucun utilisateur connecté n'existe à ce stade du projet.
**Alternatives envisagées :** (1) appeler directement `Supabase.instance.client.auth.currentUser` depuis le repository pour remplir `user_id` — écarté, car ça couple le repository à un état d'authentification non testé et casserait le critère d'acceptation ("sans dépendre d'une connexion Supabase réelle") ; (2) ajouter un champ `userId` nullable à `BookmarkEntity` (au-delà du modèle strict de SPEC.md section 3.3, mise à jour en conséquence), rempli rétroactivement par la future Tâche Auth, et ne tenter aucune synchronisation distante tant qu'il est `null`.
**Décision :** option 2, validée explicitement par l'utilisateur. `BookmarkEntity.userId` est nullable — un bookmark créé hors ligne avant toute authentification est stocké localement sans erreur, `isSynced` reste `false`. `BookmarkRepository._trySyncInsert`/`_trySyncUpdate`/`deleteBookmark` vérifient `entity.userId == null` **avant** tout appel à `BookmarkRemoteDatasource` : si absent, aucune tentative n'est faite (ce n'est pas un échec de synchronisation, juste un état "pas encore prêt à synchroniser").
**Distinction des erreurs (précision demandée) :** ce garde-fou préalable évite que le cas "pas encore authentifié" ne soit confondu avec un vrai bug de synchronisation. Un échec survenant *après* cette vérification (réseau, rejet RLS malgré un `userId` renseigné, erreur serveur) est enveloppé dans une exception dédiée `BookmarkRemoteSyncException` (`lib/features/bookmarks/data/bookmark_remote_sync_exception.dart`), journalée explicitement via `debugPrint` (pas de `catch` silencieux, voir CONVENTIONS.md section Réponses API) — exploitable plus tard par `sync_service.dart` (Tâche 9) pour différencier les deux cas plutôt que de tout traiter comme un `isSynced = false` indifférencié.
**Leçon :** quand une dépendance future (ici l'authentification) n'existe pas encore, préférer un garde-fou explicite et déterministe (vérifier un champ local avant d'agir) plutôt que de déclencher un appel voué à l'échec puis d'interpréter son exception — ça évite toute ambiguïté sur la cause réelle d'un `isSynced = false`.
**Statut :** 🔵 Choix assumé — à revisiter à la Tâche Auth (Phase 6), qui devra fournir un mécanisme pour renseigner `userId` rétroactivement sur les bookmarks déjà créés hors ligne.

---

## [CHOIX] Tâche 5 — Suppression douce (`isDeletedLocally`) avant confirmation distante

**Contexte :** Tâche 5, `BookmarkRepository.deleteBookmark`. SPEC.md section 13 documente un risque : une suppression locale pendant qu'une synchronisation est en cours pourrait faire réapparaître le bookmark supprimé après une sync ultérieure. Le prompt de tâche ne précisait pas si cette mitigation devait être implémentée dès cette tâche ou reportée au futur `sync_service.dart`.
**Alternatives envisagées :** (1) suppression locale immédiate (comme pour insert/update) + tentative distante best-effort, sans lien avec `isDeletedLocally` — plus simple mais laisse `isDeletedLocally` inutilisé et le risque de réapparition non mitigé ; (2) suppression douce : marquer `isDeletedLocally = true` immédiatement (le bookmark disparaît aussitôt de `getAllBookmarks`), tenter la suppression distante, et ne retirer l'entité locale définitivement qu'une fois cette suppression distante confirmée — sinon la ligne reste marquée en attente pour une synchronisation future.
**Décision :** option 2, validée explicitement par l'utilisateur — fidèle à SPEC.md section 13. Sans utilisateur authentifié (`userId == null`), aucune tentative distante n'est faite et la ligne reste marquée `isDeletedLocally = true` (nettoyée plus tard par le futur `sync_service.dart`).
**Leçon :** quand SPEC.md documente déjà une mitigation précise pour un risque identifié, l'implémenter dès que le champ concerné existe plutôt que de la reporter — un champ non exploité (`isDeletedLocally`) aurait fini par diverger silencieusement de son usage prévu.
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 5 — Fake du datasource distant sans nouvelle dépendance de mocking

**Contexte :** Tâche 5, test d'intégration CRUD de `BookmarkRepository` nécessitant de simuler `BookmarkRemoteDatasource` sans appel Supabase réel (critère d'acceptation).
**Décision :** comme pour l'entrée "Tâche 4 — Mock HTTP des providers" ci-dessus, pas de nouvelle dépendance (`mocktail`/`mockito`) : `FakeBookmarkRemoteDatasource implements BookmarkRemoteDatasource` est défini directement dans le fichier de test, Dart permettant nativement d'implémenter l'interface implicite d'une classe concrète.
**Leçon :** cohérent avec la leçon déjà tirée en Tâche 4 — vérifier que le langage/l'outillage déjà en place suffit avant d'ajouter une dépendance de test.
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 5 — Isar de test via répertoire temporaire (pas de mode "en mémoire" natif)

**Contexte :** Tâche 5, critère d'acceptation demandant un "Isar en mémoire de test". `isar_community` ne propose pas de mode purement in-memory : `Isar.open` requiert toujours un `directory`.
**Décision :** chaque test ouvre une instance Isar dans un répertoire temporaire (`Directory.systemTemp.createTempSync()`), supprimé dans `tearDown` — équivalent fonctionnel d'un Isar "en mémoire" pour l'isolation des tests (aucune donnée persistante entre tests ni avec la vraie base de l'app). `Isar.initializeIsarCore(download: true)` est appelé dans `setUpAll` (télécharge le binaire natif au premier lancement, mis en cache ensuite) — suivre `flutter test -j 1` comme documenté par `isar_community` pour éviter un téléchargement concurrent corrompu.
**Leçon :** le nom "in-memory" du critère d'acceptation était une approximation ; vérifier l'API réelle du package avant de supposer qu'une fonctionnalité existe telle quelle.
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 6 — Riverpod avec génération de code (`@riverpod`), première utilisation réelle

**Contexte :** Tâche 6, première tâche qui utilise réellement Riverpod dans le code applicatif (`flutter_riverpod`/`riverpod_annotation`/`riverpod_generator` n'étaient présents que dans `pubspec.yaml` depuis la Tâche 1, jamais utilisés). Le prompt de tâche demande "un provider Riverpod" sans préciser style manuel vs génération de code.
**Alternatives envisagées :** (1) providers manuels (`Provider`, `FutureProvider`, `StateNotifierProvider` écrits à la main) ; (2) génération de code via `@riverpod` (annotations + `riverpod_generator`), déjà ajoutée en dépendance de dev depuis la Tâche 1.
**Décision :** option 2. Tous les providers de cette tâche (`bookmarkIsarProvider`, `bookmarkRepositoryProvider`, `metadataServiceProvider`, `videoMetadataProvider`, `shareIntentServiceProvider`, `bookmarkListProvider`) sont générés via `@riverpod`/`@Riverpod(keepAlive: true)`, cohérent avec la dépendance déjà posée et avec le nommage `xyzProvider` de CONVENTIONS.md.
**Leçon :** une dépendance de génération de code ajoutée dès la Tâche 1 mais jamais exploitée est un signal qu'un style de codage était déjà tranché en amont — le confirmer explicitement à la première utilisation réelle plutôt que de re-décider silencieusement un style manuel.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 6 — Emplacement de l'ouverture d'Isar (`bookmarkIsarProvider` dans `features/bookmarks/data/`, pas `core/`)

**Contexte :** Tâche 6, premier branchement réel d'Isar dans l'app (jusqu'ici ouvert uniquement dans `bookmark_repository_test.dart`, via un répertoire temporaire — voir DECISIONS.md Tâche 5). `main.dart` doit désormais ouvrir une vraie instance Isar dans le répertoire de documents de l'app.
**Alternatives envisagées :** (1) `core/services/isar_service.dart`, symétrique de `SupabaseService` ; (2) directement dans `features/bookmarks/data/bookmark_repository_provider.dart`.
**Décision :** option 2. `BookmarkEntitySchema` est propre à la feature bookmarks (seule collection Isar existante) — un service dans `core/` devrait soit importer ce schéma (inversion de dépendance `core/` → `feature/`, écarté depuis DECISIONS.md Tâche 4), soit rester vide de sens tant qu'aucune autre feature n'utilise Isar. Réévaluer si une autre feature (ex: historique clipboard, Tâche 6.5) a besoin de sa propre collection Isar : factoriser l'ouverture de l'instance `Isar` elle-même (pas les schémas) dans `core/` uniquement à ce moment-là.
**Leçon :** ne pas anticiper une factorisation `core/` pour une techno (Isar) tant qu'un seul consommateur existe — le jour où un deuxième arrive, factoriser avec les deux cas réels sous les yeux plutôt que de deviner la bonne coupe à l'avance.
**Statut :** 🔵 Choix assumé — à revisiter si Tâche 6.5 (clipboard) introduit une deuxième collection Isar.

---

## [CHOIX] Tâche 6 — `ShareIntentGate` placé comme `MaterialApp.home`, jamais au-dessus de `MaterialApp`

**Contexte :** Tâche 6, branchement du Share Intent au widget racine pour ouvrir automatiquement `AddBookmarkSheet` (`showModalBottomSheet`). `showModalBottomSheet` nécessite un `BuildContext` descendant d'un `Navigator`/`Overlay`.
**Alternatives envisagées :** (1) placer le widget d'écoute (`ShareIntentGate`) au-dessus de `MaterialApp` et lui fournir un `GlobalKey<NavigatorState>` pour atteindre un contexte valide ; (2) placer `ShareIntentGate` comme contenu de `MaterialApp.home` (donc déjà sous le `Navigator` créé par `MaterialApp`), et utiliser directement son propre `context`.
**Décision :** option 2, plus simple — aucune `GlobalKey` à faire circuler, le `context` du `State` de `ShareIntentGate` est déjà valide pour `showModalBottomSheet`.
**Leçon :** avant d'introduire une `GlobalKey<NavigatorState>` (mécanisme classique mais qui ajoute un point de couplage global), vérifier si le widget a juste besoin d'être positionné différemment dans l'arbre pour obtenir un contexte valide nativement.
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 6 — Dégradation propre si `ShareIntentService.initialize()` échoue

**Contexte :** Tâche 6, vérification manuelle sur `flutter run -d linux` (aucun appareil Android/iOS physique disponible dans cet environnement, voir `BUGS_AND_ROADMAP.md`). `ShareIntentService.initialize()` lève `MissingPluginException` sur toute plateforme sans canal natif `receive_sharing_intent` (desktop, ou iOS avant configuration complète de la Share Extension dans Xcode — voir DECISIONS.md Tâche 3), ce qui faisait planter toute l'application au démarrage (exception non interceptée dans `ShareIntentGate.initState`).
**Cause :** le prompt de tâche ne mentionnait pas ce cas ; l'appel initial ne gérait aucune exception.
**Décision :** `ShareIntentGate._initialize` encapsule l'appel dans un `try/catch` sur `Exception`, journalisé via `debugPrint` (jamais un `catch` silencieux, voir CONVENTIONS.md section Réponses API) — cohérent avec SPEC.md section 4 règle 3 (dégradation propre, ne jamais bloquer l'utilisateur) déjà appliquée à la récupération de métadonnées.
**Leçon :** l'absence d'appareil physique/émulateur mobile dans l'environnement de développement a permis de détecter un vrai bug (crash au démarrage sur toute plateforme sans le plugin) qu'un test unitaire seul n'aurait pas forcément révélé — le run sur `linux desktop`, bien que hors cible, reste un filet de sécurité utile.
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 6.5 — Historique clipboard via `SharedPreferences`, pas une 2e collection Isar

**Contexte :** Tâche 6.5, mémorisation des liens clipboard déjà proposés/ignorés. Le prompt de tâche laissait le choix ("SharedPreferences ou table Isar dédiée"). DECISIONS.md, entrée Tâche 6, notait explicitement qu'il faudrait réévaluer l'emplacement de l'ouverture d'Isar si cette tâche introduisait une 2e collection.
**Alternatives envisagées :** (1) une collection Isar dédiée (`ClipboardHistoryEntity`), avec tout l'appareillage repository/datasource déjà en place pour les bookmarks ; (2) `SharedPreferences` (déjà une dépendance transitive résolue via `supabase_flutter`/`receive_sharing_intent`, `shared_preferences 2.5.3`), ajoutée en dépendance directe.
**Décision :** option 2. Une simple liste d'URLs déjà vues ne justifie pas une 2e collection Isar avec son repository dédié — c'est un état d'interface local (jamais synchronisé sur Supabase, voir contraintes de la tâche), pas une donnée métier. `ClipboardHistoryStore` (`lib/core/services/clipboard_history_store.dart`) encapsule les deux opérations (`hasBeenSeen`/`markAsSeen`) derrière `SharedPreferences`.
**Conséquence sur la décision Tâche 6 :** la question "réévaluer l'emplacement de l'ouverture d'Isar si Tâche 6.5 introduit une 2e collection" ne se pose plus — aucune 2e collection n'est introduite, `bookmarkIsarProvider` reste dans `features/bookmarks/data/`.
**Leçon :** avant d'ajouter une 2e collection Isar (ou toute nouvelle source de données), vérifier si un stockage plus simple déjà présent dans l'arbre de dépendances (ici `SharedPreferences`, déjà résolu transitivement) suffit au besoin réel.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 6.5 — Priorité Share Intent > clipboard sans modifier `ShareIntentService`

**Contexte :** Tâche 6.5, contrainte explicite : ne pas modifier `ShareIntentService`. SPEC.md section 13 documente pourtant la mitigation comme si `ShareIntentService` exposait l'état de sa file d'attente ("le `ClipboardService` vérifie l'état de la file d'attente du `ShareIntentService`") — en réalité cette file (`Queue<String>`) vit dans `ShareIntentGate` (voir DECISIONS.md, Tâche 6), pas dans le service lui-même. `ShareIntentService` n'expose que `sharedUrlStream`, aucun état de traitement.
**Alternatives envisagées :** (1) ajouter malgré tout un état de file d'attente à `ShareIntentService` — écarté, contredit directement la consigne de la tâche ; (2) exposer l'état de traitement depuis `ShareIntentGate` (widget que la tâche autorise à modifier) via un nouveau provider Riverpod dédié, consulté par la logique clipboard.
**Décision :** option 2. `shareIntentProcessingProvider` (`lib/features/bookmarks/presentation/share_intent_processing_provider.dart`), un `Notifier<bool>` simple, mis à jour par `ShareIntentGate._enqueueUrl`/`_processQueue` (vrai dès qu'une URL est en attente ou en cours d'affichage, faux une fois la file vidée). `ClipboardSuggestion` (`clipboard_suggestion_provider.dart`) le consulte avant d'afficher toute URL détectée par `ClipboardService` — `ShareIntentService` reste inchangé.
**Leçon :** quand SPEC.md décrit une mitigation en termes d'un composant qui n'expose pas réellement l'état nécessaire, et qu'une consigne interdit explicitement de le modifier, préférer exposer l'état depuis le composant qui le détient réellement (ici la présentation, `ShareIntentGate`) plutôt que de forcer une modification interdite ou de dupliquer un état de file d'attente.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 7 — `source_detector.dart` déjà complet, aucune modification apportée

**Contexte :** Tâche 7, point 3 ("Mets à jour `source_detector.dart` pour reconnaître les domaines de ces 4 plateformes"). En relisant le fichier avant modification, les domaines `instagram.com`, `facebook.com`/`fb.watch`, `twitter.com`/`x.com` et `threads.net` y sont déjà tous reconnus depuis la Tâche 4 (`source_detector_test.dart` les couvre déjà aussi, test "détecte Instagram, Facebook, X/Twitter et Threads").
**Décision :** aucune modification de `source_detector.dart` dans cette tâche — documenté ici plutôt que de le modifier inutilement (ce qui aurait été une modification silencieuse d'un fichier par ailleurs listé comme autorisé, mais sans justification réelle) ou de le passer sous silence comme un point de la tâche non traité.
**Leçon :** avant de modifier un fichier qu'une tâche autorise explicitement à changer, vérifier qu'un changement est réellement nécessaire — un prompt de tâche peut anticiper un travail déjà fait en amont (ici, la Tâche 4 avait couvert les 6 plateformes cibles dès la première implémentation, pas seulement YouTube/TikTok).
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 7 — Fallback interne aux providers de scraping (Instagram/Facebook/Threads), plutôt que délégation systématique au fallback de `MetadataService`

**Contexte :** Tâche 7, point 1, formulation : "scraping des balises `og:title`/`og:image`, timeout court, fallback systématique vers `isPartial: true` en cas d'échec (**aucune exception de scraping ne doit remonter jusqu'à l'UI**)". `MetadataService` (Tâche 4) intercepte déjà toute `Exception` levée par un provider et bascule vers `GenericFallbackProvider` — un simple `throw` (comme `YoutubeProvider`/`TiktokProvider`/`TwitterProvider`) aurait donc déjà satisfait "aucune exception ne remonte à l'UI" de fait.
**Alternatives envisagées :** (1) laisser `InstagramProvider`/`FacebookProvider`/`ThreadsProvider` lever une exception en cas d'échec de scraping, comme les providers oEmbed, et compter entièrement sur le filet de sécurité de `MetadataService` ; (2) faire en sorte que chacun de ces trois providers **n'expose jamais** d'exception à son appelant — il capture lui-même tout échec (réseau, timeout, balise `og:title` absente) et retourne directement un `VideoMetadata` avec `isPartial: true`.
**Décision :** option 2. Le scraping HTML est structurellement moins fiable qu'un oEmbed officiel (balises absentes, page de connexion à la place du contenu, structure changeante) — un échec de scraping n'est pas un cas exceptionnel pour ces trois plateformes mais un résultat normal et attendu (Facebook/Threads en particulier, voir contrainte du prompt de tâche). Traiter ce cas comme un retour de fonction ordinaire plutôt qu'une exception rend chaque provider robuste indépendamment du comportement de `MetadataService`, et documente explicitement dans le type de retour ce qui est un cas attendu. `TwitterProvider`, lui, reste sur le pattern strict de la Tâche 4 (lève une exception, `MetadataService` bascule vers le fallback générique) car il s'appuie sur un endpoint oEmbed officiel, structurellement fiable comme YouTube/TikTok.
**Conséquence :** le titre de repli n'est pas `GenericFallbackProvider.defaultTitle` mais un texte propre à chaque provider (`'Vidéo Instagram sans titre'`, etc.) — les providers ne référencent jamais `GenericFallbackProvider` ni les uns les autres (voir la doc de `metadata_provider.dart`, "aucune référence croisée entre providers").
**Leçon :** un filet de sécurité générique (ici `MetadataService`) et une gestion d'échec explicite au plus près de sa source ne sont pas mutuellement exclusifs — le second reste préférable quand l'échec est un cas *attendu* du domaine (scraping fragile), pas une anomalie.
**Statut :** ✅ Résolu

---

## [RÉSOLU] Tâche 11 — Décodage des entités HTML dans `OgTagScraper`

**Contexte :** `OgTagScraper._extractProperty` (`lib/core/services/metadata/providers/og_tag_scraper.dart`, Tâche 7) extrayait le contenu brut de l'attribut `content` des balises `<meta property="og:...">` sans décoder les entités HTML.
**Symptôme / Problème :** le HTML source d'Instagram/Facebook/Threads encode systématiquement cet attribut (`&quot;`, `&#x2014;`, entités numériques hors ASCII type `&#x4eca;`), ce qui faisait remonter des titres illisibles jusqu'à l'UI (`AddBookmarkSheet`, `BookmarkCard`, `HomeScreen`) — bug constaté sur test manuel appareil physique.
**Cause / Alternatives :** `dart:convert` ne fournit aucun décodeur d'entités HTML natif. (1) écrire un décodeur maison (table de correspondance des entités nommées + parsing des entités numériques décimales/hexadécimales) — écarté, réinvente un problème déjà résolu et mal couvert par une implémentation artisanale (entités nommées HTML5 nombreuses) ; (2) ajouter une dépendance dédiée après vérification de son état sur pub.dev.
**Fix / Décision :** option 2, package `html_unescape ^2.0.0` — vérifié sur pub.dev avant ajout : 160/160 pub points, **zéro dépendance** (aucun risque de conflit transitif comparable à celui déjà rencontré avec `isar`/`riverpod`, voir DECISIONS.md entrée "Riverpod 2.x..."), supporte les SDK Dart/Flutter stables actuels (couvre `sdk: ^3.8.0`). Seul point notable : dernière publication il y a ~5 ans, jugé acceptable au vu de l'absence de dépendance et de la stabilité intrinsèque du sujet traité (spec HTML5 des entités, non appelée à changer). Décodage appliqué dans `OgTagScraper._extractProperty`, juste après extraction du `content`, donc pour `og:title` **et** `og:image` uniformément — reste entièrement dans la couche `data/` (`core/services/metadata/providers/`), jamais dans `presentation/`. Aucune modification de `InstagramProvider`/`FacebookProvider`/`ThreadsProvider` : ils ne font que relayer le résultat d'`OgTagScraper`, ce correctif unique suffit aux trois.
**Leçon :** avant d'écrire un décodeur/parseur pour un format normalisé et non appelé à évoluer (entités HTML), vérifier si une dépendance mature et sans risque (ici zéro transitive) couvre déjà le besoin plutôt que de réinventer une implémentation partielle.
**Statut :** ✅ Résolu

---

## [RÉSOLU] Tâche 12 — Cache disque local des miniatures (`cached_network_image`)

**Contexte :** `_MetadataPreview` (`add_bookmark_sheet.dart`) et `_BookmarkThumbnail` (`bookmark_card.dart`) chargeaient les miniatures via `Image.network(thumbnailUrl)`, sans aucun cache disque. Les URLs `og:image` d'Instagram/Facebook pointent vers des CDN signés à expiration courte.
**Symptôme / Problème :** l'image se charge correctement au moment de l'ajout du bookmark, puis échoue au rechargement après un redémarrage de l'app une fois l'URL signée expirée — icône `broken_image_outlined` affichée sur les entrées Instagram après réouverture (bug constaté sur test manuel, capture à l'appui).
**Cause / Alternatives :** (1) re-télécharger et stocker le fichier image côté serveur (Supabase Storage) pour ne plus dépendre de l'URL d'origine — écarté d'emblée, hors périmètre de cette tâche (`BookmarkRemoteDatasource` et le schéma Supabase ne doivent pas être touchés) et contreviendrait à SPEC.md section 9 ("pas de stockage de contenu tiers", qui vise justement à éviter un re-upload serveur) ; (2) écrire un mécanisme de cache disque maison (téléchargement + fichier local + table de correspondance URL → chemin, invalidation) — écarté, réinvente un problème déjà bien résolu par un package mature, pour un gain nul ; (3) `cached_network_image`, après vérification explicite sur pub.dev.
**Fix / Décision :** option 3. Vérifié sur pub.dev avant ajout : version `3.4.1`, **150/160 pub points**, **~6,96k likes**, analysé avec les SDK Dart/Flutter stables actuels (compatible `sdk: ^3.8.0`), support **complet** Android/iOS (les limitations de score concernent Windows/Linux/macOS/Web, hors cible de Runk — voir SPEC.md section 2, mobile uniquement). `flutter pub get` n'a introduit aucun conflit de version (contrairement aux précédents avec `isar`/Riverpod, voir DECISIONS.md "Riverpod 2.x…") — seules des dépendances transitives attendues (`flutter_cache_manager`, `sqflite`) sont ajoutées. `Image.network` remplacé par `CachedNetworkImage(imageUrl: ..., errorWidget: ...)` dans `_MetadataPreview` et `_BookmarkThumbnail`, à l'identique du point d'insertion (mêmes `height`/`width`/`fit`). Les icônes de repli sont strictement inchangées : `videocam_off_outlined` si `isPartial`/`thumbnailUrl == null` (géré en amont, avant même d'atteindre le widget de chargement), `broken_image_outlined` en cas d'échec de chargement (`errorWidget`, équivalent de l'ancien `errorBuilder`). Aucune modification de `BookmarkRemoteDatasource` ni du schéma Supabase.
**Clarification de portée (SPEC.md section 9) :** ce cache est un cache d'**affichage**, strictement local à l'appareil (géré par `flutter_cache_manager` sur le stockage local du device, jamais transmis à Supabase). La règle "pas de stockage de contenu tiers" de SPEC.md section 9 vise le stockage **serveur** (éviter un re-upload vers Supabase Storage, pour limiter l'exposition légale liée au droit d'auteur) — elle ne concerne pas un cache de rendu local à chaque appareil, qui n'introduit aucune copie serveur du contenu. Aucune contradiction ; SPEC.md non modifié, cette distinction ne remettant en cause aucun texte existant.
**Leçon :** un cache d'affichage local (device-only) et un stockage serveur de contenu tiers relèvent de deux préoccupations différentes malgré un vocabulaire proche ("cache"/"stockage") — vérifier l'intention réelle d'une règle métier (ici, limiter l'exposition légale liée à une copie serveur) avant de l'appliquer par excès de prudence à un mécanisme qui ne présente pas le même risque.
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 7 — `OgTagScraper`, utilitaire de scraping partagé entre Instagram/Facebook/Threads

**Contexte :** Tâche 7, les trois providers de scraping (Instagram, Facebook, Threads) ont une logique d'extraction de balises `og:title`/`og:image` strictement identique — seule l'URL interrogée diffère. La doc de `metadata_provider.dart` (Tâche 4) précise "aucune référence croisée entre providers", ce qui interdit qu'un provider en importe un autre, mais ne concerne pas un utilitaire de bas niveau partagé.
**Alternatives envisagées :** (1) dupliquer la logique de requête HTTP + extraction regex dans chacun des trois fichiers `*_provider.dart` — écarté, viole directement CONVENTIONS.md ("un fichier = une responsabilité", éviter la duplication) et rendrait un futur changement de format (ex: passage à un vrai parseur HTML) à faire trois fois ; (2) créer `lib/core/services/metadata/providers/og_tag_scraper.dart`, une classe `OgTagScraper` qui n'implémente pas `MetadataProvider` — comparable à `SourceDetector`, un utilitaire partagé et non une "référence croisée entre providers" au sens interdit par la doc de la Tâche 4.
**Décision :** option 2. `OgTagScraper.scrape(url)` retourne toujours un `OgTags` (jamais d'exception, voir entrée ci-dessus), avec extraction par regex tolérante à l'ordre des attributs (`property`/`content`) dans la balise `<meta>`, aucune plateforme scrapée ne garantissant un ordre fixe. Chaque provider l'injecte via son propre constructeur (`httpClient` optionnel, comme les autres providers), sans exposer `OgTagScraper` comme point d'injection direct — cohérent avec la convention déjà en place.
**Leçon :** "aucune référence croisée entre providers" (Tâche 4) visait à éviter qu'une plateforme dépende du comportement d'une autre, pas à interdire un utilitaire de bas niveau factorisé — distinction à faire avant de dupliquer du code par excès de prudence face à une règle mal interprétée.
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 7 — `TwitterProvider` : absence de champ titre/miniature natif dans l'oEmbed officiel de X

**Contexte :** Tâche 7, `TwitterProvider` suit "exactement le pattern de la Tâche 4" (oEmbed officiel). Contrairement à YouTube/TikTok, la réponse oEmbed de `publish.twitter.com` ne contient ni champ `title` ni `thumbnail_url` — uniquement `author_name`, `author_url`, `html` (le balisage d'embed complet), `provider_name`, etc. C'est une contrainte du format de réponse officiel de X, pas une erreur de récupération.
**Alternatives envisagées :** (1) scraper en complément les balises `og:` de la page du post pour obtenir un titre/une image — écarté, mélangerait deux stratégies (oEmbed + scraping) dans un seul provider, contredisant "chaque provider ne connaît que sa propre plateforme" au sens d'une stratégie unique et cohérente, et alourdirait `TwitterProvider` par rapport au pattern demandé ; (2) construire un titre à partir de `author_name` (ex: `"Post de {author_name} sur X"`) et laisser `thumbnailUrl` à `null` en continu, sans que cela ne déclenche `isPartial: true`.
**Décision :** option 2. `isPartial` reste `false` : le titre a bien été récupéré depuis l'endpoint officiel, l'absence de miniature est une caractéristique connue et permanente de cette réponse (pas un échec ponctuel) — `VideoMetadata.thumbnailUrl` est déjà nullable pour ce type de cas légitime (voir `video_metadata.dart`, Tâche 4).
**Leçon :** "suivre exactement le pattern d'une tâche précédente" ne garantit pas que la forme de réponse d'une nouvelle API tierce soit identique — vérifier le format réel avant de supposer qu'un champ existe, plutôt que de le caster en aveugle comme si l'API était homogène entre plateformes.
**Statut :** 🔄 Remplacé, voir entrée Tâche 17

---

## [CHOIX] Tâche 7 — Icônes de plateforme ajoutées dans `assets/icons/`, jamais câblées dans `bookmark_card.dart`

**Contexte :** Tâche 7, point 4 ("Ajoute les icônes correspondantes dans `assets/icons/`"). Le commentaire doc existant sur `_platformIcon` dans `bookmark_card.dart` (Tâche 6) annonçait explicitement des "icônes de plateforme dédiées prévues en Tâche 7" en remplacement des `Icons.*` Material génériques actuels — ce qui suggérerait de câbler les nouvelles icônes dans ce fichier. Mais la contrainte de la Tâche 7 est explicite : aucune modification des fichiers déjà validés des Tâches 4-6 en dehors de `metadata_service.dart` et `source_detector.dart` ; `bookmark_card.dart` (Tâche 6) n'y figure pas.
**Alternatives envisagées :** (1) câbler les icônes SVG dans `_platformIcon`/`bookmark_card.dart` comme le commentaire existant le laissait attendre — écarté, violerait directement la contrainte explicite de ce prompt de tâche ; (2) créer les fichiers d'icônes (`assets/icons/x.svg`, `instagram.svg`, `facebook.svg`, `threads.svg`) et déclarer le dossier dans `pubspec.yaml` (`flutter: assets:`), sans toucher à `bookmark_card.dart` — le câblage réel dans l'UI est laissé à une tâche future.
**Décision :** option 2, tension documentée plutôt que tranchée silencieusement dans un sens ou dans l'autre. `pubspec.yaml` a été modifié (ajout de la section `assets:`) : nécessaire pour que Flutter embarque ces fichiers dans le build, ce n'est pas un fichier "déjà validé Tâches 4-6" au sens de la contrainte (aucune logique métier/scraping/UI n'y est modifiée). Icônes fournies en SVG monochrome (`currentColor`), stylisées et non des reproductions exactes des logos de marque officiels, pour rester descriptives sans risque de propriété intellectuelle.
**Leçon :** un commentaire `///` qui anticipe une tâche future peut devenir obsolète si le périmètre exact de cette tâche est ensuite restreint explicitement — se fier à la contrainte la plus récente et la plus précise (le prompt de la Tâche 7 lui-même) plutôt qu'à une annotation antérieure.
**Statut :** 🟡 Partiel — fichiers d'icônes et déclaration `pubspec.yaml` prêts ; câblage dans `bookmark_card.dart` (remplacement des `Icons.*` Material par ces assets) volontairement non fait, à traiter explicitement dans une tâche future (voir `BUGS_AND_ROADMAP.md`).

---

## [CHOIX] Tâche 6.5 — `detectPatterns` iOS 16+ non implémenté, bannière système acceptée sur toutes les versions d'iOS

**Contexte :** Tâche 6.5, critère de vérification manuel mentionnant `detectPatterns` (iOS 16+) "si le plugin le permet". SPEC.md section 9 recommande cette API native pour éviter la bannière système "Runk a collé depuis…" au retour au premier plan.
**Problème :** `package:flutter/services.dart` (`Clipboard.getData`) n'expose pas `UIPasteboard.detectPatterns` — cette API nécessiterait un canal de plateforme Swift custom écrit et testé dans Xcode, indisponible dans cet environnement de développement Linux sans macOS (même limitation que la Share Extension iOS, voir DECISIONS.md Tâche 3).
**Alternatives envisagées :** (1) écrire un canal de plateforme Swift non testable dans cette session, au risque de livrer du code invérifiable ; (2) utiliser la lecture standard `Clipboard.getData` sur toutes les plateformes/versions, et documenter la limitation plutôt que de la contourner à l'aveugle.
**Décision :** option 2, cohérente avec le prompt de tâche lui-même ("bannière système native acceptée comme limitation de plateforme, documentée en commentaire `///`" pour iOS < 16 — étendu ici à iOS 16+ également, faute d'implémentation possible de `detectPatterns`). Documenté en commentaire `///` sur `ClipboardService` et dans `guide.md` section 5.4.
**Leçon :** cohérent avec la leçon déjà tirée en Tâche 3 — face à une API native non exposée par Flutter et non implémentable sans l'outillage de la plateforme cible, documenter la limitation plutôt que de livrer un correctif invérifiable.
**Statut :** 🟡 Partiel — comportement standard fonctionnel et testé (Android + logique Dart), `detectPatterns` natif iOS non implémenté, à reprendre si un environnement macOS/Xcode devient disponible (voir `BUGS_AND_ROADMAP.md`).

---

## [CHOIX] Tâche 8 — `DeepLinkService` : reconstruction générique du chemin sous le schéma natif, sauf Facebook (`facewebmodal`) et Threads (aucun schéma)

**Contexte :** Tâche 8, `openInSource(url, source)` doit tenter un schéma natif par plateforme avant le repli navigateur. Le prompt de tâche ne précise aucun schéma exact — ces conventions ne sont documentées par aucune des plateformes cibles (voir doc de classe de `deep_link_service.dart`).
**Alternatives envisagées :** (1) une transformation uniforme pour toutes les plateformes (remplacer `https://` par le schéma natif, conserver hôte + chemin + requête tels quels) ; (2) des schémas spécifiques par plateforme quand une convention tierce plus fiable est connue.
**Décision :** option 1 par défaut (Instagram `instagram://`, TikTok `snssdk1233://` — déjà mentionné dans `BUGS_AND_ROADMAP.md` avant cette tâche —, X `twitter://`, YouTube `vnd.youtube://`), avec deux exceptions documentées :
- **Facebook** : `fb://facewebmodal/f?href=<url>`, convention tierce plus spécifique pour ouvrir une URL Facebook arbitraire (la reconstruction générique hôte/chemin n'est pas connue pour fonctionner avec l'app Facebook) ;
- **Threads** : aucun schéma connu à la date de cette tâche — `_nativeUriFor` retourne `null`, `openInSource` passe alors directement au repli navigateur, systématiquement pour cette plateforme (pas une régression, un choix par défaut de sécurité face à l'absence d'information fiable).
**Décision additionnelle — visibilité de paquets (Android 11+ / iOS) :** `canLaunchUrl`/`launchUrl` sur un schéma personnalisé échouent silencieusement si le schéma n'est pas déclaré (`<queries>` sur Android, `LSApplicationQueriesSchemes` sur iOS), même si l'app cible est installée — restriction de visibilité de paquets indépendante du code Dart. Ajouté dans `android/app/src/main/AndroidManifest.xml` et `ios/Runner/Info.plist` pour les 5 schémas ci-dessus, sans quoi le critère d'acceptation de cette tâche (ouverture réelle de l'app installée) ne pourrait jamais être vérifié sur device, même avec un code Dart correct.
**Décision additionnelle — retour `bool` plutôt que `void` :** `openInSource` retourne `true`/`false` (succès d'ouverture par l'un ou l'autre moyen) plutôt que `void`, pour permettre à l'appelant (`HomeScreen`) d'informer l'utilisateur dans le cas extrême où ni le schéma natif ni le navigateur ne fonctionnent (ex: aucun navigateur sur l'appareil) — jamais un plantage, juste un signal exploitable.
**Leçon :** face à des schémas non documentés officiellement, préférer un algorithme générique unique documenté comme "best effort" à des schémas inventés au cas par cas quand aucune convention tierce fiable n'est identifiée (Threads) — et vérifier explicitement les restrictions de visibilité de paquets des deux OS, un piège fréquent qui rend `canLaunchUrl` faussement négatif sans aucune erreur explicite.
**Statut :** 🔵 Choix assumé — à revisiter si un schéma Threads fiable est identifié, ou si un des schémas actuels cesse de fonctionner (voir `BUGS_AND_ROADMAP.md`).

---

## [CHOIX] Tâche 9 — Bottom Navigation Bar ajoutée bien que non demandée explicitement par le prompt

**Contexte :** Tâche 9, création de `TagsScreen` et `SearchScreen`. Le prompt de tâche ne demande que la création de ces deux écrans — il ne mentionne aucun câblage de navigation. Or `main.dart` ne pointait jusqu'ici que directement sur `HomeScreen` (`MaterialApp.home`), sans `go_router` (dépendance présente depuis la Tâche 1 mais jamais exploitée) ni bottom nav : les deux nouveaux écrans n'auraient eu strictement aucun moyen d'être atteints depuis l'UI.
**Alternatives envisagées :** (1) créer `tags_screen.dart`/`search_screen.dart` tels quels, sans les rendre accessibles, en laissant le câblage de la navigation comme dette documentée dans `BUGS_AND_ROADMAP.md` pour une tâche future ; (2) ajouter la bottom navigation à 3 onglets (Home / Tags / Recherche) déjà spécifiée par SPEC.md section 11, en s'appuyant enfin sur `go_router`.
**Décision :** option 2, validée explicitement par l'utilisateur. `lib/app/router.dart` configure un unique `StatefulShellRoute.indexedStack` à 3 branches (Home, `/tags`, `/search`), et `lib/app/app_shell.dart` affiche la bottom nav (widget Material 3 `NavigationBar`, équivalent moderne de la "Bottom Navigation Bar" de SPEC.md). `main.dart` passe de `MaterialApp(home: ...)` à `MaterialApp.router(routerConfig: appRouter)`. `ShareIntentGate` et `SyncServiceGate` enveloppent désormais le shell entier (plutôt que `HomeScreen` seul comme depuis la Tâche 6) pour que leur `context` reste un descendant valide du `Navigator` quel que soit l'onglet actif.
**Leçon :** une dépendance ajoutée tôt mais jamais exploitée (`go_router`, comme `riverpod_generator` avant la Tâche 6, voir DECISIONS.md) reste un signal qu'un choix d'architecture était déjà pris en amont sans être mis en œuvre — la première tâche qui en a réellement besoin doit le confirmer explicitement plutôt que de contourner le manque avec un nouvel écran isolé et inatteignable.
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 9 — `SyncService` bidirectionnel (push + pull), au-delà du texte littéral "Isar → Supabase"

**Contexte :** Tâche 9, le prompt décrit `sync_service.dart` comme une "logique Isar → Supabase" (push uniquement). Mais son critère d'acceptation exige qu'un bookmark créé hors ligne sur un premier appareil apparaisse sur un second appareil connecté au même compte — ce qui suppose aussi de rapatrier (pull) vers l'Isar local de ce second appareil les lignes Supabase créées ailleurs, chose qu'aucun code existant ne faisait (`BookmarkRepository.getAllBookmarks` ne lit que le local).
**Alternatives envisagées :** (1) respecter le texte littéral du prompt (push uniquement) et documenter le critère d'acceptation multi-appareils comme non atteignable avec ce code seul ; (2) portée bidirectionnelle — `BookmarkRepository.syncPendingChanges()` (push, suppressions en priorité) **et** `BookmarkRepository.pullRemoteChanges()` (pull).
**Décision :** option 2, validée explicitement par l'utilisateur, avec une précision supplémentaire actée : la suppression distante d'un bookmark par un autre appareil doit être propagée localement. `pullRemoteChanges()` applique une résolution **last-write-wins** sur `updated_at` (décision déjà actée, SPEC.md section 13) pour les lignes modifiées ailleurs, insère les lignes distantes absentes localement, et — via `BookmarkLocalDatasource.getAllSyncedRemoteIds()` — supprime localement toute entité déjà confirmée synchronisée (`isSynced: true`, `isDeletedLocally: false`) qui n'apparaît plus dans les lignes distantes rapatriées (signe qu'elle a été supprimée depuis un autre appareil). `syncPendingChanges()` traite les suppressions locales en attente (`isDeletedLocally`) **avant** tout envoi, conformément à la contrainte explicite de la Tâche 9 et à SPEC.md section 13.
**Leçon :** un critère d'acceptation peut révéler qu'une description de tâche formulée en apparence unidirectionnelle ("X → Y") est en réalité incomplète dès qu'elle est confrontée à un scénario multi-appareils concret — vérifier le critère d'acceptation contre le texte de la tâche avant d'implémenter, plutôt que de suivre le texte à la lettre puis découvrir l'écart après coup.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 9 — Ajout de `connectivity_plus` (dépendance hors SPEC.md section 2) pour déclencher la resynchronisation à la reconnexion

**Contexte :** Tâche 9, `sync_service.dart` doit se déclencher "à la reconnexion réseau et périodiquement" (texte du prompt). Aucune dépendance de détection de connectivité n'existait dans `pubspec.yaml` — SPEC.md section 2 ne liste que les dépendances déjà en place au moment de la Tâche 1, et CONVENTIONS.md privilégie systématiquement l'outillage déjà présent avant d'ajouter une dépendance (voir DECISIONS.md, entrées Tâche 4 "Mock HTTP" et Tâche 6.5 "SharedPreferences").
**Alternatives envisagées :** (1) uniquement un `Timer.periodic` + déclenchement au retour au premier plan (réutilisant le pattern déjà en place dans `ClipboardService`), sans nouvelle dépendance, au prix d'un délai de rattrapage borné par l'intervalle du minuteur plutôt qu'une réaction immédiate à la reconnexion ; (2) ajouter `connectivity_plus`, seul moyen de réagir en temps réel à un changement d'état réseau.
**Décision :** option 2, validée explicitement par l'utilisateur — avec une précision importante actée en même temps : `connectivity_plus` ne signale qu'une interface réseau active (Wi-Fi/cellulaire rattaché), jamais un accès Internet réellement fonctionnel ni une session Supabase joignable. `SyncService` ne lui délègue donc qu'un rôle de **déclencheur d'essai** (`onConnectivityChanged` → tente `syncNow()`), jamais une garantie de succès : le seul juge d'un échec réel reste l'appel Supabase lui-même, dont l'échec est capturé exactement comme dans `BookmarkRepository` depuis la Tâche 5 (`BookmarkRemoteSyncException`, journalisé via `debugPrint`, jamais un `catch` silencieux — voir DECISIONS.md, entrée "user_id absent avant l'authentification"). `SyncService` conserve en complément un `Timer.periodic` (filet de sécurité si l'événement de connectivité est manqué ou peu fiable sur une plateforme donnée, voir la documentation de classe de `connectivity_plus`).
**Leçon :** une dépendance ajoutée pour détecter un signal externe (ici la connectivité) ne doit jamais devenir la source de vérité du succès d'une opération réseau — elle ne fait que décider *quand retenter*, la vérité sur le succès ou l'échec reste toujours au plus près de l'appel réseau réel, cohérent avec la distinction déjà actée en Tâche 5 entre "pas encore prêt à synchroniser" et un vrai échec de synchronisation.
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 9 — `sync_service.dart` placé dans `features/bookmarks/data/`, pas `core/services/` comme le suggère SPEC.md section 5

**Contexte :** Tâche 9, quatrième écart (non demandé explicitement par l'utilisateur, mais documenté ici par cohérence avec le commentaire `///` de `sync_service.dart` qui y renvoie). SPEC.md section 5 (arborescence de référence) place `sync_service.dart` sous `core/services/`. Mais sa logique manipule directement `BookmarkEntity.isSynced`/`isDeletedLocally` et appelle `BookmarkRepository`, propres à la feature bookmarks.
**Alternatives envisagées :** (1) respecter l'emplacement `core/services/` de SPEC.md — écarté, un `core/` qui importerait `BookmarkRepository` (`features/bookmarks/data/`) inverserait la dépendance `core/` → `feature/`, proscrite depuis DECISIONS.md (entrées Tâche 4 "Emplacement de `VideoSource`" et Tâche 6 "Emplacement de l'ouverture d'Isar") ; (2) `features/bookmarks/data/sync_service.dart`, à côté de `BookmarkRepository` dont il dépend directement — même raisonnement déjà appliqué à `bookmarkIsarProvider` en Tâche 6 ("ne pas anticiper une factorisation `core/` pour une techno tant qu'un seul consommateur existe").
**Décision :** option 2. SPEC.md section 5 mis à jour en conséquence (`sync_service.dart` déplacé de `core/services/` vers `features/bookmarks/data/` dans l'arborescence de référence), ainsi que l'ajout de `lib/app/app_shell.dart` (absent de l'arborescence jusqu'ici) et de `connectivity_plus` en section 2.
**Leçon :** une arborescence de référence écrite avant qu'une feature donnée n'existe encore (ici, `sync_service.dart` anticipé dès SPEC.md section 5 initiale) peut se révéler incompatible avec les règles de dépendance actées entre-temps (`core/` ne dépend jamais d'une `feature/`) — la règle de dépendance, plus fondamentale et actée par plusieurs décisions successives, prime sur l'arborescence indicative, qui doit alors être corrigée pour rester exacte.
**Statut :** ✅ Résolu

---

## [RÉSOLU] Tâche 9 — Build Android cassé par `androidx.core:core-ktx:1.18.0` (dépendance transitive de `connectivity_plus`)

**Contexte :** Tâche 9, après l'ajout de `connectivity_plus` (voir DECISIONS.md, entrée « Ajout de `connectivity_plus` »), `flutter run` sur Android échoue avant même la compilation Dart.
**Symptôme / Problème :** Gradle rejette la résolution des dépendances avec l'erreur `Dependency 'androidx.core:core-ktx:1.18.0' requires libraries and applications that depend on it to compile against version 36 or later of the Android APIs`, ainsi qu'une exigence d'AGP 8.9.1 ou supérieur. Le projet était alors sur AGP 8.7.3 (`android/settings.gradle.kts`) et `compileSdk = flutter.compileSdkVersion` (résolvait à 35, `android/app/build.gradle.kts`).
**Cause / Alternatives :** `androidx.core:core-ktx:1.18.0` est tirée transitivement par `connectivity_plus`, pas déclarée explicitement. (1) mettre à jour le SDK Flutter global pour que `flutter.compileSdkVersion` résolve nativement à 36 — écarté, effet de bord sur tout le projet et toutes les autres tâches pour un besoin localisé à une seule dépendance transitive ; (2) fixer explicitement `compileSdk = 36` dans `app/build.gradle.kts` et monter AGP à `8.9.1` dans `settings.gradle.kts` (minimum requis 8.11.1 selon le message d'erreur — en réalité la contrainte réelle observée est 8.9.1, voir Gradle déjà en 8.12 côté wrapper, suffisant sans y toucher), pattern déjà en place pour `ndkVersion` dans le même fichier (valeur explicite + commentaire `///` + renvoi DECISIONS.md).
**Fix / Décision :** option 2. `android/settings.gradle.kts` : `com.android.application` passé de `"8.7.3"` à `"8.9.1"`. `android/app/build.gradle.kts` : `compileSdk = flutter.compileSdkVersion` remplacé par `compileSdk = 36` explicite, avec commentaire `///`-style renvoyant à cette entrée. `android/gradle/wrapper/gradle-wrapper.properties` (Gradle 8.12) et la version de Kotlin (`org.jetbrains.kotlin.android`, 2.1.0) non touchées, ni nécessaires ni concernées par cette contrainte.
**Leçon :** une dépendance ajoutée pour une seule feature (ici `connectivity_plus`, Tâche 9) peut imposer transitivement des contraintes de plateforme (compileSdk, version d'AGP) sans rapport apparent avec cette feature — fixer ces valeurs explicitement au point d'usage plutôt que de faire remonter la contrainte vers une mise à jour globale du SDK Flutter, cohérent avec le traitement déjà appliqué à `ndkVersion` (voir plus haut, même fichier).
**Statut :** ✅ Résolu

---

## [RÉSOLU] Tâche 10 — `flutter test` bloqué indéfiniment dans `search_screen_test.dart` (opérations Isar réelles incompatibles avec `testWidgets` sans `runAsync`)

**Contexte :** Tâche 10, mise en place du workflow CI (`flutter analyze` + `flutter test` sur chaque PR). `flutter analyze` et `flutter test integration_test` passaient, mais `flutter test` complet ne se terminait jamais (0 % CPU après un pic initial, aucun deadlock détecté par `ps aux`), bloquant la CI avant même qu'elle ne puisse remplir son rôle (Tâche 10 exige que la CI échoue *visiblement*, pas qu'elle ne se termine jamais).

**Symptôme / Problème :** isolé à `test/widget/features/search/presentation/search_screen_test.dart`, test `'la saisie déclenche une recherche locale et affiche les résultats'`. Instrumentation par `debugPrint()` autour de chaque `await` (voir méthode dans un fichier de diagnostic temporaire, supprimé après usage) : le blocage se produisait avant même le premier `pumpWidget`, dès l'appel `await repository.createBookmark(...)` placé directement dans le corps de `testWidgets`. Un test minimal isolé (`test()` classique vs `testWidgets()`, même code) a confirmé que `Isar.open(...)` — pas seulement `createBookmark` — se bloque indéfiniment uniquement sous `testWidgets()`, jamais sous un `test()` classique.

**Cause :** `isar_community` (comme l'`isar` historique) résout ses opérations asynchrones natives (`Isar.open`, `writeTxn`, les requêtes `find*`) via un `ReceivePort` alimenté depuis un thread natif en arrière-plan qui appelle `Dart_PostCObject` (`isar_instance_create_async` / `isar_txn_begin` / `isar_q_find`, voir `package:isar_community/src/native/{open,isar_impl,query_impl}.dart`) — **jamais** via un `Timer` Dart. Or `testWidgets()` exécute le corps du test sous `AutomatedTestWidgetsFlutterBinding`, qui pilote une horloge fake et ne fait jamais tourner un vrai tour de boucle d'événements tant qu'on n'est pas explicitement sorti de cette zone via `tester.runAsync()` — un `await` réel sur un `Future` alimenté par ce mécanisme de port natif ne se résout donc jamais dans ce contexte. `setUp()`/`tearDown()` (hors du corps `testWidgets`) ne sont pas concernés, ce qui explique que l'ouverture d'Isar dans `setUp()` fonctionnait déjà normalement dans ce même fichier. Une fois ce premier blocage levé, un second est apparu au même endroit conceptuel : la recherche déclenchée par `bookmarkSearchProvider` (elle aussi un accès Isar réel, via `BookmarkRepository.searchBookmarks`) est relancée implicitement par Riverpod à la reconstruction du widget après `enterText` — `pumpAndSettle()` ne peut alors jamais conclure : non seulement l'accès Isar sous-jacent ne se résout pas hors `runAsync`, mais même une fois résolu, le `CircularProgressIndicator` affiché pendant l'état `loading` reprogramme une frame en continu et empêche structurellement `pumpAndSettle()` de « settle » avant que les données ne soient déjà disponibles.

**Alternatives envisagées :** (1) remplacer `pumpAndSettle()` par un simple `pump()` sans le comprendre — explicitement proscrit par la mission, et de toute façon insuffisant seul : sans `runAsync`, l'accès Isar réel ne se résout jamais quel que soit le nombre de `pump()` ; (2) réduire l'usage d'Isar dans les tests widgets à des doubles/fakes plutôt qu'un Isar réel en répertoire temporaire — écarté, changerait la nature du test (déjà validée en Tâche 5, voir DECISIONS.md « Tâche 5 — Isar de test via répertoire temporaire ») et masquerait la cause réelle plutôt que de la traiter ; (3) `tester.runAsync()` autour de chaque opération Isar réelle déclenchée directement par le test, complété par une attente explicite du `Future` du provider concerné (récupéré via `ProviderScope.containerOf(...)`) avant un `pump()` normal hors `runAsync` — c'est l'API officiellement prévue par `flutter_test` pour exactement ce cas (async réel non piloté par l'horloge fake : I/O, isolates, threads natifs).

**Fix / Décision :** option 3. Dans `search_screen_test.dart` : chaque `repository.createBookmark(...)` appelé directement dans un corps `testWidgets` est enveloppé dans `tester.runAsync()`. Pour la recherche déclenchée par la saisie, le test récupère le `ProviderContainer` de l'écran et attend explicitement `container.read(bookmarkSearchProvider(query).future)` à l'intérieur d'un `runAsync()`, suivi d'un unique `pump()` classique (pas `pumpAndSettle()`) pour reconstruire l'écran une fois la donnée déjà résolue — cohérent avec la remarque déjà actée en Tâche 6.5 sur la propagation asynchrone des `FutureProvider` dans les tests (voir `BUGS_AND_ROADMAP.md`, entrée Tâche 6.5).

**Écart signalé :** ceci change la stratégie de test autour de `pumpAndSettle()` dans ce fichier précis (remplacé par `pump()` explicite après attente du `Future` sous-jacent) — écart mineur et justifié au cas par cas, pas une règle générale : `pumpAndSettle()` reste utilisé sans modification partout ailleurs dans ce même fichier (ex. après le `tap` final, qui ne touche pas Isar).

**Point vérifié — tag `v0.13.8-temp-upstream-fix` du moteur Isar :** confirmé, via `strings` sur le `libisar.so` téléchargé (`Isar.initializeIsarCore(download: true)`), qu'il s'agit du tag de publication **officiel** de la distribution native `isar_community` (visible dans le binaire tel que publié, avant toute intervention de ce projet) — pas un patch appliqué localement. `libisar.so` à la racine du dépôt est non versionné (`.gitignore` ligne 52) : c'est l'artefact standard que `initializeIsarCore(download: true)` place dans le répertoire courant au premier lancement des tests, jamais vendorisé ni modifié par le projet. Aucun écart à tracer au-delà de cette clarification.

**Leçon :** un blocage à 0 % CPU sans deadlock détectable, spécifique à `testWidgets()` et absent en `test()` classique, doit faire suspecter en priorité un `Future` alimenté hors du mécanisme de Timer/microtask que l'horloge fake de `AutomatedTestWidgetsFlutterBinding` sait piloter (I/O réel, thread natif, isolate) plutôt qu'un vrai deadlock applicatif — vérifier systématiquement si la bibliothèque en cause complète ses opérations via un `ReceivePort`/port natif avant d'auditer le code applicatif en boucle.

**Suite (2026-07-31) — deux échecs préexistants marqués `skip` pour fiabiliser la CI :** une fois ce blocage levé, `flutter test` complet a révélé deux échecs sans rapport avec Isar ni avec ce blocage (masqués jusque-là, la suite ne les atteignant jamais) : `test/widget/features/tags/presentation/tags_screen_test.dart` (`'un tap sur un tag active le filtre puis revient sur Home'`, échec déterministe) et `test/unit/features/bookmarks/data/sync_service_test.dart` (`'le minuteur périodique déclenche une synchronisation'`, échec dépendant de la charge CPU en suite complète, une course contre un délai réel fixe trop court). Ces deux corrections sortent du périmètre de la Tâche 10 (CI + test d'intégration, pas correction de bugs applicatifs sans rapport). Décision, validée explicitement par l'utilisateur : les marquer `skip: true` (avec un commentaire renvoyant à `BUGS_AND_ROADMAP.md`, section "Points de vigilance techniques identifiés", entrée Tâche 10, qui détaille symptôme et hypothèse de cause pour chacun), plutôt que de les supprimer ou de les laisser rouges — la CI (`.github/workflows/ci.yml`, `flutter test` sans exclusion) doit pouvoir servir son critère d'acceptation (une régression volontaire la fait échouer visiblement) sur une base verte, sans prétendre que ces deux bugs sont résolus. `flutter test` confirmé vert ensuite : `91 passed, 2 skipped` en ~97 s.

**Statut :** ✅ Résolu (blocage) — les deux bugs révélés restent ouverts, suivis dans `BUGS_AND_ROADMAP.md`

---

## [CHOIX] Tâche 12bis — Ne pas ajouter de User-Agent navigateur à `OgTagScraper` (investigation, correctif rejeté)

**Contexte :** hypothèse non confirmée que des miniatures manquantes dès l'ajout initial (pas seulement après redémarrage, sujet distinct de la Tâche 12) s'expliqueraient par l'absence de header `User-Agent` sur la requête HTTP d'`OgTagScraper.scrape` — Instagram étant soupçonné de servir un HTML minimal aux requêtes n'ayant pas l'air de venir d'un navigateur.

**Investigation :** test manuel (script Dart autonome utilisant directement `OgTagScraper`, réseau réel, pas de mock) sur 5 liens Instagram publics (`reel/DX7PnqbFL50`, `reel/Dak0VgMFbZ-`, `p/DXWBwBAE55Q`, `p/DWwszBIE2Et`, `p/DWm8OQKlKvC`) :
- **Avant** (comportement actuel, aucun header `User-Agent` explicite → `dart:io` envoie son défaut `Dart/3.x (dart:io)`) : `og:title` et `og:image` récupérés avec succès sur les 5/5 liens, y compris en rafale (8 requêtes rapprochées sur le même lien, aucun signe de throttling).
- **Après** (ajout d'un header `User-Agent` desktop récent, ex. Chrome/Windows) : `og:title` et `og:image` **absents sur les 5/5 mêmes liens** — Instagram sert alors le shell applicatif React complet (`<title>Instagram</title>`, mur de connexion), sans balises `og:` statiques, plutôt que la page simplifiée servie à l'UA par défaut.

**Cause probable :** Instagram distingue les requêtes non identifiées comme navigateur (UA générique/inconnu, comportement proche d'un bot de prévisualisation de lien type Facebook/Slack/Twitter) et leur sert une page HTML statique légère contenant les balises `og:` — exactement le comportement dont dépend `OgTagScraper`. Un `User-Agent` de navigateur réel déclenche au contraire le rendu applicatif normal (SPA, mur de connexion), qui ne contient pas ces balises dans le HTML initial.

**Fix / Décision :** ne **pas** ajouter de header `User-Agent` à `OgTagScraper.scrape` — le comportement par défaut du client HTTP est, de façon contre-intuitive, celui qui fonctionne. Changement de code testé sur la branche `investigate/scraper-user-agent` puis **annulé** (`git checkout --`) après ce constat, pour ne pas introduire de régression. Aucun code mergé. Voir `BUGS_AND_ROADMAP.md` pour le rapport détaillé et l'historique des liens testés.

**Écart signalé :** l'hypothèse de départ du prompt (User-Agent navigateur = correctif attendu) s'est révélée fausse à l'usage — l'investigation confirme l'absence de header comme la configuration correcte plutôt que de proposer le correctif initialement pressenti.

**Leçon :** ne jamais supposer qu'imiter un navigateur réel est systématiquement la meilleure stratégie de scraping — certaines plateformes réservent leur HTML statique riche en métadonnées (`og:`) aux requêtes qui *ne* ressemblent *pas* à un navigateur (comportement de bot de prévisualisation de lien), et cassent ce même contenu pour un vrai navigateur (SPA + mur de connexion). Toujours valider un changement de header HTTP par un test avant/après sur des cas réels plutôt que sur la seule plausibilité de l'hypothèse.

**Statut :** 🔵 Choix assumé (ne pas modifier `og_tag_scraper.dart`) — cause réelle des miniatures manquantes à l'ajout initial toujours non identifiée, reste ouvert (voir `BUGS_AND_ROADMAP.md`, section Points de vigilance techniques identifiés)

---

## [CHOIX] Tâche 13 — Passage d'un champ Tags texte libre à une liste de tags avec autocomplétion

**Contexte :** Tâche 13, `AddBookmarkSheet`. Le champ Tags était jusqu'ici un unique `TextField` texte libre, tags séparés par des virgules, parsés uniquement à la sauvegarde (`_parseTags`). Le prompt de tâche demande d'afficher des suggestions issues de `distinctTagsProvider` (préfixe insensible à la casse) sous le champ, et qu'un tap sur une suggestion « l'ajoute à la liste de tags en cours de saisie (sans dupliquer un tag déjà présent) », ce qui suppose une liste de tags déjà validés à distance de ce qui est en train d'être tapé — la formulation même de la tâche implique un changement de modèle du champ, pas une simple superposition d'un `Overlay` sur le `TextField` existant.

**Alternatives envisagées :**
1. Garder le `TextField` unique à texte libre séparé par virgules, et superposer une liste de suggestions calculée sur le dernier segment tapé après la dernière virgule — techniquement possible, mais la notion de « liste de tags en cours de saisie » distincte du texte brut n'existe pas dans ce modèle, rendant la déduplication ambiguë (faut-il comparer au texte entier ou à chaque segment ?) et l'UX de suppression d'un tag individuel malaisée (retrouver puis effacer un segment au milieu d'une chaîne).
2. Remplacer par un composant à liste de tags validés (`Chip`s, retirables) + un `TextField` ne portant que le tag en cours de frappe, les suggestions filtrant `distinctTagsProvider` sur ce texte en cours et excluant les tags déjà ajoutés ; validation manuelle d'un tag non suggéré via soumission du champ (`onSubmitted`), en plus du tap sur suggestion.

**Décision :** option 2, extraite dans un nouveau widget dédié `TagInputField` (`lib/features/bookmarks/presentation/tag_input_field.dart`) — cohérent avec CONVENTIONS.md section Partials/Frontend (pas de widget anonyme complexe inline dans `AddBookmarkSheet.build`). `_AddBookmarkSheetState` ne garde qu'un état `List<String> _tags`, remplaçant `_tagsController`/`_parseTags()`. `TagInputField` ne lit `distinctTagsProvider` que via `ref.watch` (aucun accès direct à Isar), conformément à la contrainte de la tâche.
**Choix additionnels non explicitement tranchés par le prompt, documentés ici plutôt que silencieusement :**
- Déduplication insensible à la casse (`'Cuisine'` et `'cuisine'` sont considérés comme le même tag) — une suggestion reprise depuis `distinctTagsProvider` pourrait sinon dupliquer visuellement un tag déjà tapé avec une casse différente.
- Ajout manuel d'un tag non suggéré conservé via soumission du champ (`onSubmitted`, touche "Terminé"/Entrée), pour ne pas régresser la possibilité de créer un tag inédit qu'offrait implicitement l'ancien champ texte libre.
- Liste de suggestions bornée en hauteur (`maxHeight: 160`) et affichée en flux normal sous le champ (pas un `Overlay`/`Autocomplete` plein écran), conformément à la contrainte explicite de ne jamais masquer le reste de la modale.

**Leçon :** quand un critère d'acceptation décrit un comportement (« liste de tags en cours de saisie », dédoublonnage) incompatible avec le modèle de données actuel d'un champ (texte brut séparé par virgules), ne pas forcer ce comportement par-dessus l'ancien modèle — vérifier si la tâche implique un changement de représentation sous-jacente avant d'implémenter, et l'extraire dans son propre composant plutôt que d'alourdir le widget appelant.

**Statut :** ✅ Résolu

---

## [RÉSOLU] Tâche 14 — Boutons de confirmation explicites (ajout de lien / ajout de tag)

**Contexte :** retour de test manuel — le libellé "Enregistrer" du bouton principal d'`AddBookmarkSheet` était incohérent avec le libellé "Ajouter" déjà utilisé pour la même action (ajouter un lien) dans `clipboard_suggestion_banner.dart`, et la validation d'un tag tapé manuellement dans `TagInputField` (Tâche 13) ne disposait que de la soumission clavier (`onSubmitted`), sans affordance visuelle explicite.

**Symptôme / Problème :** vocabulaire incohérent pour la même action selon le point d'entrée (bannière clipboard vs modale d'ajout), et absence de bouton visible pour valider un tag — seule la touche "Terminé"/Entrée du clavier le permettait, non découvrable sans essai.

**Fix / Décision :**
- `add_bookmark_sheet.dart` : libellé du `FilledButton.icon` de sauvegarde changé de `'Enregistrer'` à `'Ajouter'`, aucun changement de comportement (toujours `_save`, toujours désactivé pendant `_isSaving`).
- `tag_input_field.dart` : le `TextField` de saisie de tag est désormais dans un `Row`, accompagné d'un `IconButton.filled` (icône `Icons.add`, tooltip "Ajouter ce tag") qui appelle `_addTag(_controller.text)` — exactement la même méthode que `onSubmitted`, donc même règle de déduplication insensible à la casse et même vidage du champ après ajout. Ce bouton ne manipule que l'état local `_tags` de `_AddBookmarkSheetState` (remonté via `onTagsChanged`) — aucune persistance avant la sauvegarde finale du bookmark via `BookmarkRepository`, conformément à la contrainte de la tâche.
- `integration_test/app_flow_test.dart` : occurrences de `'Enregistrer'` mises à jour vers `'Ajouter'` pour rester cohérentes avec le nouveau libellé.

**Alternatives envisagées :** un simple `Icon(Icons.add)` sans fond (`IconButton` standard) plutôt que `IconButton.filled` — écarté au profit de la variante remplie, plus proche visuellement d'une action de validation explicite (cohérent avec le critère d'acceptation « bouton "+" ») qu'une icône discrète pouvant se confondre avec une simple décoration.

**Écart signalé :** le prompt ne précisait pas explicitement s'il fallait mettre à jour `integration_test/app_flow_test.dart` (qui référençait l'ancien libellé `'Enregistrer'`) — mis à jour pour éviter une régression de test non liée au périmètre fonctionnel de la tâche, mais strictement mécanique (renommage du texte cherché).

**Leçon :** un changement de libellé de bouton, même trivial en apparence, doit être recherché dans toute la base (`grep`) avant d'être considéré terminé — les tests d'intégration qui font `find.text(...)` sur un libellé UI cassent silencieusement sinon (ici détecté avant commit grâce à `flutter test integration_test`, pas après).

**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 15 — `TagEntity` : gestion indépendante des tags (proposition, questions ouvertes — Phase A, aucun code écrit)

**Contexte :** besoin exprimé de pouvoir créer, renommer et supprimer un tag indépendamment de tout bookmark, depuis `TagsScreen`. Aujourd'hui un tag n'existe pas en tant qu'entité : `BookmarkEntity.tags` (SPEC.md section 3.3) est un simple `List<String>` porté par chaque bookmark, et `distinctTagsProvider` (`lib/features/tags/presentation/distinct_tags_provider.dart`) ne fait que dériver l'ensemble des tags distincts à partir de `bookmarkListProvider` — aucune source de vérité n'existe indépendamment des bookmarks. Il est donc structurellement impossible aujourd'hui qu'un tag existe sans être rattaché à au moins un bookmark, ce que la demande implique par construction (« créer un tag depuis `TagsScreen` sans aucun bookmark associé »).

**Symptôme / Problème :** répondre au besoin exige d'introduire une nouvelle collection Isar (`TagEntity`), absente de SPEC.md section 3.3 — changement de modèle de données non trivial, avec trois points de comportement non tranchés par la demande elle-même. Conformément à la règle du projet (aucune ambiguïté n'est tranchée silencieusement), ces points sont documentés ici comme des **questions ouvertes**, pas comme des décisions déjà prises. Aucun fichier `.dart` n'a été modifié pour cette entrée, aucun commit n'a été fait.

**Proposition de schéma (a minima, à valider) :**
```dart
@collection
class TagEntity {
  Id isarId = Isar.autoIncrement;
  @Index(unique: true, caseSensitive: false)
  late String name;
}
```
Index unique insensible à la casse pour rester cohérent avec la déduplication déjà actée en Tâche 13 (`'Cuisine'`/`'cuisine'` traités comme un seul tag dans `TagInputField`).

**Questions ouvertes :**

1. **Suppression d'un tag — cascade ou non ?**
   - Option A (cascade) : supprimer un `TagEntity` retire aussi ce tag de `BookmarkEntity.tags` sur tous les bookmarks qui l'utilisent (parcours + réécriture de chaque bookmark concerné, propagation potentielle vers Supabase via `isSynced = false`).
   - Option B (non-cascade) : supprimer un `TagEntity` le retire uniquement de la liste de gestion (`TagsScreen`) ; les bookmarks existants gardent le tag tel quel dans leur `List<String>`, qui redeviendrait alors visible dans `distinctTagsProvider` dès qu'au moins un bookmark le porte encore (le tag « réapparaîtrait » de fait, dérivé des bookmarks, même après suppression de son `TagEntity`).
   - Tension à trancher : l'option B rend le mot « supprimer » trompeur pour l'utilisateur (le tag reste visible et filtrable tant qu'un bookmark le porte) ; l'option A est plus intuitive mais touche potentiellement un grand nombre de bookmarks en une seule action et doit repasser par la synchronisation Supabase (coût, et risque vis-à-vis de la politique last-write-wins si un autre appareil modifie le même bookmark en parallèle, voir SPEC.md section 13).

2. **Renommage d'un tag — propagation ou non dans `BookmarkEntity.tags` ?**
   - Option A (propagation) : renommer un `TagEntity` met à jour `tags` sur tous les bookmarks qui le portent (remplacement de l'ancienne valeur par la nouvelle), avec les mêmes implications de coût/sync que la suppression en cascade ci-dessus.
   - Option B (non-propagation) : renommer un `TagEntity` ne change que l'entité de gestion ; les bookmarks déjà tagués gardent l'ancien libellé, qui coexisterait alors comme un tag distinct dérivé (ancien nom) à côté du nouveau `TagEntity` (nouveau nom) dans l'autocomplétion.
   - Tension à trancher : l'option B produit une divergence durable entre le nom « géré » et le nom réellement porté par les bookmarks existants (deux tags visuellement différents pour ce qui était censé être un renommage) ; symétrique de la question 1.

3. **Fusion dans `distinctTagsProvider` (ou nouveau provider dédié) — comment éviter les doublons ?**
   - Le provider actuel dérive uniquement des bookmarks. Il faudra fusionner cet ensemble avec les noms des `TagEntity` existants (y compris ceux sans aucun bookmark associé), en dédupliquant de façon insensible à la casse (cohérent avec Tâche 13) — mais quelle casse afficher en cas de divergence (ex. un `TagEntity.name = 'Cuisine'` et un bookmark taggé `'cuisine'`) ? Priorité au `TagEntity` géré, ou au tag le plus utilisé ?
   - Question annexe : si les réponses aux questions 1 et 2 sont « non-propagation », un tag purement dérivé des bookmarks (sans `TagEntity` correspondant, ex. après un renommage non propagé) reste-t-il éditable/supprimable depuis `TagsScreen` comme s'il avait un `TagEntity` — ce qui impliquerait de le créer à la volée — ou seulement affiché en lecture seule ?

**Fix / Décision :** les trois questions ont été tranchées par l'utilisateur : suppression en cascade, renommage propagé, tag dérivé éditable avec création implicite de son `TagEntity`. Voir l'entrée « Tâche 15 — Implémentation » ci-dessous pour le détail de la mise en œuvre.

**Leçon :** poser les questions de modèle de données comme options explicites plutôt que de deviner un comportement "raisonnable" a permis de trancher les trois en une seule fois, sans aller-retour supplémentaire une fois la Phase B lancée.

**Statut :** 🟡 Révisé — voir « Tâche 15 — Implémentation de la gestion indépendante des tags » ci-dessous. Entrée conservée pour l'historique des questions posées, ne pas supprimer.

---

## [RÉSOLU] Tâche 15 — Implémentation de la gestion indépendante des tags (`TagEntity`, `TagRepository`)

**Contexte :** Phase B de la Tâche 15, suite à la décision actée ci-dessus. Branche `feat/standalone-tag-management`.

**Décisions de modèle appliquées (rappel, actées par l'utilisateur en Phase A) :**
- Suppression d'un tag = cascade : retire le tag de tous les `BookmarkEntity.tags` qui le portent, avec confirmation utilisateur affichant le nombre de bookmarks impactés.
- Renommage d'un tag = propagation : met à jour tous les `BookmarkEntity.tags` concernés.
- Un tag purement dérivé (aucun `TagEntity`) reste éditable comme un tag géré ; le renommer ou le supprimer depuis `TagsScreen` crée implicitement son `TagEntity` (renommage) ou l'ignore silencieusement (suppression, rien à retirer).
- Fusion dans `distinctTagsProvider` : dédoublonnage insensible à la casse, priorité d'affichage à la casse du `TagEntity` géré s'il existe pour ce nom normalisé.

**Symptôme / Problème technique rencontré :** la contrainte explicite de la tâche ("suppression/renommage dans une **même** transaction Isar, pas d'écriture en deux temps") s'est heurtée à une limite du package : Isar (`isar_community`) **interdit explicitement les transactions imbriquées** — `Zone.current[_zoneTxn]` est vérifié par `_requireNotInTxn()` (`isar_common.dart`), et un `writeTxn` appelé depuis l'intérieur d'un `writeTxn` déjà actif lève `IsarError: Isar does not support nesting transactions` (vérifié en lisant le code source du package dans `~/.pub-cache`, pas supposé). Or `BookmarkLocalDatasource.upsert`/`TagLocalDatasource.upsert` ouvrent chacun leur propre `writeTxn` — impossible de les composer tels quels dans une transaction unique couvrant les deux collections.

**Cause / Alternatives :**
1. Garder deux instances Isar séparées (une par feature, chacune dans son propre fichier) — écarté d'emblée : deux instances Isar ne peuvent jamais partager une transaction, ce qui aurait rendu l'atomicité demandée (suppression/renommage en une seule transaction) impossible par construction.
2. Une seule instance Isar partagée (les deux schémas ouverts par le même `Isar.open`), et laisser `TagRepository` composer lui-même la transaction en appelant les collections Isar directement (`_isar.tagEntitys`/`_isar.bookmarkEntitys`) pour les méthodes `renameTag`/`deleteTag`, plutôt que par les méthodes d'écriture des datasources (qui restent utilisées pour les cas à collection unique : `createTag`, et pour toutes les lectures, qui elles n'ouvrent jamais de transaction et se composent sans problème — vérifié aussi dans le code source, `getTxn(false, ...)` réutilise la transaction active si elle existe déjà).

**Fix / Décision :** option 2. Conséquences architecturales, documentées dans le code (voir doc de classe de `bookmarkIsarProvider` et de `TagRepository`) :
- `bookmarkIsarProvider` (`lib/features/bookmarks/data/bookmark_repository_provider.dart`) ouvre désormais `[BookmarkEntitySchema, TagEntitySchema]` dans une seule instance, partagée par `bookmarkRepositoryProvider` et le nouveau `tagRepositoryProvider`. Reste dans `features/bookmarks/data/` plutôt que déplacé (pas de nouveau composant "composition root" introduit pour un seul point d'ouverture, même raisonnement que Tâche 6.5).
- `TagRepository` reçoit l'instance `Isar` brute en plus de `TagLocalDatasource`/`BookmarkLocalDatasource`, uniquement pour composer la transaction unique de `renameTag`/`deleteTag` — les lectures (`findByName`, `findAllByTag`) restent déléguées aux datasources.
- Dépendance croisée à double sens entre `features/bookmarks/data/` et `features/tags/data/` : `bookmark_repository_provider.dart` importe `TagEntitySchema` (pour l'ouverture combinée), `tag_repository_provider.dart`/`tag_repository.dart` importent `BookmarkLocalDatasource`/`BookmarkEntity` (pour la cascade). Direction jugée acceptable : symétrique à la dépendance déjà existante côté présentation (`distinct_tags_provider.dart` dépend de `bookmark_list_provider.dart` depuis la création de `TagsScreen`, Tâche 9) et sans alternative propre trouvée dans l'architecture actuelle (`core/` ne peut pas porter cette logique sans inverser la règle "`core/` ne dépend jamais d'une `feature/`", voir DECISIONS.md entrée Tâche 4).
- `distinctTagsProvider` fusionne désormais `bookmarkListProvider` (tags dérivés) et `tagRepositoryProvider.getManagedTagNames()` (tags gérés), contrat public inchangé (`Future<List<String>>`) — `TagInputField`/l'autocomplétion de `AddBookmarkSheet` non modifiés.
- `TagsScreen` : bouton "+" (`AppBar`), menu contextuel par tag (`PopupMenuButton`, "Renommer"/"Supprimer"), dialogues extraits dans `tag_action_dialogs.dart` (cohérent avec CONVENTIONS.md, pas de widget anonyme complexe inline). Après toute mutation, `distinctTagsProvider` est invalidé et `bookmarkListProvider.refresh()` est appelé (les tags affichés sur `BookmarkCard` peuvent changer suite à une cascade).

**Vérification :** `flutter analyze` propre. `flutter test` : 108 passed, 2 skipped (préexistants, sans rapport, voir entrée Tâche 10) — nouveaux tests : `tag_repository_test.dart` (7 cas : création, doublon de casse en no-op, renommage propagé sur plusieurs bookmarks, renommage d'un tag purement dérivé avec création implicite du `TagEntity`, suppression en cascade, comptage des bookmarks impactés), extensions de `distinct_tags_provider_test.dart` (fusion, priorité de casse) et `tags_screen_test.dart` (création/renommage/suppression avec confirmation, via widget tests bout en bout sur `TagsScreen` réel). `flutter test integration_test -d linux` toujours vert (le flux Share Intent → Metadata → Save, qui passe par `AddBookmarkSheet`/`TagInputField`/`distinctTagsProvider`, continue de fonctionner avec l'instance Isar partagée). Application relancée via `flutter run -d linux` : démarrage propre, ouverture Isar avec les deux schémas sans erreur.

**Écart signalé :** aucun appareil physique Android/iOS ni émulateur disponible dans cette session (limitation déjà documentée dans plusieurs entrées précédentes) — le rendu réel des dialogues de création/renommage/suppression et du menu contextuel sur petit écran reste à valider visuellement par l'utilisateur.

**Leçon :** avant de concevoir une opération "transaction unique" entre deux collections d'un même moteur de données, vérifier le support réel des transactions imbriquées dans le code source du package plutôt que de le supposer — Isar les interdit explicitement, ce qui a directement dicté l'architecture (instance unique partagée, composition manuelle de la transaction dans le repository) plutôt qu'une simple préférence de style.

**Statut :** ✅ Résolu

---

## [RÉSOLU] Tâche 16 — Extraction d'URL depuis un texte de partage libre (bug partage TikTok Lite)

**Contexte :** `ShareIntentService._isValidUrl` exigeait que l'intégralité de la chaîne partagée soit une URL valide. TikTok Lite partage un texte libre entourant le lien réel de texte promotionnel et d'un second lien non pertinent (ex: `"Check out Sarafina's video! #TikTok https://vm.tiktok.com/ZS4BB5Rc7/ This post is shared via TikTok Lite. Download TikTok Lite to enjoy more posts: https://www.tiktok.com/tiktoklite"`), ce qui faisait échouer la validation sur la chaîne entière — le partage était rejeté silencieusement, sans qu'aucune erreur ne soit visible pour l'utilisateur.

**Symptôme / Problème :** bug constaté sur test manuel réel (partage depuis TikTok Lite). YouTube/Instagram partagent un lien nu (fonctionnaient déjà) ; TikTok Lite partage un texte libre avec parfois deux URLs, la seconde étant purement promotionnelle et sans rapport avec la vidéo partagée.

**Cause / Alternatives :** (1) assouplir `_isValidUrl` pour accepter un texte contenant une URL en le validant tel quel (`Uri.tryParse` sur la chaîne entière échouerait toujours à cause du texte environnant) — ne résout rien ; (2) extraire toutes les sous-chaînes ressemblant à une URL `http`/`https` via une regex (`RegExp(r'https?://\S+')`), nettoyer la ponctuation finale parasite éventuellement collée (point, parenthèse fermante, etc.), puis choisir parmi les URLs valides trouvées celle dont `SourceDetector.detect` reconnaît une plateforme (≠ `VideoSource.unknown`) plutôt que la première de la liste — pour ne pas dépendre de la position du lien pertinent dans le texte. Si aucune URL trouvée ne correspond à une plateforme reconnue, la première URL valide est conservée malgré tout, cohérent avec le fait que `ShareIntentService` ne doit connaître aucune liste de plateformes en dur (seulement s'appuyer sur `SourceDetector`, déjà partagé par le reste du code).

**Fix / Décision :** option 2. Nouvelle méthode privée `ShareIntentService._extractBestUrl(text)`, appelée par `_handleSharedMedia` avant `_isValidUrl`. Une chaîne déjà entièrement constituée d'une URL nue (cas YouTube/Instagram) traverse cette extraction sans changement de comportement — un seul candidat est trouvé, retourné tel quel. Aucune dépendance ajoutée (regex simple, pas de package de parsing).

**Vérification :** nouveau test unitaire dans `share_intent_service_test.dart` reproduisant exactement le texte de partage TikTok Lite ci-dessus (avec les deux liens) — confirme qu'uniquement `https://vm.tiktok.com/ZS4BB5Rc7/` est émis sur `sharedUrlStream`. Test existant (URL nue, texte sans lien) inchangé et toujours vert. `flutter analyze` propre. `flutter test -j 1` : 109 passed, 2 skipped (préexistants, sans rapport, voir entrée Tâche 10).

**Leçon :** un service qui valide une entrée partagée par un système tiers ne doit pas supposer que toute plateforme partage un lien nu — certaines apps (TikTok Lite) enrobent le lien de texte libre et de liens additionnels non pertinents ; extraire puis désambiguïser via la logique de détection déjà existante (`SourceDetector`) évite d'introduire une nouvelle dépendance à la liste des plateformes dans une couche qui ne doit pas la connaître.

**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 17 — `TwitterProvider` : scraping `og:image` complémentaire malgré la fiabilité moindre, en remplacement de l'entrée "Tâche 7 — `TwitterProvider` : absence de champ titre/miniature natif dans l'oEmbed officiel de X"

**Contexte :** l'entrée ci-dessus ("Tâche 7 — `TwitterProvider` : absence de champ titre/miniature natif dans l'oEmbed officiel de X") actait explicitement l'absence de miniature comme un choix assumé, et écartait le scraping `og:` en complément de l'oEmbed comme option — au motif de ne pas mélanger deux stratégies dans un seul provider et d'alourdir `TwitterProvider` par rapport au pattern demandé à l'époque (Tâche 7). Nouvelle demande explicite (Tâche 17) : le contexte produit a changé — obtenir une image, même de façon moins fiable qu'un oEmbed, est désormais préféré à l'absence systématique de miniature pour les posts X.

**Alternatives envisagées :** (1) garder `TwitterProvider` inchangé (statu quo de la Tâche 7) — écarté, contredit la demande explicite de cette tâche ; (2) remplacer entièrement l'oEmbed par du scraping `og:` (comme Instagram/Facebook/Threads) — écarté, le titre via `author_name` de l'oEmbed officiel reste une source strictement plus fiable qu'un `og:title` scrapé, et la tâche ne demande de scraper qu'un complément d'image, pas de remplacer la source du titre ; (3) conserver l'oEmbed comme unique source du titre, et ajouter un scraping `og:image` complémentaire de la page du post via `OgTagScraper` (déjà utilisé par Instagram/Facebook/Threads, réutilisé tel quel), dont l'échec (fréquent, X bloquant couramment le scraping automatisé) reste toujours silencieux — `thumbnailUrl` reste `null`, `isPartial` reste `false`, exactement comme avant.

**Décision :** option 3. `TwitterProvider` reçoit un second champ, un `OgTagScraper` dédié à la miniature, avec un timeout court propre (2s) indépendant de l'appel oEmbed déjà effectué, pour ne jamais faire dépasser le budget global de 5s de `MetadataService` (SPEC.md section 9) si seul ce scraping complémentaire traîne. `OgTagScraper.scrape` ne lève par construction aucune exception (voir DECISIONS.md, entrée "Tâche 7 — `OgTagScraper`, utilitaire partagé") : aucun `try/catch` supplémentaire n'est nécessaire dans `TwitterProvider` pour garantir qu'un échec de ce scraping ne remonte jamais à l'appelant. Le titre continue de venir exclusivement de `author_name` (oEmbed) — le `og:title` scrapé, s'il existe, n'est jamais lu ni utilisé.

**Vérification empirique (constat non anticipé par le prompt de tâche) :** un test manuel réseau réel (script Dart autonome, sans mock) contre `https://x.com/i/status/2083336273922765201` (post avec média) confirme le cas nominal : `title='Post de Nona manis sur X'`, `thumbnailUrl='https://pbs.twimg.com/amplify_video_thumb/.../NKFLog3zTl8VUtll.jpg'`, `isPartial=false`. Un second test contre un post historiquement texte seul (`https://x.com/jack/status/20`) montre que X expose malgré tout une balise `og:image` — mais celle-ci pointe vers la photo de profil de l'auteur, pas une image spécifique au post (`title='Post de jack sur X'`, `thumbnailUrl` = avatar de `@jack`, `isPartial=false`). Le prompt de tâche anticipait plutôt une absence totale d'image pour ce cas ; en pratique X sert un `og:image` générique de repli (avatar) même sans média spécifique. Le comportement du code reste conforme à la demande (aucune distinction entre "image spécifique au post" et "avatar de repli" n'a été demandée ni implémentée) — documenté ici pour ne pas laisser croire que `thumbnailUrl` reste systématiquement `null` sur un post texte seul : il peut être non-`null` mais représenter l'avatar de l'auteur plutôt qu'un contenu du post.

**Vérification :** `flutter analyze` propre. `flutter test` : suite complète verte (2 skipped préexistants et sans rapport, voir entrée Tâche 10) — `twitter_provider_test.dart` étendu de 2 nouveaux cas (miniature récupérée via `og:image` mocké ; scraping en échec silencieux, titre oEmbed conservé, `thumbnailUrl: null`, `isPartial: false`), en plus des cas existants (titre via `author_name`, exception si l'oEmbed échoue).

**Leçon :** une décision documentée comme "choix assumé" n'est pas immuable — un changement de contexte produit explicite (préférer une image moins fiable à l'absence d'image) justifie de la remplacer, à condition de tracer la décision précédente plutôt que de l'effacer (traçabilité de l'historique des choix). Par ailleurs, une hypothèse du prompt de tâche sur le comportement empirique d'une plateforme tierce (« X ne renvoie généralement aucune image spécifique » pour un post texte) mérite d'être vérifiée sur le réseau réel plutôt que supposée : ici l'hypothèse s'est révélée partiellement inexacte (image de repli générique plutôt qu'absence totale), sans que cela ne remette en cause le code livré.

**Statut :** ✅ Résolu

---

## [RÉSOLU] Tâche 18 — Extraction d'URL depuis un texte de presse-papier (bug détection clipboard TikTok) + factorisation

**Contexte :** `ClipboardService._checkClipboard`/`_isValidUrl` avait exactement la même limitation que `ShareIntentService` avant la Tâche 16 (voir entrée ci-dessus) : elle exigeait que l'intégralité du contenu du presse-papier soit une URL valide. Quand TikTok Lite copie un texte libre contenant le lien (caption + lien, même format que pour le partage), la détection échouait silencieusement — aucune bannière de suggestion n'apparaissait. L'entrée `ClipboardService._isValidUrl` anticipait déjà ce cas ("deux occurrences courtes ne justifient pas encore un utilitaire partagé... voir BUGS_AND_ROADMAP.md si une 3e apparaît") : cette 3e occurrence est arrivée avec cette tâche.

**Symptôme / Problème :** copier dans le presse-papier `"Check out Sarafina's video! #TikTok https://vm.tiktok.com/ZS4BB5Rc7/ This post is shared via TikTok Lite. Download TikTok Lite to enjoy more posts: https://www.tiktok.com/tiktoklite"` puis revenir au premier plan sur Runk ne faisait apparaître aucune bannière de suggestion, faute d'une URL nue en entrée de `_isValidUrl`.

**Cause / Alternatives :** la logique nécessaire (extraire toute sous-chaîne `http(s)://\S+`, nettoyer la ponctuation finale parasite, préférer l'URL reconnue par `SourceDetector.detect`, repli sur la première URL valide sinon) existait déjà, dupliquée dans `ShareIntentService._extractBestUrl` (Tâche 16). Alternatives : (1) dupliquer cette logique une 3e fois directement dans `ClipboardService` — écarté, exactement le signal documenté à la Tâche 16 pour déclencher la factorisation ; (2) extraire la logique dans un utilitaire pur partagé, comparable à `SourceDetector` (aucune dépendance Flutter/Isar/Riverpod), réutilisé par les deux services.

**Fix / Décision :** option 2. Nouveau `lib/core/utils/url_text_extractor.dart` (classe `UrlTextExtractor`, méthode statique `extractBestUrl(String text)`), reprenant exactement le comportement de l'ancien `ShareIntentService._extractBestUrl`/`_stripTrailingPunctuation`/`_isValidUrl`. `ShareIntentService` délègue désormais à cet utilitaire (ses méthodes privées d'extraction supprimées, comportement observable inchangé — `share_intent_service_test.dart` et `share_intent_processing_provider_test.dart` non modifiés et toujours verts). `ClipboardService._checkClipboard` appelle `UrlTextExtractor.extractBestUrl` sur le texte brut du presse-papier avant la vérification `SourceDetector.detect` existante, à la place de son ancien `_isValidUrl` qui exigeait une chaîne entièrement URL — celui-ci est supprimé.

**Vérification :** nouveau test unitaire dans `clipboard_service_test.dart` reproduisant le texte de presse-papier TikTok Lite ci-dessus, confirmant que seul `https://vm.tiktok.com/ZS4BB5Rc7/` est proposé via `suggestedUrlStream` (pas le lien promotionnel). `flutter analyze` propre. `flutter test -j 1` (suite complète) : vert, mêmes 2 skipped préexistants et sans rapport (voir entrée Tâche 10) ; tous les tests existants de `share_intent_service_test.dart` et `share_intent_processing_provider_test.dart` passent sans modification de leur attente.

**Leçon :** un commentaire qui documente explicitement un seuil ("2 occurrences ne justifient pas encore une factorisation, voir si une 3e apparaît") est un marqueur à surveiller activement, pas une note qu'on oublie — dès que la 3e occurrence attendue se présente, factoriser immédiatement plutôt que de la dupliquer une fois de plus.

**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 19 — Couleur d'accent de `ClipboardSuggestionBanner` : `colorScheme.primaryContainer`, pas une couleur codée en dur

**Contexte :** Tâche 19, renforcement visuel de `ClipboardSuggestionBanner` (`MaterialBanner` par défaut jugé trop discret lors d'un test manuel). Le prompt de tâche demande une "couleur d'accent plus marquée... cohérente avec la charte sombre de SPEC.md section 10", mais SPEC.md section 10 précise explicitement que la palette détaillée (couleurs, typographie) "reste à définir lors de la phase UI" — aucune valeur hexadécimale n'existe encore nulle part dans le projet, et `main.dart` utilise `ThemeData.dark(useMaterial3: true)` sans `ColorScheme` personnalisé.

**Alternatives envisagées :** (1) choisir une couleur codée en dur (`Color(0xFF...)`) directement dans `clipboard_suggestion_banner.dart`, en anticipant une charte qui n'existe pas encore — risque de couleur non réconciliée avec la future palette de la phase UI, et de valeur isolée hors de tout système de theming ; (2) s'appuyer sur `Theme.of(context).colorScheme.primaryContainer` (+ `onPrimaryContainer` pour le texte/les icônes/les boutons), déjà dérivé par Material 3 depuis la seed color par défaut du thème existant.

**Décision :** option 2. `backgroundColor: colorScheme.primaryContainer`, contenu/icône/boutons en `colorScheme.onPrimaryContainer` pour un contraste garanti. Cohérent avec le thème Material 3 sombre déjà en place, sans introduire de valeur de couleur isolée avant que la charte graphique ne soit tranchée — si une palette de marque personnalisée est définie plus tard (`ColorScheme.fromSeed` ou palette codée en dur dans `main.dart`), la bannière en héritera automatiquement sans modification de `clipboard_suggestion_banner.dart`.

**Vérification physique :** un appareil Android réel était connecté durant cette session (`adb devices` → `SCG10`, Android 15) — voir aussi l'entrée ci-dessous. `flutter run -d <device>` confirme que la bannière s'affiche avec un fond violet nettement distinct du reste de `HomeScreen` (fond sombre neutre), lisible, cohérent avec le thème Material 3 par défaut.

**Leçon :** quand un prompt de tâche demande une "couleur cohérente avec la charte" alors que la charte elle-même est explicitement documentée comme non définie, préférer dériver la couleur du système de theming déjà en place (`ColorScheme`) plutôt que d'en inventer une — la cohérence future avec une charte pas encore écrite est ainsi garantie par construction.

**Statut :** 🔵 Choix assumé — à revisiter si `main.dart` adopte un `ColorScheme.fromSeed`/une palette de marque dédiée lors de la phase UI (SPEC.md section 10) : `colorScheme.primaryContainer` en héritera automatiquement, aucune modification attendue dans `clipboard_suggestion_banner.dart`.

---

## [RÉSOLU] Tâche 19 — Renforcement visuel de `ClipboardSuggestionBanner` (couleur, animation, haptique) + validation sur appareil physique réel

**Contexte :** Tâche 19, `clipboard_suggestion_banner.dart` jugé peu visible lors d'un test manuel (`MaterialBanner` par défaut, fond neutre, apparition instantanée). Une popup centrée bloquante avait été explicitement écartée en amont (contredirait SPEC.md section 4 règle 7 et section 11) — la demande porte donc uniquement sur un renforcement de présentation du `MaterialBanner` existant, sans toucher au texte, aux deux actions ni à leur comportement.

**Décision :**
1. **Couleur** : `backgroundColor: colorScheme.primaryContainer` / contenu et actions en `colorScheme.onPrimaryContainer` — voir entrée dédiée ci-dessus pour le choix de ne pas coder une couleur en dur.
2. **Animation d'apparition** : `AnimatedSwitcher` (300 ms) enveloppant soit `SizedBox.shrink()` (clé `'clipboard-banner-empty'`), soit le `MaterialBanner` (clé `'clipboard-banner-$suggestedUrl'`), avec un `transitionBuilder` combinant `SlideTransition` (glissement depuis `Offset(0, -1)`) et `FadeTransition`. Le changement de clé entre `null`/URL (et entre deux URLs différentes, si une suggestion en remplace une autre avant action utilisateur) déclenche la transition — la disparition (Ajouter/Ignorer) bénéficie de la même transition en sens inverse, sans que ce soit une exigence explicite du prompt (comportement non demandé mais non exclu : le texte, les actions et leur effet restent strictement inchangés).
3. **Haptique** : `ref.listen<String?>(clipboardSuggestionProvider, (previous, next) { if (next != null && next != previous) HapticFeedback.lightImpact(); })` directement dans `build()` de `ClipboardSuggestionBanner` (toujours un `ConsumerWidget`, pas de conversion en `ConsumerStatefulWidget` nécessaire). `ref.listen` ne réagit qu'à un changement réel de la valeur du provider, jamais à un simple rebuild du widget causé par autre chose — satisfait directement la contrainte "jamais de re-déclenchement à chaque rebuild" sans état local supplémentaire à gérer soi-même.

**Vérification automatisée :** nouveau `test/widget/features/bookmarks/presentation/clipboard_suggestion_banner_test.dart` (4 cas, provider `clipboardSuggestionProvider` remplacé par un `_FakeClipboardSuggestion` contrôlable, même pattern que `_FakeBookmarkList` dans `home_screen_test.dart`) : (1) aucun `MaterialBanner` tant qu'aucune suggestion, (2) `backgroundColor` égal à `colorScheme.primaryContainer`, (3) opacité de la `FadeTransition` strictement inférieure à 1 juste après le changement d'état puis égale à 1 une fois réglée (transition non instantanée), (4) `HapticFeedback.lightImpact` intercepté via un mock de `SystemChannels.platform` — exactement un appel par nouvelle suggestion, aucun sur rebuild répété ni sur disparition, un deuxième appel sur une suggestion différente. `flutter analyze` propre ; `flutter test` (suite complète, `-j 1` non nécessaire ici) : 115 passed, 2 skipped (préexistants et sans rapport, voir entrée Tâche 10), 1 échec (`sync_service_test.dart`, `'start une reconnexion réseau déclenche une synchronisation'`) — confirmé non lié à cette tâche : passe systématiquement en isolation (`flutter test test/unit/features/bookmarks/data/sync_service_test.dart`), échec intermittent uniquement en suite complète, même famille de course contre une horloge réelle que le cas déjà documenté et `skip`-é juste en dessous dans le même fichier (voir entrée Tâche 10, BUGS_AND_ROADMAP.md) — non modifié dans cette tâche (hors périmètre du prompt).

**Vérification manuelle sur appareil physique réel (fait exceptionnel pour ce projet, voir note ci-dessous) :** un appareil Android physique était connecté durant cette session (`adb devices` → `SCG10`, Android 15/API 35, série `RFCRA1E10HH`) — à la différence de toutes les tâches précédentes (Tâches 3 à 18), qui documentaient systématiquement l'absence d'appareil physique/émulateur comme limitation de l'environnement de développement. `flutter run -d RFCRA1E10HH --debug` : build et install réussis. Un lien YouTube a été copié dans le presse-papier de l'appareil (saisi dans le champ de `SearchScreen`, sélectionné et copié via `adb shell cmd input keycombination`, jamais sauvegardé), puis l'app a été mise en arrière-plan puis reprise au premier plan (`AppLifecycleState.resumed`) pendant que `HomeScreen` restait monté (conservé par l'`IndexedStack` de la navigation par onglets) :
- la bannière apparaît avec le fond violet `primaryContainer`, nettement distinct du fond sombre neutre du reste de `HomeScreen` (capture d'écran) ;
- `adb logcat` confirme un unique appel `VibratorManagerService: performHapticFeedback` au moment exact de l'apparition — la vibration réelle n'a pas été ressentie car le réglage système "retour haptique" est désactivé sur cet appareil (message logcat "haptic feedback is disabled"), ce qui est une configuration système de l'appareil de test, pas un défaut du code : l'appel `HapticFeedback.lightImpact()` a bien été émis exactement une fois, comme requis ;
- "Ignorer" referme la bannière sans créer de bookmark ni perturber la liste existante (capture d'écran avant/après identique).

**Non vérifié visuellement en direct :** la fluidité de la transition de 300 ms elle-même (glissement + fondu) n'a pas pu être observée à l'œil sur l'appareil dans cette session (captures d'écran = instantanés, pas de vidéo) — sa présence et son minutage sont garantis par le test automatisé (2) ci-dessus, qui vérifie explicitement une opacité intermédiaire non nulle et non unitaire pendant la transition.

**Note sur la disponibilité de l'appareil physique :** toutes les entrées précédentes de ce fichier et de `BUGS_AND_ROADMAP.md` (Tâches 3, 5, 6, 6.5, 7, 12, 12bis, 13, 15, 17) documentent l'absence d'appareil Android/iOS physique ou d'émulateur comme limitation constante de l'environnement de développement. Un appareil Android (`SCG10`) était connecté et accessible via `adb`/`flutter run` durant cette session précise — ne pas supposer que cette disponibilité est permanente ou reproductible pour les tâches futures ; vérifier `flutter devices`/`adb devices` en début de session avant de s'appuyer dessus, plutôt que de présumer soit sa présence soit son absence.

**Leçon :** quand un appareil physique réel devient disponible de façon inattendue, l'utiliser pour valider un critère d'acceptation qui mentionne explicitement un retour haptique et une transition visuelle — un test automatisé (`flutter test`, sans rendu réel ni vibreur matériel) peut vérifier la logique (opacité, nombre d'appels à l'API) mais pas le ressenti final ; `adb logcat` s'est révélé être un moyen fiable de confirmer qu'un appel `HapticFeedback` a bien atteint la couche native, y compris quand le réglage système empêche de le ressentir physiquement.

**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 20 — Validation de `ManualAddDialog` via `UrlTextExtractor`, popup qui retourne l'URL plutôt que d'ouvrir `AddBookmarkSheet` depuis son propre contexte

**Contexte :** Tâche 20, ajout d'un bouton flottant "+" sur `HomeScreen` ouvrant une popup de saisie manuelle d'URL (troisième voie d'entrée déjà documentée par SPEC.md section 11). Le prompt de tâche demandait explicitement de réutiliser toute logique de validation déjà factorisée au moment de la tâche plutôt que d'en écrire une nouvelle (voir Tâche 18).
**Alternatives envisagées pour la validation :** (1) écrire une nouvelle regex/vérification de schéma `http`/`https` propre à `ManualAddDialog` ; (2) réutiliser directement `UrlTextExtractor.extractBestUrl` (Tâche 18), qui encapsule déjà exactement cette règle (schéma obligatoire, host non vide) en plus de savoir extraire un lien exploitable au sein d'un texte libre collé (ex: lien entouré de texte, comportement déjà exploité par `ShareIntentService`/`ClipboardService`).
**Décision validation :** option 2. `ManualAddDialog._submit` appelle `UrlTextExtractor.extractBestUrl(input)` ; `null` déclenche l'erreur inline ("Ce n'est pas un lien valide."), sans fermer la popup ni transmettre quoi que ce soit — une valeur non nulle est l'URL retenue, y compris si l'utilisateur a collé un texte libre autour du lien réel (bénéfice gratuit de la factorisation déjà faite, non explicitement demandé mais cohérent avec le comportement des deux autres voies d'entrée).
**Alternatives envisagées pour l'enchaînement vers `AddBookmarkSheet` :** (1) appeler `AddBookmarkSheet.show(context, url: ...)` directement dans `_submit`, juste après `Navigator.of(context).pop()`, en utilisant le `context` du `State` de la popup elle-même ; (2) faire retourner l'URL validée par la popup (`Navigator.of(context).pop(validUrl)`) et laisser le point d'appel statique `ManualAddDialog.show` (appelé depuis `HomeScreen`, avec le `context` de l'écran) enchaîner sur `AddBookmarkSheet.show` une fois la popup effectivement fermée.
**Décision enchaînement :** option 2. Le `context` d'un widget dont le `State` vient d'être poppé n'est plus garanti valide de façon fiable une fois l'animation de fermeture engagée (risque de `deactivated widget ancestor` selon le timing) — retourner la valeur via `Navigator.pop` et rouvrir `AddBookmarkSheet` depuis le `context` de l'appelant (avec vérification `context.mounted` après le `await`, required puisqu'un `BuildContext` traverse un point async) est le pattern recommandé par Flutter pour ce cas exact.
**Conséquence :** `ManualAddDialog` ne connaît et n'importe que `UrlTextExtractor` et `AddBookmarkSheet.show` (uniquement via sa méthode statique `show`) — jamais `MetadataService`, `BookmarkRepository`, Isar ni Supabase, conformément à la contrainte de la tâche.
**Libellé du bouton de confirmation :** "Ajouter", pour rester cohérent avec le vocabulaire de CTA déjà harmonisé ailleurs dans l'app (voir DECISIONS.md, entrée "Tâche 14 — Boutons de confirmation explicites") plutôt qu'un terme distinct comme "Valider" qui aurait introduit une incohérence de vocabulaire entre les différentes étapes du flux d'ajout.
**Leçon :** avant d'écrire une nouvelle règle de validation, vérifier si un utilitaire déjà factorisé pour un besoin voisin (ici Tâche 18) ne couvre pas déjà exactement le cas — et pour l'enchaînement de deux overlays Flutter successifs (popup puis modale), préférer faire remonter un résultat via `Navigator.pop(value)` jusqu'au point d'appel d'origine plutôt que d'utiliser le `context` d'un widget en cours de fermeture.
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 21 — Menu contextuel par appui long : `onLongPress` optionnel sur `BookmarkCard`, logique portée par un widget dédié

**Contexte :** Tâche 21, exposer dans l'UI les méthodes déjà testées `BookmarkRepository.updateBookmark`/`deleteBookmark` (Tâche 5), jusqu'ici inaccessibles depuis `HomeScreen`. Le prompt de tâche autorisait que le déclenchement du menu vive dans `BookmarkCard`, à condition qu'aucun appel à `BookmarkRepository` n'y soit fait directement.
**Alternatives envisagées :** (1) transformer `BookmarkCard` en `ConsumerWidget` pour qu'elle ouvre elle-même le menu contextuel (accès direct à `ref`) ; (2) garder `BookmarkCard` `StatelessWidget`, avec un paramètre `onLongPress` optionnel symétrique à `onTap` (déjà branché par `HomeScreen` sur `openBookmark`, `open_bookmark_action.dart`), et faire porter toute la logique de mutation par un nouveau fichier dédié (`bookmark_context_menu.dart`) consommé par `HomeScreen`.
**Décision :** option 2, strictement symétrique au pattern `onTap`/`openBookmark` déjà en place. `BookmarkCard` ne connaît donc ni Riverpod ni `BookmarkRepository` — cohérence de séparation légèrement plus stricte que ce que le prompt exigeait au minimum (qui aurait toléré l'option 1). `showBookmarkContextMenu(context, ref, bookmark)` (`bookmark_context_menu.dart`) ouvre un `showModalBottomSheet` léger (2 actions), puis délègue : "Modifier les tags" à un `AlertDialog` dédié (`_EditTagsDialog`, `StatefulWidget` interne) enveloppant `TagInputField` tel quel (aucune modification, exactement l'usage anticipé par sa doc de classe depuis la Tâche 13/14) ; "Supprimer" à un `AlertDialog` de confirmation standard avant `deleteBookmark`. Les deux rafraîchissent `bookmarkListProvider` après coup.
**`VideoBookmark.copyWith` ajouté :** `BookmarkRepository.updateBookmark` prend un `VideoBookmark` complet (pas seulement une liste de tags) — `copyWith` évite une reconstruction manuelle de tous les champs (risque d'oubli/désynchronisation si un champ est ajouté plus tard au modèle) pour ne remplacer que `tags`.
**Portée volontairement limitée à `HomeScreen` :** `SearchScreen` réutilise aussi `BookmarkCard` (voir DECISIONS.md/CONVENTIONS.md, contrainte de non-duplication) mais n'a pas reçu ce même `onLongPress` — hors périmètre du prompt de la Tâche 21, qui ne mentionne que `HomeScreen`. Signalé ici plutôt que tranché silencieusement ; voir `BUGS_AND_ROADMAP.md`.
**Leçon de test — `isar_community` sous `AutomatedTestWidgetsFlutterBinding` (étend l'entrée « Tâche 10 ») :** le nouveau test widget `bookmark_context_menu_test.dart` a d'abord semblé bloquer indéfiniment sur `pumpAndSettle()`. Cause réelle, distincte d'un simple oubli de surcharge de provider (`bookmarkRepositoryProvider` était bien surchargé, à l'identique de `search_screen_test.dart`) : `HomeScreen` lit `bookmarkListProvider` (donc Isar réel) dès son montage — tout `await` sur une opération Isar réelle doit être enveloppé dans `tester.runAsync`, sans quoi le port natif d'`isar_community` n'est jamais relayé. Trois pièges supplémentaires, non documentés ailleurs dans le projet, découverts empiriquement à cette occasion :
1. `pumpAndSettle()` ne fonctionne pas à l'intérieur d'un bloc `runAsync` (timeout, même sur une simple animation d'ouverture de bottom sheet sans Isar en jeu) — remplacé par un pompage borné de frames brutes (`pumpFrames`).
2. `tester.longPress()` s'appuie en interne sur l'avancement de l'horloge *fake* du test pour déclencher le minuteur du `LongPressGestureRecognizer` (`kLongPressTimeout`) — cette horloge étant court-circuitée par `runAsync`, le geste dégénère en simple tap (`onTap`/`openBookmark` se déclenchait à la place du menu). Remplacé par une simulation manuelle (`startGesture` + vraie attente réelle > 500 ms + `up()`).
3. `tester.pump()` **sans** argument de durée n'avance jamais l'horloge synthétique de frame de `TestWidgetsFlutterBinding` : une transition de route reste figée à sa valeur initiale (complètement hors écran) quel que soit le nombre d'appels — une `Duration` explicite (`tester.pump(duration)`) est indispensable pour la faire progresser, y compris à l'intérieur de `runAsync`.
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 22 — Section "My Eyes Only" : décisions actées en amont avec l'utilisateur

**Contexte :** nouvelle fonctionnalité de masquage de bookmarks, protégée par un code local. Trois points ont été tranchés avec l'utilisateur avant tout développement (voir `TASK_PROMPTS.md`), documentés ici pour mémoire plutôt que retranchés :
1. **Point d'entrée volontairement discret :** appui long sur le titre "Runk" de l'`AppBar` de `HomeScreen` (`GestureDetector` autour du `Text`, voir `home_screen.dart`) — aucun onglet dédié dans `AppShell`, aucune route `go_router` associée (voir entrée séparée ci-dessous sur `Navigator.push`).
2. **"Code oublié ?" ne bloque jamais l'utilisateur :** démasque tous les bookmarks `isHidden: true` existants (`BookmarkRepository.unhideAllBookmarks`, aucune suppression) et efface le hash du code (`MyEyesOnlyService.resetPin`), puis enchaîne automatiquement sur le dialogue de création d'un nouveau code (confirmé explicitement par l'utilisateur : pas besoin de refaire l'appui long sur "Runk").
3. **Synchronisation asymétrique :** `VideoBookmark.isHidden`/`BookmarkEntity.isHidden` suit exactement le même chemin que les autres champs (`_toRemoteMap`/`_fromRemoteMap` de `BookmarkRepository`, colonne `bookmarks.is_hidden` côté Supabase) — visible sur un second appareil après synchronisation. Le code PIN lui-même (`MyEyesOnlyService`) ne connaît que `shared_preferences`, jamais Isar ni Supabase : strictement local à chaque appareil.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 22 — Limite de sécurité assumée : confidentialité d'usage, pas chiffrement

**Contexte :** le code "My Eyes Only" protège l'accès à une liste de bookmarks depuis l'interface de l'app, pas les données elles-mêmes.
**Ce qui est réellement protégé :** un utilisateur qui n'a pas le code ne peut pas, *depuis l'app*, faire apparaître les bookmarks `isHidden: true` dans `HomeScreen` ni dans `MyEyesOnlyScreen`.
**Ce qui n'est pas protégé :** les bookmarks masqués restent en clair dans la base Isar locale (accessible à quiconque a un accès root/débogage à l'appareil) et dans la table `bookmarks` de Supabase, où ils sont seulement protégés par les policies RLS déjà en place pour tout bookmark (donc invisibles aux *autres utilisateurs* de l'app, mais pas chiffrés pour le propriétaire lui-même — un accès direct à la base Supabase avec les identifiants du compte, ou à l'Isar local du device, les révèle sans le code).
**Décision :** assumer cette limite plutôt que de concevoir un chiffrement au repos (hors périmètre de la Tâche 22, complexité et gestion de clé disproportionnées pour le besoin exprimé — masquer par confort d'usage, pas se protéger d'un accès root/forensique à l'appareil). Formulée explicitement dans le commentaire `///` de `MyEyesOnlyService` (`lib/core/services/my_eyes_only_service.dart`) pour qu'elle reste visible à la prochaine personne qui referait confiance à cette fonctionnalité pour un usage plus sensible.
**Leçon :** nommer clairement la limite d'une fonctionnalité de confidentialité dès sa livraison évite qu'elle soit perçue plus tard comme un bug de sécurité plutôt que comme un choix assumé.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 22 — `MyEyesOnlyScreen` ouvert via `Navigator.push`, pas une route `go_router`

**Contexte :** `router.dart` déclare aujourd'hui uniquement les 3 branches visibles de la bottom navigation (Home/Tags/Recherche, voir Tâche 9) au sein d'un unique `StatefulShellRoute.indexedStack`. `MyEyesOnlyScreen` doit rester un point d'entrée discret (voir décision ci-dessus), jamais accessible autrement qu'en passant par le code.
**Alternatives envisagées :** (1) ajouter une route `go_router` dédiée (ex: `/my-eyes-only`), cohérente avec le reste de la navigation de l'app ; (2) ouvrir l'écran via un simple `Navigator.of(context).push(MaterialPageRoute(...))`, en dehors de toute configuration `go_router`.
**Décision :** option 2. Une route `go_router` nommée serait adressable directement (deep link, bouton "retour" du système reconstruisant l'URL, historique de navigation persistant) — au moins un chemin d'accès à l'écran qui contournerait entièrement le code, ce qui contredirait le point d'entrée volontairement discret déjà acté avec l'utilisateur. `Navigator.push` classique n'existe que le temps où l'utilisateur est effectivement passé par `openMyEyesOnly` (donc par le code), et disparaît de la pile de navigation dès qu'il revient en arrière.
**Conséquence :** `MyEyesOnlyScreen` n'apparaît dans aucun fichier de routes ; `my_eyes_only_access.dart` est le seul point d'entrée qui la construit.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 22 — Réutilisation de `showBookmarkContextMenu` (donc "Ne plus masquer") depuis `MyEyesOnlyScreen`

**Contexte :** le prompt de tâche demandait que `MyEyesOnlyScreen` réutilise `BookmarkCard` filtré sur `isHidden == true`, sans préciser si le menu contextuel par appui long (Tâche 21, `onLongPress`) devait lui aussi y être branché.
**Décision :** brancher `onLongPress`/`showBookmarkContextMenu` sur `MyEyesOnlyScreen` exactement comme sur `HomeScreen` (même signature, même widget), plutôt que de le laisser non câblé comme cela avait été fait pour `SearchScreen` en Tâche 21 (voir entrée « Tâche 21 » ci-dessus, "Portée volontairement limitée à `HomeScreen`"). Sans ce branchement, un bookmark masqué par erreur ne pourrait être "démasqué" qu'en repassant par `HomeScreen`... où il n'apparaît justement plus — seul `MyEyesOnlyScreen` peut raisonnablement offrir cette action de retour, ce qui en fait une conséquence directe du critère d'acceptation de la tâche plutôt qu'un ajout hors périmètre.
**Conséquence :** aucune duplication de code — `bookmark_context_menu.dart` est appelé tel quel, seul le libellé de l'action ("Masquer"/"Ne plus masquer") change dynamiquement selon `bookmark.isHidden`, déjà géré par le widget existant.
**Statut :** 🔵 Choix assumé

---

## [RÉSOLU] Tâche 23 — Exclusion des bookmarks masqués de `searchByTitleOrTags`

**Contexte :** `HomeScreen` filtre `isHidden == true` côté présentation depuis la Tâche 22, mais `BookmarkRepository.searchBookmarks` déléguait sans filtre à `BookmarkLocalDatasource.searchByTitleOrTags` — un bookmark masqué restait trouvable via `SearchScreen` en tapant un terme présent dans son titre ou ses tags, contournement direct de la protection par code.
**Cause :** le filtre `isHidden` avait été ajouté uniquement à l'endroit où le besoin s'est présenté en premier (Tâche 22, `HomeScreen`), sans revue systématique des autres chemins de lecture qui remontent des `VideoBookmark` (recherche, tags).
**Alternatives envisagées :** (1) filtrer dans `BookmarkRepository.searchBookmarks`, après récupération des entités (symétrique du filtre actuel de `HomeScreen`) ; (2) filtrer directement dans `BookmarkLocalDatasource.searchByTitleOrTags`, au niveau de la requête Isar (`isHiddenEqualTo(false)`, champ déjà indexé par Isar comme les autres booléens de l'entité).
**Décision :** option 2. Cohérent avec `isDeletedLocallyEqualTo(false)`, déjà filtré au même endroit et pour la même raison (un résultat de recherche ne doit jamais inclure une entité qui n'a pas vocation à être visible) — évite aussi de charger puis de jeter des entités masquées inutilement. Aucun paramètre `includeHidden` exposé : l'exclusion est systématique et non contournable depuis `presentation/`.
**Fuite potentielle documentée, non corrigée dans cette tâche :** `distinctTagsProvider` (`lib/features/tags/presentation/distinct_tags_provider.dart`) dérive ses tags de `bookmarkListProvider`, qui lit `BookmarkRepository.getAllBookmarks()` **sans filtre `isHidden`** (le filtre de la Tâche 22 vit uniquement dans le `build()` de `HomeScreen`, pas dans le repository). Si un tag n'existe que sur des bookmarks masqués, il apparaît quand même dans `TagsScreen` et dans les suggestions de `TagInputField` (Tâche 13) — un utilisateur sans le code "My Eyes Only" peut ainsi deviner qu'un bookmark masqué existe (via l'existence du tag), même s'il ne peut ni le lister ni le lire. Risque mineur (aucune donnée du bookmark lui-même n'est exposée, seul un nom de tag), mais réel — hors périmètre du prompt de la Tâche 23 (qui ne portait que sur `searchBookmarks`), signalé ici plutôt que passé sous silence.
**Leçon :** quand une règle de confidentialité (ici `isHidden`) est ajoutée à une couche `presentation/` plutôt qu'au niveau du repository/datasource qui centralise la lecture, chaque nouveau chemin de lecture doit être audité explicitement — le risque n'est pas d'oublier de filtrer un écran, mais d'oublier qu'un filtre posé une fois ne se propage à aucun autre consommateur du même repository.
**Statut :** ✅ Résolu (recherche) — 🟡 fuite via `distinctTagsProvider` documentée, non corrigée

---

## [CHOIX] Tâche 24 — Retrait de "Masquer"/"Ne plus masquer" du menu contextuel partagé (ajustement explicite de la Tâche 22)

**Contexte :** la Tâche 22 avait délibérément branché "Masquer"/"Ne plus masquer" dans `showBookmarkContextMenu` (voir l'entrée « Tâche 22 — Réutilisation de `showBookmarkContextMenu`... » ci-dessus), pour que `MyEyesOnlyScreen` puisse démasquer sans dupliquer de code. Revu explicitement avec l'utilisateur en Tâche 24 : ce choix rendait la fonctionnalité "My Eyes Only" devinable par n'importe quel appui long occasionnel sur *n'importe quel* bookmark visible (Home/Recherche/Tags), même par un utilisateur qui n'a jamais entendu parler de la fonctionnalité — contradictoire avec le point d'entrée volontairement discret déjà acté (Tâche 22, entrée « décisions actées en amont »).
**Ce n'est pas une correction de bug :** le comportement de la Tâche 22 fonctionnait exactement comme prévu et testé à l'époque ; il s'agit d'un choix de discrétion plus strict, pas d'une régression corrigée.
**Décision :** retirer entièrement `_BookmarkMenuAction.toggleHidden` et le `ListTile` associé de `bookmark_context_menu.dart` — ce menu partagé (HomeScreen/SearchScreen/TagsScreen/MyEyesOnlyScreen) ne propose plus que "Modifier les tags" et "Supprimer", sans aucune condition ni exception, dans aucun état de l'app. `MyEyesOnlyScreen` reçoit à la place une action locale dédiée (`HiddenBookmarkMenuButton`, nouveau fichier `hidden_bookmark_menu_button.dart`, `lib/features/bookmarks/presentation/`) pour "Ne plus masquer"/"Supprimer" — importée uniquement par `my_eyes_only_screen.dart`.
**Conséquence :** l'entrée « Tâche 22 — Réutilisation de `showBookmarkContextMenu`... » ci-dessus ne décrit donc plus le comportement actuel du code — conservée telle quelle par souci d'historique plutôt que réécrite ; cette entrée-ci fait foi pour l'état courant.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 24 — Nouveau flux de sélection multiple `AddToMyEyesOnlyScreen`

**Contexte :** sans l'entrée "Masquer" du menu contextuel partagé (voir entrée ci-dessus), il fallait un nouveau chemin pour masquer un bookmark, accessible uniquement depuis l'intérieur de `MyEyesOnlyScreen` (donc déjà protégé par le code).
**Décision :** nouvel écran `add_to_my_eyes_only_screen.dart` (`lib/features/bookmarks/presentation/`), liste à cases à cocher (`CheckboxListTile`) des bookmarks `isHidden == false`, dérivée de `bookmarkListProvider` comme `MyEyesOnlyScreen` (même pattern de filtrage client, voir sa doc de classe). Sélection multiple plutôt qu'un masquage bookmark par bookmark, pour permettre de masquer plusieurs bookmarks en une seule visite de l'écran. Accessible uniquement via un second `FloatingActionButton` (icône `Icons.add`) sur `MyEyesOnlyScreen`, ouvert par `Navigator.push` — même raisonnement que `MyEyesOnlyScreen` lui-même (voir entrée « Tâche 22 — `MyEyesOnlyScreen` ouvert via `Navigator.push`, pas une route `go_router` » : une route `go_router` créerait un chemin d'accès adressable qui contournerait le code).
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 24 — Aucune session "déverrouillée" persistante : la discrétion vient de la navigation, pas d'un flag

**Contexte :** le prompt de tâche demandait explicitement de documenter pourquoi aucun nouvel état de session/déverrouillage n'est nécessaire, `MyEyesOnlyScreen` ne pouvant plus s'appuyer sur le menu contextuel partagé pour démasquer.
**Alternatives envisagées :** (1) un provider Riverpod (ex: `isMyEyesOnlyUnlockedProvider`) mémorisant que le code vient d'être saisi avec succès, pour par exemple permettre un accès simplifié tant que l'app reste au premier plan ; (2) aucun état partagé — la protection redevient pleinement effective dès que l'utilisateur quitte `MyEyesOnlyScreen`.
**Décision :** option 2. `MyEyesOnlyScreen` n'est atteignable que via `openMyEyesOnly` (code correct requis à chaque appui long sur "Runk", Tâche 22) ; un retour arrière ramène à un contexte où ni le menu contextuel partagé (Tâche 24, entrée ci-dessus) ni la nouvelle action locale (`HiddenBookmarkMenuButton`, présente uniquement dans l'arbre de `MyEyesOnlyScreen`) ne sont atteignables. Il n'existe donc aucun état intermédiaire "déverrouillé mais pas sur l'écran" à protéger : soit l'utilisateur est effectivement sur `MyEyesOnlyScreen` (code déjà vérifié pour cette navigation précise), soit il n'y est pas et aucune action liée au masquage n'est jamais visible ni exécutable, quel que soit l'écran affiché. Un flag de session ajouterait un état à invalider correctement (retour arrière, mise en arrière-plan, kill de l'app) sans bénéfice pour le critère d'acceptation de cette tâche.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 24 — Perte de "Modifier les tags" depuis `MyEyesOnlyScreen` (trade-off assumé)

**Contexte :** `MyEyesOnlyScreen` bénéficiait, depuis la Tâche 22, du menu contextuel complet (`showBookmarkContextMenu` branché sur `onLongPress`), donc aussi de "Modifier les tags" pour un bookmark masqué. Le retrait total du masquage de ce menu partagé (voir entrée ci-dessus) posait une question non tranchée par le prompt de tâche : fallait-il garder `onLongPress`/`showBookmarkContextMenu` branché sur `MyEyesOnlyScreen` en plus de la nouvelle action locale, ou le retirer entièrement ?
**Alternatives envisagées :** (1) garder les deux (`onLongPress` vers le menu partagé pour "Modifier les tags"/"Supprimer", en plus du bouton local dédié pour "Ne plus masquer"/"Supprimer") — deux façons différentes de supprimer un bookmark depuis le même écran, source de confusion ; (2) retirer entièrement `onLongPress` de `MyEyesOnlyScreen`, ne garder que l'action locale à deux choix explicitement demandée par le prompt de tâche.
**Décision :** option 2. Un bookmark masqué peut être démasqué puis, une fois redevenu visible dans `HomeScreen`, avoir ses tags modifiés comme n'importe quel autre bookmark via le menu partagé habituel — perte d'un raccourci depuis `MyEyesOnlyScreen`, pas d'une capacité de l'app. Cohérent avec le libellé exact demandé par le prompt de tâche ("deux choix : Ne plus masquer / Supprimer").
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 25 — Masquage de tag en cascade : décisions actées en amont avec l'utilisateur

**Contexte :** extension de "My Eyes Only" (Tâches 22/24) aux tags eux-mêmes. Trois points tranchés avec l'utilisateur avant tout développement (voir `TASK_PROMPTS.md`) :
1. **Masquer un tag masque tous les bookmarks qui le portent, existants et futurs.** Concrètement : `TagRepository.hideTag(name)` marque `TagEntity.isHidden: true` et cascade immédiatement sur tous les `BookmarkEntity` déjà taggés ; `BookmarkRepository.createBookmark`/`updateBookmark` consultent ensuite ce même `TagEntity.isHidden` à chaque écriture pour couvrir le cas "futur" — un bookmark créé ou édité plus tard avec ce tag est automatiquement masqué, sans repasser par `TagRepository`.
2. **Jamais accessible depuis l'UI normale.** `tag_action_dialogs.dart` et `bookmark_context_menu.dart` restent strictement inchangés (aucune modification apportée dans cette tâche) — même principe que la Tâche 24 pour les bookmarks : `hideTag`/`unhideTag` ne sont appelés que depuis `add_to_my_eyes_only_screen.dart` (nouveau mode "Tags") et `my_eyes_only_screen.dart` (nouvelle section "Tags masqués"), tous deux déjà protégés par le code "My Eyes Only".
3. **Extension explicite de la Tâche 21 ("Modifier les tags").** Le prompt de tâche demandait initialement le comportement seulement pour "un nouveau bookmark créé avec ce tag" ; ajouter un tag masqué à un bookmark existant via "Modifier les tags" (menu contextuel, Tâche 21) déclenche le même masquage automatique — traité comme une extension logique plutôt qu'un ajout hors périmètre non documenté (voir critère d'acceptation du prompt de tâche, qui le rend explicite).

**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 25 — `BookmarkRepository` lit `TagEntity` en lecture seule, sans transaction composée

**Contexte :** `createBookmark`/`updateBookmark` doivent savoir si un des tags finaux du bookmark correspond à un `TagEntity.isHidden == true`, pour forcer `isHidden: true` sur le bookmark. Cela suppose un accès de `BookmarkRepository` (feature bookmarks) à la collection `TagEntity` (feature tags) — jusqu'ici, seul `TagRepository` écrivait dans les deux collections (voir DECISIONS.md, entrée « Tâche 15 »), jamais l'inverse.
**Différence avec le cas déjà résolu en Tâche 15 :** `TagRepository.renameTag`/`deleteTag` doivent modifier `TagEntity` et `BookmarkEntity` **dans la même transaction** (Isar interdit les transactions imbriquées, d'où l'accès direct à l'instance `Isar` documenté en Tâche 15). Ici, `BookmarkRepository` ne fait qu'une **lecture** de `TagEntity` avant d'écrire son propre `BookmarkEntity` — aucune contrainte de transaction unique ne s'applique, une simple injection de `TagLocalDatasource` (déjà une classe publique de la feature tags, `lib/features/tags/data/tag_local_datasource.dart`) suffit, sans avoir besoin de l'instance `Isar` brute.
**Décision :** `BookmarkRepository` reçoit un `TagLocalDatasource` en constructeur (nouveau paramètre requis `tagLocalDatasource`, injecté par `bookmarkRepositoryProvider` à partir de la même instance `Isar` déjà partagée, voir Tâche 15) et lui délègue une nouvelle méthode `TagLocalDatasource.hasAnyHiddenTag(List<String> tagNames)` — lecture pure, aucune écriture. La règle "toute écriture sur les tags reste la responsabilité exclusive de `TagRepository`" (contrainte explicite du prompt de tâche) est donc respectée : `BookmarkRepository` ne modifie jamais `TagEntity`.
**Conséquence sur les tests :** tous les tests qui construisaient directement un `BookmarkRepository` (7 fichiers, voir liste dans le commit) ouvrent désormais `[BookmarkEntitySchema, TagEntitySchema]` (au lieu de `BookmarkEntitySchema` seul) et passent un `TagLocalDatasource(isar)` — cohérent avec le fait que l'instance `Isar` de production ouvre déjà les deux schémas depuis la Tâche 15.
**Leçon :** une dépendance cross-feature en lecture seule ne justifie pas la même solution (accès direct à `Isar`, transaction composée) qu'une dépendance qui doit garantir l'atomicité de plusieurs écritures — réévaluer la contrainte réelle (ici : aucune transaction partagée nécessaire) avant de reproduire par réflexe le pattern déjà utilisé pour un cas voisin.
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 25 — `unhideTag` ne démasque pas un bookmark protégé par un autre tag encore masqué

**Contexte :** le prompt de tâche décrit `unhideTag` de façon littéralement symétrique à `hideTag` ("`TagEntity.isHidden = false`, et `isHidden = false` sur tous les `BookmarkEntity` portant ce tag"). Un bookmark peut porter plusieurs tags masqués simultanément (ex: masquer `tag1` puis, séparément, masquer `tag2`, sur un bookmark qui porte les deux) — une implémentation strictement littérale de `unhideTag('tag1')` rendrait ce bookmark visible même si `tag2` est toujours masqué, ce qui contredit l'invariant que `hideTag` établit lui-même ("tous les bookmarks qui portent ce tag sont masqués").
**Alternatives envisagées :** (1) implémentation littérale, sans vérification croisée — plus simple, mais casse silencieusement l'invariant de `hideTag` dès qu'un bookmark a deux tags masqués ; (2) avant de démasquer un bookmark donné, revérifier (dans la même transaction, après avoir déjà mis à jour ce `TagEntity` à `isHidden: false`) si l'un de ses autres tags est encore masqué via `TagLocalDatasource.hasAnyHiddenTag` — ne le démasquer que si la réponse est non.
**Décision :** option 2. Ce n'est **pas** la même ambiguïté que la limite ci-dessous (bookmark masqué individuellement + via tag) : ici, les deux causes du masquage sont de même nature (deux tags masqués), et la seconde est encore active au moment du démasquage — l'information nécessaire pour ne pas casser l'invariant est disponible et déjà vérifiée par construction (`hasAnyHiddenTag`, la même méthode que celle utilisée par `BookmarkRepository`).
**Leçon :** une description de tâche formulée comme "symétrique" à une opération déjà spécifiée mérite d'être vérifiée contre l'invariant que la première opération établit, pas seulement contre son propre effet immédiat — la cascade de `hideTag` promet plus que "ce bookmark est masqué maintenant", elle promet "tant que ce tag reste masqué, ce bookmark le reste aussi".
**Statut :** ✅ Résolu

---

## [LIMITE] Tâche 25 — Impossible de distinguer un bookmark masqué individuellement d'un bookmark masqué via un tag

**Contexte :** un bookmark peut être masqué de deux façons indépendantes : individuellement (Tâche 24, `HiddenBookmarkMenuButton`/`AddToMyEyesOnlyScreen` en mode "Bookmarks") ou via un tag masqué (Tâche 25, `hideTag`/auto-masquage à la création/édition). `BookmarkEntity.isHidden` est un simple booléen — rien ne distingue laquelle de ces deux causes (ou les deux à la fois) explique l'état actuel d'un bookmark donné.
**Conséquence concrète :** si un bookmark est masqué à la fois individuellement et via un tag masqué, démasquer ce tag (`unhideTag`, depuis `MyEyesOnlyScreen`) le rend visible à nouveau **aussi** — alors que l'utilisateur avait peut-être une raison de le masquer indépendamment du tag. Symétriquement, "Ne plus masquer" un bookmark individuellement (`HiddenBookmarkMenuButton`) ne le remasque jamais automatiquement si l'un de ses tags est encore masqué : côté `BookmarkRepository`, seuls `createBookmark`/`updateBookmark` réévaluent `hasAnyHiddenTag` — `HiddenBookmarkMenuButton._unhide` appelle `updateBookmark(bookmark.copyWith(isHidden: false))` avec les mêmes tags qu'avant, donc si l'un d'eux est encore masqué, `updateBookmark` le re-masque immédiatement (`hasHiddenTag || bookmark.isHidden` avec `bookmark.isHidden` fourni à `false` redevient `true`) — dans ce sens précis, le mécanisme protège correctement l'invariant du tag. C'est uniquement dans le sens "démasquer le tag" que l'ambiguïté existe, faute de savoir si le bookmark avait *aussi* été masqué individuellement.
**Alternatives qui auraient pu lever l'ambiguïté (délibérément écartées, hors périmètre de cette tâche) :** stocker la ou les raisons du masquage (ex: `Set<String> hiddenReasons` ou `List<String> hidingTags` sur `BookmarkEntity`) plutôt qu'un simple booléen — changement de modèle de données plus large, qui toucherait aussi la synchronisation Supabase (`bookmarks.is_hidden`) et le flux "Code oublié ?" (`unhideAllBookmarks`, Tâche 22). Explicitement non tranché dans cette tâche, à la demande de l'utilisateur : documenter la limite plutôt que la résoudre silencieusement ou la masquer.
**Décision :** limite assumée, non corrigée. `BookmarkEntity.isHidden` reste un booléen simple.
**Leçon :** quand deux mécanismes indépendants peuvent produire le même effet observable (ici `isHidden: true`) sans qu'aucun état ne retienne *lequel*, toute action qui inverse l'un des deux mécanismes affecte l'autre par accident — nommer cette limite explicitement (au lieu de la découvrir plus tard comme un bug signalé par l'utilisateur) permet de la garder sous surveillance sans bloquer la tâche en cours sur un changement de modèle de données plus large.
**Statut :** 🟡 Limite documentée, non résolue

---

## [RÉSOLU] Tâche 25 — Bonus : correction de la fuite `distinctTagsProvider` documentée en Tâche 23

**Contexte :** DECISIONS.md, entrée « Tâche 23 », documentait déjà (sans le corriger, hors périmètre à l'époque) qu'un tag porté uniquement par des bookmarks `isHidden: true` restait visible dans `TagsScreen`/l'autocomplétion, parce que `distinctTagsProvider` dérivait ses tags de `bookmarkListProvider` sans filtrer `isHidden`. Découvert à nouveau en préparant la Tâche 25 (mentionné explicitement dans le prompt de tâche comme bug préexistant à corriger dans le même mouvement, pas comme un nouveau bug de cette tâche).
**Fix :** deux changements complémentaires dans `lib/features/tags/presentation/distinct_tags_provider.dart` et `lib/features/tags/data/tag_repository.dart` :
1. Les tags **dérivés** ne sont plus calculés depuis tous les bookmarks retournés par `bookmarkListProvider`, mais uniquement depuis ceux `isHidden == false` (`bookmarks.where((bookmark) => !bookmark.isHidden)`).
2. Les tags **gérés** (`TagRepository.getManagedTagNames()`) excluent désormais les `TagEntity.isHidden == true` — changement de comportement nécessaire de toute façon pour la Tâche 25 (un tag masqué ne doit jamais apparaître dans `TagsScreen`), qui corrige au passage le même type de fuite côté tags gérés.
**Vérification :** nouveau cas dans `distinct_tags_provider_test.dart` (« exclut un tag porté uniquement par des bookmarks masqués ») et dans `tag_repository_test.dart` (« getManagedTagNames exclut les tags masqués, getHiddenTagNames ne retourne qu'eux »).
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 25 — UI : mode "Tags" dans `AddToMyEyesOnlyScreen`, section "Tags masqués" dans `MyEyesOnlyScreen`

**Contexte :** le prompt de tâche laissait le choix entre "un second mode ou une section séparée" pour étendre `add_to_my_eyes_only_screen.dart`, et demandait d'étendre `MyEyesOnlyScreen` pour lister aussi les tags masqués.
**Décision — `AddToMyEyesOnlyScreen` :** un `SegmentedButton<_Mode>` (`Bookmarks`/`Tags`) en tête d'écran, plutôt que deux écrans séparés — un seul point d'entrée depuis `MyEyesOnlyScreen` (le `FloatingActionButton` existant, inchangé) reste cohérent avec la Tâche 24 ("aucun nouvel état de session déverrouillé", voir entrée dédiée). En mode "Tags", le corps délègue entièrement à un nouveau widget dédié `HideTagListView` (`lib/features/bookmarks/presentation/hide_tag_list_view.dart`) — liste des tags visibles ([distinctTagsProvider], déjà filtrée par le fix ci-dessus), sélection **unique** (un tap masque directement le tag, sans case à cocher ni bouton de validation séparé) — différent du mode "Bookmarks" (sélection multiple par cases à cocher), car masquer un tag a un effet immédiatement visible et cascadé (il disparaît de la liste dès qu'il est masqué), contrairement à masquer plusieurs bookmarks un par un.
**Décision — sans confirmation avant de masquer un tag :** cohérent avec le "Masquer" déjà sans confirmation ailleurs dans l'app pour les bookmarks (Tâches 22/24) — masquer reste réversible depuis `MyEyesOnlyScreen` (`HiddenTagListTile`), à la différence d'une suppression de tag (`tags_screen.dart`, qui affiche `confirmTagDeletion` avec le nombre de bookmarks impactés, parce que la suppression, elle, est définitive).
**Décision — `MyEyesOnlyScreen` :** nouvelle section "Tags masqués" au-dessus de la liste de bookmarks masqués existante (pas un second onglet), dérivée d'un nouveau `hiddenTagsProvider` (`lib/features/tags/presentation/hidden_tags_provider.dart`, symétrique de `distinctTagsProvider`) — chaque tag affiché via `HiddenTagListTile` (`lib/features/bookmarks/presentation/hidden_tag_list_tile.dart`), qui propose uniquement "Ne plus masquer ce tag" (`TagRepository.unhideTag`), même principe que `HiddenBookmarkMenuButton` (Tâche 24) : widget local, jamais réutilisé par un autre écran, jamais de réutilisation du menu partagé.
**Leçon :** quand une tâche laisse un choix de structure UI ouvert, la contrainte déjà actée pour une fonctionnalité voisine (ici, "un seul point d'entrée protégé par le code, pas de nouvel état de session") est souvent le critère le plus fiable pour trancher entre les options, plus que l'esthétique seule.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 26 — "Modifier les tags en groupe" interprété comme ajout (union), jamais un remplacement

**Contexte :** précision de conception nécessaire, absente de la demande initiale (voir `TASK_PROMPTS.md`, Tâche 26) — actée avec l'utilisateur avant développement.
**Alternatives envisagées :** (1) remplacer la liste de tags de chaque bookmark sélectionné par la liste saisie dans le dialogue groupé ; (2) ajouter (union) la liste saisie aux tags déjà présents sur chaque bookmark, sans jamais en retirer aucun.
**Décision :** option 2. Un remplacement écraserait silencieusement les tags propres à chaque bookmark sélectionné — destructif et surprenant pour une action groupée dont l'intitulé ("Ajouter un tag") ne suggère aucune suppression. `BookmarkRepository.addTagsToBookmarks` fusionne donc les tags saisis avec `BookmarkEntity.tags` existant, comparaison insensible à la casse pour éviter un doublon visuel (même logique que `TagInputField._addTag`, Tâche 13).
**Leçon :** une action de "modification en groupe" sur une liste (ici des tags) doit être explicitée comme ajout ou remplacement avant tout développement — les deux sont des interprétations également plausibles d'un intitulé court, avec des conséquences très différentes en cas d'erreur (perte de données pour un remplacement).
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 26 — Sélection multiple : masquage volontairement exclu, une instance de contrôleur par écran

**Contexte :** mode sélection multiple sur `HomeScreen`/`SearchScreen`, avec deux actions groupées (suppression, ajout de tag). Deux points structurants, actés en amont avec l'utilisateur (voir `TASK_PROMPTS.md`).
**Décision — aucune action de masquage dans ce mode :** le masquage en groupe existe déjà via `AddToMyEyesOnlyScreen` (Tâche 24), volontairement séparé et accessible uniquement depuis l'espace "My Eyes Only" déjà déverrouillé. Ajouter une action "Masquer" à `BulkSelectionToolbar` (visible dans l'usage courant de l'app, sans code) recréerait exactement la fuite de discrétion corrigée en Tâche 24 — une action de masquage visible révélerait l'existence de la fonctionnalité à quiconque utilise l'app. `bulk_selection_toolbar.dart` n'importe donc jamais `MyEyesOnlyService` ni aucune méthode de masquage de `BookmarkRepository`.
**Décision — activation par icône dédiée de l'`AppBar`, jamais l'appui long :** l'appui long sur une `BookmarkCard` reste exclusivement lié au menu contextuel individuel (Tâche 21, `showBookmarkContextMenu`) — réutiliser ce même geste pour démarrer une sélection multiple aurait créé un conflit d'ambiguïté (un appui long signifierait deux choses différentes selon un état invisible avant le geste). Un `IconButton` dédié (`Icons.checklist`/`Icons.close`) dans l'`AppBar` de chaque écran est un point d'entrée sans ambiguïté, cohérent avec le pattern déjà établi par le bouton flottant "+" (Tâche 20, geste distinct pour une action distincte).
**Décision — `BookmarkSelectionController` en `@riverpod` family, keyé par `BookmarkSelectionScope` (`home`/`search`) :** la contrainte explicite ("pas d'état partagé entre les deux écrans — sortir de l'un réinitialise sa sélection") exclut un unique provider global. Les deux écrans restant simultanément montés (`StatefulShellRoute.indexedStack`, voir `app_shell.dart`), un simple provider `autoDispose` (comportement par défaut de `@riverpod`) ne suffirait pas à lui seul à isoler les deux sélections — un `IndexedStack` garde chaque branche montée, donc chaque écran continue de `watch` "son" provider indéfiniment tant qu'il reste dans l'arbre. Une `family` sur un `scope` distinct par écran garantit l'isolation par construction, indépendamment du cycle de vie de dispose.
**Décision — `toggleSelectionMode()` réutilisé pour quitter automatiquement le mode après une action groupée réussie :** plutôt que d'ajouter une méthode dédiée (`exitSelectionMode()`), `BulkSelectionToolbar._finishBulkAction` rappelle `toggleSelectionMode()` (qui, appelé alors que le mode est actif, le désactive et vide la sélection) — cohérent avec le comportement déjà utilisé par la croix de l'`AppBar`, aucune duplication de logique de sortie.
**Leçon :** quand un geste existant (ici l'appui long) est déjà porteur d'un sens précis ailleurs dans l'app, introduire un point d'entrée dédié pour une nouvelle fonctionnalité plutôt que de surcharger ce geste évite une ambiguïté qu'aucune UI ne peut lever après coup sans re-former l'utilisateur.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 26 — `deleteBookmarks`/`addTagsToBookmarks` : accès direct à `Isar` pour une transaction unique par lot

**Contexte :** contrainte explicite du prompt de tâche — les actions groupées de suppression et d'ajout de tag doivent utiliser une seule transaction Isar pour l'ensemble du lot, pas une boucle de `deleteBookmark`/`updateBookmark` individuels appelés depuis la présentation.
**Décision :** même mécanisme que celui déjà établi par `TagRepository` (voir DECISIONS.md, entrées « Tâche 15 » et « Tâche 25 — `BookmarkRepository` lit `TagEntity`... ») : `BookmarkRepository` reçoit désormais l'instance `Isar` partagée en constructeur (nouveau paramètre requis `isar`, injecté par `bookmarkRepositoryProvider` à partir de `bookmarkIsarProvider`, déjà existant), et `deleteBookmarks`/`addTagsToBookmarks` ouvrent elles-mêmes un unique `_isar.writeTxn` pour appliquer leurs mutations locales à tout le lot, en écrivant directement via `_isar.bookmarkEntitys.put(...)` — `BookmarkLocalDatasource.upsert` (qui ouvre sa propre transaction par appel) reste inutilisée pour ces deux méthodes, incompatible avec cette composition (Isar interdit les transactions imbriquées).
**Portée de la transaction unique — locale uniquement, pas la synchronisation distante :** la transaction Isar ne couvre que l'écriture locale du lot (`isDeletedLocally = true` pour la suppression, fusion des tags pour l'ajout). La tentative de synchronisation Supabase reste faite id par id, après la transaction, comme pour tous les autres flux de ce repository (`syncPendingChanges`, `deleteBookmark`) — un appel réseau individuel ne doit jamais faire échouer les autres du même lot, et un réseau lent ne doit jamais garder une transaction Isar ouverte plus longtemps que nécessaire.
**Conséquence sur les tests :** tous les fichiers qui construisaient directement un `BookmarkRepository` (10 fichiers dans `test/`, 1 dans `integration_test/`) passent désormais aussi `isar: isar` — chacun disposait déjà de cette instance dans son `setUp` (ouverte pour `BookmarkLocalDatasource`/`TagLocalDatasource`), aucune nouvelle donnée de test à préparer.
**Leçon :** cohérent avec la leçon déjà tirée en Tâche 25 — une contrainte de transaction unique sur plusieurs écritures Isar se résout systématiquement par un accès direct à l'instance `Isar` partagée dans le repository qui la porte, jamais en composant les méthodes d'écriture des datasources (qui ouvrent chacune leur propre transaction).

---

## [RÉSOLU] Tâche 27 — Overflow d'`AddBookmarkSheet` clavier ouvert + suggestions de tags

**Contexte :** Tâche 27, bug constaté sur test manuel ("BOTTOM OVERFLOWED BY 23 PIXELS"). `AddBookmarkSheet` affichait son contenu (miniature, titre, `TagInputField`, bouton "Ajouter") dans un `Column` simple (`mainAxisSize: MainAxisSize.min`), sans conteneur défilant.
**Symptôme / Problème :** `TagInputField` affiche ses suggestions de tags dans un `Container` à `maxHeight: 160` contenant un `ListView.builder(shrinkWrap: true)` — cette hauteur s'ajoute donc à celle du reste du contenu de la modale. Quand le clavier est ouvert (réduisant l'espace vertical disponible) et que plusieurs suggestions s'affichent, la hauteur totale (miniature 160px + titre + tags + suggestions jusqu'à 160px + bouton) dépasse l'espace restant sous le clavier, provoquant un overflow visible en bas de la modale.
**Cause :** aucun ancêtre défilant au-dessus du `Column` — celui-ci se contente de sa taille minimale (`MainAxisSize.min`), mais rien ne borne ni ne fait défiler cette taille quand elle dépasse l'espace alloué par `showModalBottomSheet`/le clavier.
**Alternatives envisagées :** (1) modifier `TagInputField` pour faire défiler ses propres suggestions indépendamment du reste — écarté, la contrainte de la tâche interdit de toucher à ce composant partagé avec le menu contextuel (Tâche 21) et la sélection groupée (Tâche 26), et déplacer le défilement dans l'enfant n'aurait pas réglé le cas où c'est la somme de plusieurs éléments (pas seulement les suggestions) qui dépasse ; (2) envelopper le `Column` du `data:` de `AddBookmarkSheet` dans un `SingleChildScrollView`, au niveau du parent qui connaît l'espace réellement disponible.
**Fix / Décision :** option 2. `lib/features/bookmarks/presentation/add_bookmark_sheet.dart` : le `Column` de la branche `data:` est désormais enveloppé dans un `SingleChildScrollView`. Le padding existant compensant le clavier (`MediaQuery.of(context).viewInsets.bottom + 16`, sur le `Padding` parent) reste inchangé et continue de s'appliquer autour du contenu désormais défilant — aucune double compensation, le comportement visuel du cas normal (pas de clavier, pas de suggestions) est inchangé (vérifié via `integration_test/app_flow_test.dart`, flux complet toujours vert).
**Leçon :** un enfant avec `shrinkWrap: true`/hauteur bornée (`TagInputField`) élimine son propre overflow interne mais ne protège pas son parent d'un dépassement global si ce parent ne défile pas lui-même — le défilement doit être porté par le conteneur qui connaît l'espace réellement disponible (ici la modale, pas le champ de tags).
**Statut :** ✅ Résolu
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 28 — `BookmarkRepository.createBookmark` renseigne désormais `userId` depuis la session active, pas seulement le rattachement rétroactif

**Contexte :** Tâche 28, authentification Supabase. Le prompt de tâche ne demandait explicitement qu'une méthode de rattachement rétroactif (`linkLocalBookmarksToUser`) pour les bookmarks déjà créés hors ligne. Mais `createBookmark` (inchangé depuis la Tâche 5, voir DECISIONS.md « Tâche 5 — `user_id` absent avant l'authentification ») n'a jamais renseigné `userId`, y compris pour un bookmark créé *après* une connexion réussie — sans correctif, un tel bookmark serait resté indéfiniment `userId: null`, ne synchronisant donc jamais, ce qui contredit directement la contrainte de la tâche : "l'app doit rester pleinement utilisable sans compte, la connexion n'active que la synchronisation".
**Alternatives envisagées :** (1) s'en tenir au texte littéral du prompt (rattachement rétroactif uniquement) et documenter ce trou comme une limite connue dans `BUGS_AND_ROADMAP.md` ; (2) faire lire à `createBookmark` l'utilisateur actuellement authentifié, via une fonction injectée en constructeur (`CurrentUserIdProvider`, `String? Function()`), même mécanisme de testabilité que `HasActiveSessionCheck` de `SyncService` (voir DECISIONS.md Tâche 9).
**Décision :** option 2, confirmée explicitement par l'utilisateur avant implémentation. La décision initiale de la Tâche 5 ("pas de dépendance directe à Supabase Auth depuis le repository") supposait qu'aucune authentification n'existait encore dans le projet — ce n'est plus le cas depuis cette tâche, la prémisse ne tient donc plus. `bookmarkRepositoryProvider` injecte `getCurrentUserId: () => SupabaseService.client.auth.currentUser?.id`, cohérent avec `sync_service_provider.dart` qui injecte déjà `hasActiveSession` de la même façon. Impact sur les tests : les 11 fichiers qui construisaient directement un `BookmarkRepository` (10 dans `test/`, 1 dans `integration_test/`) passent désormais aussi `getCurrentUserId: () => null` (comportement inchangé pour ces tests, qui ne testent pas l'authentification), et un nouveau groupe de tests dédié (`bookmark_repository_test.dart`, "authentification (Tâche 28)") couvre le nouveau comportement avec un `getCurrentUserId` renvoyant un id fixe.
**Leçon :** une décision d'architecture prise en l'absence d'une fonctionnalité future ("pas d'authentification pour l'instant") doit être explicitement revisitée le jour où cette fonctionnalité arrive, plutôt que de la considérer comme acquise indéfiniment — sans quoi le nouveau code (l'authentification elle-même) resterait fonctionnellement inerte pour tout ce qui est créé après son introduction.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 28 — Rattachement rétroactif déclenché à la connexion **et** à l'inscription, gardé uniquement par le nombre de bookmarks non liés

**Contexte :** Tâche 28, le prompt contient une formulation ambiguë : "À la connexion réussie (pas à l'inscription si l'utilisateur n'a pas encore de bookmarks locaux non liés — vérifier le compte avant d'afficher quoi que ce soit), si au moins un bookmark local a `userId == null` : afficher une boîte de dialogue...". Lue littéralement au premier degré, cette phrase pourrait suggérer que le rattachement ne doit jamais se déclencher à l'inscription. Mais le critère d'acceptation de la même tâche décrit explicitement le scénario inverse : créer des bookmarks hors ligne, **puis créer un compte** (inscription, pas connexion sur un compte existant) fait apparaître la boîte de confirmation.
**Alternatives envisagées :** (1) lecture littérale stricte — déclencher uniquement sur `signInWithPassword`, jamais sur `signUp` — incompatible avec le critère d'acceptation explicite ; (2) lire la parenthèse comme une clarification du garde-fou (ne rien afficher à l'inscription **si** aucun bookmark non lié n'existe, ce qui est le cas courant pour un tout nouveau compte) plutôt que comme une exclusion totale de l'inscription — cohérente avec le critère d'acceptation et avec la contrainte "vérifier le compte avant d'afficher quoi que ce soit" déjà présente dans la même phrase.
**Décision :** option 2. `AppDrawer` déclenche `promptToLinkLocalBookmarks` sur toute transition "aucune session" → "session active" observée via `authStateChangesProvider` (`ref.listen`), que la session vienne de `signIn` ou de `signUp` — la fonction elle-même ne fait rien (aucune boîte de dialogue) si `countLocalOnlyBookmarks() == 0`, ce qui couvre exactement le cas visé par la parenthèse (une inscription "propre" sans bookmarks locaux préexistants).
**Leçon :** face à une formulation ambiguë dans un prompt de tâche, le critère d'acceptation explicite fait autorité sur une lecture littérale d'une parenthèse elliptique — quand les deux semblent se contredire, chercher la lecture qui les réconcilie avant de trancher, plutôt que d'obéir au texte le plus proche syntaxiquement.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 28 — `AppDrawer` déclenche la confirmation de rattachement depuis son propre `context`, jamais celui d'`AuthForm`

**Contexte :** Tâche 28, la confirmation de rattachement (`promptToLinkLocalBookmarks`) a besoin d'un `BuildContext` valide pour `showDialog`. Le point le plus intuitif pour déclencher cette logique aurait été directement dans `AuthForm._submit()`, juste après un `signIn`/`signUp` réussi.
**Symptôme / problème évité :** dès qu'une connexion réussit, `authStateChangesProvider` émet un nouvel état, ce qui fait immédiatement basculer `AppDrawer` de l'affichage d'`AuthForm` vers la vue "connecté" (`_SignedInDrawerContent`) — retirant `AuthForm` de l'arbre de widgets. Déclencher `showDialog` depuis le `context` d'`AuthForm` après un `await` réseau expose donc à une fenêtre de course : selon l'ordre exact de propagation entre le rebuild de `AppDrawer` et la suite du code de `_submit()`, `AuthForm` pourrait déjà être démonté (`context.mounted == false`) au moment d'afficher la boîte de dialogue.
**Alternatives envisagées :** (1) déclencher depuis `AuthForm`, avec une vérification `context.mounted` juste avant `showDialog` — fonctionnerait la plupart du temps mais resterait dépendant d'un ordre de reconstruction non garanti explicitement par Riverpod/Flutter ; (2) déclencher depuis `AppDrawer` lui-même, via `ref.listen(authStateChangesProvider, ...)` sur la transition "aucune session" → "session active", en utilisant le `context` d'`AppDrawer` — un widget qui reste monté tout du long (seul son contenu interne change entre `AuthForm` et la vue connectée).
**Décision :** option 2. `AppDrawer.build` appelle `ref.listen(authStateChangesProvider, ...)` et invoque `promptToLinkLocalBookmarks(context, ref, ...)` avec son propre `context` — découplé du cycle de vie d'`AuthForm`, robuste à l'ordre de reconstruction.
**Leçon :** quand une action différée (boîte de dialogue après un `await`) dépend d'un `BuildContext`, préférer celui du widget dont la durée de vie couvre tout le scénario (ici le conteneur qui bascule entre deux vues) plutôt que celui du widget transitoire qui va justement disparaître à cause de l'action en cours.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 28 — Erreurs Supabase enveloppées dans `AuthFailure` (exception métier dédiée), jamais `AuthException` exposée à la présentation

**Contexte :** Tâche 28, contrainte explicite : "erreurs Supabase (mauvais mot de passe, email déjà utilisé, etc.) affichées à l'utilisateur, jamais avalées silencieusement". CONVENTIONS.md section Réponses API précise en complément : "les erreurs réseau/API sont capturées dans le repository et remontées sous forme de résultat typé ... ou exception métier dédiée, jamais de `try/catch` silencieux".
**Alternatives envisagées :** (1) laisser `AuthException` (type de `package:supabase_flutter`) remonter telle quelle jusqu'à `AuthForm`, qui la catch directement — plus rapide à écrire, mais couple la couche présentation au type d'erreur d'un SDK tiers ; (2) `AuthRepository` capture `AuthException` et la relève sous forme d'`AuthFailure` (`lib/features/auth/domain/auth_failure.dart`), un type métier propre au projet qui n'expose que le message à afficher.
**Décision :** option 2, cohérente avec la contrainte de CONVENTIONS.md citée ci-dessus. `AuthForm` catch uniquement `AuthFailure`, jamais de type Supabase — si le SDK d'authentification était remplacé un jour, seul `AuthRepository` aurait à changer.
**Leçon :** la même règle déjà appliquée à `BookmarkRepository` (`BookmarkRemoteSyncException`, voir DECISIONS.md Tâche 5) s'applique symétriquement à l'authentification — aucune exception de bibliothèque tierce ne doit franchir la frontière `data/` → `presentation/` sans être d'abord enveloppée.
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 28 — `appScaffoldKeyProvider` placé dans `core/services/`, pas `app/`, malgré une clé "créée au niveau d'AppShell"

**Contexte :** Tâche 28, point 3 du prompt : un `GlobalKey<ScaffoldState>` "créé au niveau d'`AppShell`" et injecté dans `HomeScreen`/`TagsScreen`/`SearchScreen` pour qu'ils ouvrent le `Drawer` parent — écart non anticipé par SPEC.md section 11, à documenter explicitement (demande du prompt).
**Symptôme / problème évité :** ces 3 écrans sont des `features/`, construits indépendamment d'`AppShell` par les routes `go_router` (`StatefulShellRoute.indexedStack`, voir `router.dart`) — il n'existe donc aucun moyen de leur passer la clé par simple paramètre de constructeur. Un premier essai plaçant le provider dans `lib/app/app_scaffold_key_provider.dart` aurait forcé ces 3 écrans à importer depuis `app/`, inversant la direction de dépendance établie depuis DECISIONS.md (Tâche 4, Tâche 6) : `app/` dépend de `features/`, jamais l'inverse.
**Alternatives envisagées :** (1) `lib/app/app_scaffold_key_provider.dart`, au plus près de son usage conceptuel dans `AppShell` — écarté pour la raison ci-dessus ; (2) `lib/core/services/app_scaffold_key_provider.dart` : le provider lui-même ne dépend d'aucune feature (un simple `GlobalKey<ScaffoldState>`), donc `core/` peut le porter sans rien inverser — `HomeScreen`/`TagsScreen`/`SearchScreen` l'importent depuis `core/`, direction déjà établie et normale.
**Décision :** option 2. `AppShell` reste l'unique endroit qui assigne effectivement cette clé à un `Scaffold` (`Scaffold(key: ref.watch(appScaffoldKeyProvider), ...)`) — seul l'emplacement du fichier du provider diffère de ce qu'une lecture superficielle du prompt pourrait suggérer.
**Leçon :** "créé au niveau de X" dans un prompt de tâche décrit un rôle logique, pas nécessairement un emplacement de fichier obligatoire — quand le placer littéralement à cet endroit violerait une règle de dépendance déjà actée, chercher l'emplacement qui respecte la règle tout en gardant le rôle logique intact.
**Statut :** ✅ Résolu

---

## [LIMITE] Tâche 28 — Flux "mot de passe oublié" non implémenté (hors périmètre explicite)

**Contexte :** Tâche 28, contrainte explicite du prompt : "pas de flux 'mot de passe oublié' — à documenter comme dette dans `BUGS_AND_ROADMAP.md` si pertinent, pas à improviser ici."
**Décision :** aucun lien "mot de passe oublié" dans `AuthForm` — un utilisateur qui oublie son mot de passe reste bloqué (pas de `resetPasswordForEmail`) tant que cette dette n'est pas reprise. Documenté dans `BUGS_AND_ROADMAP.md`, section Roadmap.
**Statut :** 🟡 Dette assumée, non résolue

---

## [CHOIX] Tâche 29 — Architecture des thèmes : `ColorScheme.light`/`.dark` explicites + `AppColorTokens` pour les rôles hors standard

**Contexte :** Tâche 29, palette figée avec l'utilisateur (voir SPEC.md section 10) à câbler via un système de thème Material 3, avec contrainte explicite : pas de `ColorScheme.fromSeed` (dérivation algorithmique), `useMaterial3: true` conservé.
**Décision :** `lib/core/theme/app_palette.dart` porte les valeurs brutes nommées par teinte (jamais par rôle). `AppColorTokens extends ThemeExtension<AppColorTokens>` (`app_color_tokens.dart`) porte les 6 rôles sans équivalent `ColorScheme` (`cardBorder`, `tagBackground`, `tagText`, `badgeOverlay`, `badgeText`, `thumbnailPalette`). `AppTheme.light`/`.dark` (`app_theme.dart`) construisent chacun un `ColorScheme.light(...)`/`ColorScheme.dark(...)` (factories Material avec valeurs par défaut, pas `.fromSeed`) en ne surchargeant que les rôles pilotés par la palette (`primary`/`onPrimary`/`secondary`/`onSecondary`/`surface`/`onSurface`/`onSurfaceVariant`/`outline`) — `textMuted` mappé sur `onSurfaceVariant`, `textMutedInactive` sur `outline`, faute de rôle `ColorScheme` dédié plus proche.
**Rôle "background" distinct de "surface" :** la palette distingue fond d'écran (`background`) et fond de carte (`surface`), deux valeurs différentes — non représentable par le seul champ `ColorScheme.surface` (utilisé par défaut à la fois par `Scaffold` et par `Card` en Material 3). Résolu en fixant `ThemeData.scaffoldBackgroundColor` explicitement sur le token `background`, indépendamment de `colorScheme.surface` (réservé au token `surface`/fond de carte).
**`CardThemeData.surfaceTintColor: Colors.transparent` :** Material 3 applique par défaut une superposition de teinte (`surfaceTint`, dérivée de `colorScheme.primary`) sur les surfaces élevées comme `Card` — sans la désactiver, la couleur de fond exacte de la palette (`surface`) serait imperceptiblement altérée par l'accent, contredisant l'objectif de "piloter précisément" les couleurs (même raisonnement que le rejet de `ColorScheme.fromSeed`).
**Leçon :** un système de design qui distingue explicitement plusieurs niveaux de fond (écran vs carte) ne peut pas s'appuyer uniquement sur les rôles `ColorScheme` standard, qui n'en distinguent qu'un (`surface`, utilisé pour tout par défaut en M3) — `scaffoldBackgroundColor` (indépendant du `ColorScheme`) et la désactivation du `surfaceTint` algorithmique sont les deux leviers nécessaires pour reprendre un contrôle exact.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 29 — Thème par défaut : `ThemeMode.system`, révision du "sombre par défaut" de SPEC.md section 10

**Contexte :** SPEC.md section 10 documentait jusqu'ici "Thème par défaut : sombre (`ThemeData.dark(useMaterial3: true)`)". Le prompt de la Tâche 29 impose cependant explicitement : "Le mode système (`ThemeMode.system`) doit suivre le thème OS si l'utilisateur ne l'a jamais changé manuellement dans l'app (première ouverture)."
**Tension identifiée :** ces deux exigences sont incompatibles au sens strict — un premier lancement "sombre par défaut" ne peut pas simultanément "suivre le thème OS" si l'OS est en mode clair.
**Décision :** la contrainte explicite et récente de la Tâche 29 fait autorité sur l'ancienne valeur de SPEC.md section 10, révisée en conséquence (voir la mise à jour de cette section). `themeModeControllerProvider` (`lib/features/settings/data/theme_mode_provider.dart`) vaut `ThemeMode.system` par défaut, jusqu'à ce que l'utilisateur choisisse explicitement un mode via `ThemeModeSelector` (sidebar) — ce choix est alors persisté via `SharedPreferences` et prime définitivement sur le thème OS.
**Leçon :** quand un prompt de tâche contredit explicitement une décision plus ancienne documentée dans SPEC.md, la contrainte la plus récente et la plus explicite l'emporte — mais la contradiction doit être documentée ici plutôt que résolue silencieusement, et SPEC.md mis à jour pour ne pas laisser deux sources de vérité incohérentes.
**Statut :** ✅ Résolu

---

## [CHOIX] Tâche 29 — Résolution des rôles non explicitement assignés par le prompt

**Contexte :** Tâche 29, plusieurs éléments visuels n'étaient pas assignés sans ambiguïté à un rôle précis de la palette par le prompt de tâche.
**Icône de plateforme dans `BookmarkCard` (`badgeText` vs `textMuted`) :** le prompt propose les deux ("teintées avec `AppColorTokens.badgeText` ou `textMuted` selon le contexte d'affichage") sans trancher. Dans la disposition actuelle, cette icône apparaît en ligne à côté du titre, directement sur le fond de carte (`surface`) — jamais en superposition sur une miniature colorée comme un vrai "badge". Décision : `textMuted` (mappé sur `colorScheme.onSurfaceVariant`, voir entrée ci-dessus), `badgeText` étant réservé au cas où une icône se superposerait effectivement à une miniature (non le cas ici).
**Icône du placeholder de miniature (`_BookmarkThumbnail`) :** ce placeholder affiche une icône (`videocam_off_outlined`/`broken_image_outlined`) sur un fond assigné cycliquement depuis `thumbnailPalette` — un vrai cas de superposition sur une couleur pleine. Décision : `badgeText`, seul token prévu par la palette pour "texte/icône sur une surface colorée".
**Indicateur actif de la `NavigationBar` (`AppShell`) :** un premier essai a teinté l'icône active directement en `colorScheme.primary` (accent), sans pastille visible en dessous — jugé insuffisamment lisible par l'utilisateur après relecture visuelle ("les icônes doivent être en blanc... actuellement elles sont en orange"). Décision finale : `indicatorColor: colorScheme.primary` (pastille pleine teinte accent derrière l'icône active) + icône active en `colorScheme.onPrimary` (blanc chaud, `AppPalette.blush`) pour rester lisible sur ce fond — le label sous l'icône reste en `colorScheme.primary`, non superposé à la pastille. Câblé entièrement via `NavigationBarThemeData` dans `AppTheme`, sans toucher `app_shell.dart` (le thème suffit à piloter tout le style du composant).
**Provider de thème nommé `themeModeControllerProvider`, pas `themeModeProvider` :** le prompt utilise `ref.watch(themeModeProvider)` à titre d'exemple, mais un provider Riverpod généré par code nécessite un notifier nommé `ThemeMode` pour produire exactement ce nom — collision directe avec l'enum `ThemeMode` de Flutter, importé dans le même fichier. Le notifier est donc nommé `ThemeModeController`, générant `themeModeControllerProvider` (toujours conforme à CONVENTIONS.md : suffixe `Provider` explicite).
**Nouvelle dépendance directe `flutter_svg` :** déjà présente en dépendance transitive (résolue via une autre dépendance) mais jamais déclarée explicitement ni importée directement dans le code applicatif jusqu'ici. Le câblage des icônes SVG de plateforme (`BookmarkCard._PlatformIcon`) l'importe directement (`SvgPicture.asset` + `colorFilter`) — déclarée en dépendance directe dans `pubspec.yaml`, absente de la liste de SPEC.md section 2 (mise à jour non faite, changement mineur et sans alternative : aucune autre approche ne permet de teinter dynamiquement un SVG selon le thème actif sans réécrire un moteur de rendu SVG maison).
**Fallback `AppColorTokens.dark` dans `BookmarkCard` :** plusieurs tests de widget existants (`home_screen_test.dart`, `search_screen_test.dart`, etc., tous antérieurs à cette tâche) montent un `MaterialApp` minimal sans `theme`/`darkTheme` applicatif, donc sans `AppColorTokens` enregistré — `Theme.of(context).extension<AppColorTokens>()` y renverrait `null`. Plutôt que de modifier les ~8 fichiers de test concernés (hors périmètre de cette tâche, qui ne porte que sur l'app réelle), `BookmarkCard`/`_BookmarkThumbnail` utilisent `Theme.of(context).extension<AppColorTokens>() ?? AppColorTokens.dark` — en usage réel, `main.dart` enregistre toujours l'extension via `AppTheme.light`/`.dark`, ce fallback ne s'active donc jamais en production.
**Leçon :** quand un prompt de tâche propose explicitement plusieurs choix sans trancher ("l'un ou l'autre selon le contexte"), documenter la règle de résolution retenue plutôt que de choisir arbitrairement à chaque site d'appel — ici, la présence ou non d'une superposition sur une image colorée fait la distinction entre `badgeText` et `textMuted`.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 30 — Barre de recherche dans le `bottom:` du `SliverAppBar`, pas un second sliver

**Contexte :** Tâche 30, le prompt laissait un choix technique explicite ("dans le `bottom:` du `SliverAppBar`, ou un second sliver directement en dessous — au choix technique, tant que les deux masquent/réapparaissent ensemble au scroll").
**Alternatives envisagées :** (1) un second `SliverToBoxAdapter` (ou `SliverPersistentHeader`) juste après le `SliverAppBar`, contenant le champ de recherche ; (2) le champ de recherche dans `SliverAppBar.bottom` (`PreferredSize`).
**Décision :** option 2. Un `bottom:` de `SliverAppBar` est explicitement conçu par Flutter pour ce cas (contenu qui doit se masquer/réapparaître strictement synchronisé avec le reste de l'`AppBar`, `floating`/`snap` inclus) — un second sliver séparé aurait exigé de dupliquer manuellement cette même logique de visibilité (aucune garantie native que deux slivers indépendants restent synchronisés au pixel près), sans bénéfice.
**Leçon :** quand l'API native propose déjà un emplacement dédié pour exactement le besoin exprimé (ici `bottom:`, prévu pour du contenu secondaire solidaire de l'`AppBar`), le préférer à une reconstruction manuelle avec un second sliver, qui réintroduirait le risque de désynchronisation que `floating`/`snap` natifs évitent justement.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 30 — Bascule liste/résultats : `bookmarkSearchProvider` regardé conditionnellement, pas en parallèle

**Contexte :** Tâche 30, `HomeScreen` doit reproduire à l'identique le comportement de l'ancien `SearchScreen` (chip de filtre par tag masqué pendant une recherche, les deux filtres ne se combinant jamais).
**Décision :** `HomeScreen` regarde soit `bookmarkListProvider` (+ filtre par tag), soit `bookmarkSearchProvider(query)`, jamais les deux à la fois (`isSearching ? ref.watch(bookmarkSearchProvider(...)) : ref.watch(bookmarkListProvider)`) — `bookmarkListProvider` étant `autoDispose` (voir sa doc), il se dispose donc pendant qu'une recherche est active, et se reconstruit (nouvel accès Isar réel) quand la recherche est effacée. Comportement sans impact en usage réel (juste une relecture Isar supplémentaire, quasi instantanée), mais qui a nécessité d'adapter les tests (voir entrée ci-dessous) : un test widget sous `testWidgets` ne peut pas laisser cette reconstruction se résoudre hors de `tester.runAsync`.
**Alternative écartée :** passer `bookmarkListProvider` en `keepAlive: true` pour éviter cette re-création — non retenu, changement de comportement du provider au-delà du périmètre de cette tâche (purement une recherche intégrée à l'écran, pas une revue du cycle de vie de `bookmarkListProvider`), à ne pas trancher silencieusement.
**Statut :** 🔵 Choix assumé

---

## [CHOIX] Tâche 30 — `BookmarkSelectionScope` réduit à `home` seul, énumération conservée

**Contexte :** Tâche 30, suppression de `SearchScreen` et donc de sa propre instance de `BookmarkSelectionController` (Tâche 26). Le prompt demande explicitement de retirer `search` de `enum BookmarkSelectionScope` sans reconcevoir le contrôleur.
**Décision :** l'enum ne garde que `home`, mais reste une énumération (pas un simple `bool`/singleton) — `BookmarkSelectionController`/`BulkSelectionToolbar` restent paramétrés par ce scope tels quels, sans re-design, pour ne pas re-toucher un mécanisme (family Riverpod) validé en Tâche 26 pour un changement qui ne porte que sur le nombre d'écrans appelants.
**Leçon :** supprimer une valeur d'énumération devenue inutile ne justifie pas de reconcevoir la structure qui la consomme si elle reste par ailleurs valide avec une seule valeur — cohérent avec CONVENTIONS.md (ne pas modifier au-delà de ce que la tâche demande).
**Statut :** 🔵 Choix assumé

---

## [RÉSOLU] Tâche 30 — Tests widgets avec Isar réel sur `HomeScreen` : `pumpWidget` doit être *à l'intérieur* du `runAsync`, pas seulement l'`await` final

**Contexte :** Tâche 30, nouveaux tests de `home_screen_test.dart` couvrant la recherche intégrée (nécessitent un `BookmarkRepository` réel, pas `_FakeBookmarkList`, pour exercer `bookmarkSearchProvider` — voir DECISIONS.md, entrée Tâche 10). Un premier essai reproduisait le pattern de `search_screen_test.dart` (`tester.pumpWidget(...)` hors `runAsync`, puis `await tester.runAsync(() async { await container.read(bookmarkListProvider.future); })`) : blocage indéfini, reproductible à 100 %, dès le premier `pumpWidget`.
**Symptôme / Problème :** `tester.pumpWidget` déclenche de façon synchrone `HomeScreen.build()` → `ref.watch(bookmarkListProvider)` → `BookmarkList.build()` → accès Isar réel (port natif, voir DECISIONS.md Tâche 10). Ce `pumpWidget` avait lieu **hors** de tout bloc `runAsync`, donc dans la zone Dart de `AutomatedTestWidgetsFlutterBinding` (horloge fake). Le `Future` retourné par une opération asynchrone reste lié à la zone dans laquelle elle a été *déclenchée*, pas à celle depuis laquelle on l'attend ensuite — entrer dans un `runAsync` **après coup** pour `await container.read(bookmarkListProvider.future)` ne fait donc jamais aboutir la continuation native, qui reste postée dans la zone fake jamais pompée.
**Cause :** différence avec `search_screen_test.dart` (Tâche 10, toujours vert) : dans ce fichier, la requête vide initiale ne touche jamais Isar (`bookmarkSearchProvider('')` retourne `[]` synchronement sans toucher au repository, voir sa doc), donc le premier `pumpWidget`/`pumpAndSettle` hors `runAsync` ne déclenche jamais réellement d'accès Isar — seul l'`enterText` suivant (dans un bloc `runAsync` unique englobant aussi le `pump()` qui le déclenche) en déclenche un. `HomeScreen`, elle, accède toujours à Isar dès le premier `build()` (`bookmarkListProvider` regardé inconditionnellement dès que la recherche est vide) — la même règle que `bookmark_context_menu_test.dart` (Tâche 21) s'applique donc ici : `pumpWidget` doit être dans le **même** bloc `runAsync` que tout le reste.
**Fix / Décision :** repris le pattern déjà établi par `bookmark_context_menu_test.dart` : un seul bloc `runAsync` par test, englobant `repository.createBookmark`, `tester.pumpWidget`, toutes les interactions (`enterText`, `tap`) et un helper local `pumpFrames` (boucle de vrais délais + `tester.pump(duration)`, `pumpAndSettle()` ne fonctionnant pas non plus à l'intérieur d'un `runAsync`, voir le commentaire déjà présent dans ce fichier) — plutôt que des allers-retours `container.read(provider.future)` ponctuels hors `runAsync`.
**Leçon :** la règle de la Tâche 10 ("toute opération Isar réelle doit être sous `runAsync`") ne suffit pas seule : ce qui compte est la zone Dart dans laquelle l'opération est *déclenchée*, pas seulement celle dans laquelle on l'attend — dès qu'un écran accède à Isar inconditionnellement dès son premier `build()` (`HomeScreen`, contrairement à `SearchScreen` dont la requête vide court-circuitait Isar), le `pumpWidget` initial lui-même doit être dans le bloc `runAsync`, pas seulement les étapes suivantes.
**Statut :** ✅ Résolu — `test/widget/features/bookmarks/presentation/home_screen_test.dart` (groupe "Recherche intégrée")

---

## [RÉSOLU] Tâche 30 — `find.byType(TextField)` devenu ambigu dans deux tests existants de `HomeScreen`

**Contexte :** Tâche 30, l'ajout d'un champ de recherche sur `HomeScreen` (toujours visible, voir plus haut) casse deux tests préexistants qui supposaient un unique `TextField` à l'écran lors d'une saisie dans un dialogue ouvert par-dessus (`bookmark_context_menu_test.dart` : "Modifier les tags" ; `bulk_selection_toolbar_test.dart` : "Ajouter un tag (N)").
**Symptôme / Problème :** `tester.enterText(find.byType(TextField), ...)` échoue avec `Bad state: Too many elements` / `Iterable.single` (deux `TextField` désormais présents : la barre de recherche de `HomeScreen` + le `TextField` interne de `TagInputField` dans le dialogue).
**Fix / Décision :** scope la recherche au dialogue ouvert : `find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField))`, dans les deux fichiers concernés.
**Leçon :** ajouter un `TextField` visible en permanence sur un écran existant peut casser silencieusement des finders `find.byType(TextField)` non scopés dans des tests déjà verts pour ce même écran — à vérifier systématiquement (`grep find.byType(TextField)` sur les fichiers montant l'écran modifié) avant de considérer une tâche d'UI terminée.
**Statut :** ✅ Résolu — `test/widget/features/bookmarks/presentation/bookmark_context_menu_test.dart`, `test/widget/features/bookmarks/presentation/bulk_selection_toolbar_test.dart`
