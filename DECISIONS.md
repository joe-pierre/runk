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
