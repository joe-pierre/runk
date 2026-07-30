# TASK_PROMPTS.md — Instructions de développement pour Claude Code

> Chaque tâche ci-dessous est un prompt **autonome et copiable tel quel** dans Claude Code (bloc `markdown` dédié). Avant de lancer une tâche, vérifie que `TODO.md` confirme que ses dépendances sont bien cochées.
>
> **Règles transversales, rappelées dans chaque prompt mais valables sur TOUTES les tâches sans exception :**
> - Code modulaire, un fichier = une responsabilité. Aucun "god file".
> - Séparation stricte des couches : `presentation/` ne contient jamais de logique métier ni d'appel réseau direct ; `data/` ne contient jamais de widget.
> - Nommage explicite (voir `CONVENTIONS.md`) — aucune abréviation ambiguë (`bkm`, `svc`, `tmp` proscrits).
> - Chaque classe et fonction publique documentée par un commentaire `///` expliquant son rôle, pas seulement sa signature.
> - Aucune ambiguïté n'est tranchée silencieusement — elle est documentée dans `DECISIONS.md` selon le format standard.
> - **Aucun commit n'est fait avant validation explicite** ("commit" dit clairement par l'utilisateur).
> - À la fin de la tâche (une fois le commit autorisé) : mettre à jour `TODO.md` (cocher les cases), `DECISIONS.md` (si un choix ou un bug a été traité) et `BUGS_AND_ROADMAP.md` (si pertinent).

---

## TÂCHE 1 — Setup du projet Flutter + Supabase

```markdown
Contexte : démarrage du projet Runk (Flutter, Riverpod, GoRouter, Isar, Supabase) — app mobile de sauvegarde de vidéos cross-plateformes. Aucun code n'existe encore. Voir SPEC.md sections 1 et 2 pour la vue d'ensemble et la stack complète.

Branche : feat/project-setup

## Ce qui est demandé

1. **Initialisation du projet** (si non fait) :
   - `flutter create runk --org com.senluxtech`
   - Vérifie que l'identifiant final est bien `com.senluxtech.runk`

2. **Dépendances** dans `pubspec.yaml` — ajoute exactement celles listées dans SPEC.md section 2, aucune dépendance supplémentaire non justifiée par la spec :
   go_router, flutter_riverpod, riverpod_annotation, isar, isar_flutter_libs, path_provider, supabase_flutter, receive_sharing_intent, any_link_preview, http, url_launcher, uuid, intl (+ dev: build_runner, isar_generator, riverpod_generator, flutter_lints)

3. **Configuration environnement** :
   - Crée `lib/core/config/env.dart` lisant les variables via `String.fromEnvironment` — jamais de clé Supabase en dur (voir CONVENTIONS.md section Sécurité)

4. **Service Supabase** :
   - Crée `lib/core/services/supabase_service.dart` — responsabilité unique : initialisation du client Supabase, exposée via un getter statique ou un provider Riverpod. Aucune logique métier dans ce fichier.
   - Initialise Supabase dans `main.dart` avant `runApp`

5. **Base de données Supabase** :
   - Exécute le schéma SQL de SPEC.md section 3.2 sur un projet Supabase de développement (table `bookmarks` + RLS)

6. **Vérification** :
   - `flutter run` doit lancer l'app sans erreur
   - Confirme la connexion Supabase active par un test temporaire (log ou print), à retirer avant la fin de la tâche
   - `flutter analyze` ne doit remonter aucun warning

## Contraintes

- Respecte CLAUDE.md et CONVENTIONS.md : structure de dossiers `lib/app/`, `lib/features/`, `lib/core/` dès le départ, même si peu peuplée à ce stade
- N'ajoute aucune dépendance non listée dans SPEC.md section 2, même si elle semble utile — signale-la plutôt dans BUGS_AND_ROADMAP.md pour discussion ultérieure

## Contrainte de process

Ne fais **aucun commit** avant que je te dise explicitement "commit".

**Critère d'acceptation :** `flutter run` fonctionne, la connexion Supabase est confirmée active, `flutter analyze` est propre.
```

> **Règles transversales, rappelées dans chaque prompt mais valables sur TOUTES les tâches sans exception :**
> - Code modulaire, un fichier = une responsabilité. Aucun "god file".
> - Séparation stricte des couches : `presentation/` ne contient jamais de logique métier ni d'appel réseau direct ; `data/` ne contient jamais de widget.
> - Nommage explicite (voir `CONVENTIONS.md`) — aucune abréviation ambiguë (`bkm`, `svc`, `tmp` proscrits).
> - Chaque classe et fonction publique documentée par un commentaire `///` expliquant son rôle, pas seulement sa signature.
> - Aucune ambiguïté n'est tranchée silencieusement — elle est documentée dans `DECISIONS.md` selon le format standard.
> - **Aucun commit n'est fait avant validation explicite** ("commit" dit clairement par l'utilisateur).
> - À la fin de la tâche (une fois le commit autorisé) : mettre à jour `TODO.md` (cocher les cases), `DECISIONS.md` (si un choix ou un bug a été traité) et `BUGS_AND_ROADMAP.md` (si pertinent).

---

## TÂCHE 2 — Share Intent Android

```markdown
Contexte : Runk doit recevoir un lien vidéo partagé depuis une app tierce (Instagram, TikTok, etc.) via le menu de partage natif Android. C'est le cœur de l'expérience utilisateur — voir SPEC.md section 1 (fonctionnement cible) et section 13 (race conditions liées aux partages multiples).

Branche : feat/share-intent-android

## Ce qui est demandé

1. **Configuration Android** :
   - Dans `android/app/src/main/AndroidManifest.xml`, ajoute les intent-filters `SEND` et `SEND_MULTIPLE` sur `MainActivity`
   - Ajoute `android:launchMode="singleTask"` pour éviter les instances dupliquées de l'app lors d'un partage répété

2. **Service de réception** :
   - Crée `lib/core/services/share_intent_service.dart` — responsabilité unique : écouter les intents de partage et exposer les URLs valides via un `Stream<String>`
   - N'y mets **aucune logique d'ouverture de modale** — ça appartient à la couche présentation qui consommera ce service plus tard (Tâche 6)
   - Implémente une validation d'URL (`_isValidUrl`, méthode privée) : schéma `http`/`https` obligatoire, rejet silencieux sinon

3. **Test unitaire** :
   - `test/unit/services/share_intent_service_test.dart` — vérifie que les chaînes non-URL sont rejetées silencieusement par `_isValidUrl`

## Contraintes

- Ne touche à aucun fichier hors du périmètre Share Intent — pas de modale, pas de repository, pas de metadata (ce sont d'autres tâches)
- Le service doit être réutilisable tel quel pour iOS (Tâche 3) sans duplication de logique de validation

## Contrainte de process

Ne fais **aucun commit** avant que je te dise explicitement "commit".

**Critère d'acceptation :** sur un appareil Android physique, partager un lien Instagram/TikTok propose "Runk" dans le menu de partage, et le stream du service émet bien l'URL reçue.
```
> **Règles transversales, rappelées dans chaque prompt mais valables sur TOUTES les tâches sans exception :**
> - Code modulaire, un fichier = une responsabilité. Aucun "god file".
> - Séparation stricte des couches : `presentation/` ne contient jamais de logique métier ni d'appel réseau direct ; `data/` ne contient jamais de widget.
> - Nommage explicite (voir `CONVENTIONS.md`) — aucune abréviation ambiguë (`bkm`, `svc`, `tmp` proscrits).
> - Chaque classe et fonction publique documentée par un commentaire `///` expliquant son rôle, pas seulement sa signature.
> - Aucune ambiguïté n'est tranchée silencieusement — elle est documentée dans `DECISIONS.md` selon le format standard.
> - **Aucun commit n'est fait avant validation explicite** ("commit" dit clairement par l'utilisateur).
> - À la fin de la tâche (une fois le commit autorisé) : mettre à jour `TODO.md` (cocher les cases), `DECISIONS.md` (si un choix ou un bug a été traité) et `BUGS_AND_ROADMAP.md` (si pertinent).

---

## TÂCHE 3 — Share Intent iOS (Share Extension)

```markdown
Contexte : équivalent iOS de la Tâche 2 (déjà faite — `ShareIntentService` existe et fonctionne côté Android). Voir SPEC.md sections 1 et 13.

Branche : feat/share-intent-ios

## Ce qui est demandé

1. **Target Xcode** :
   - Crée le target `RunkShareExtension` (Share Extension) dans `ios/Runner.xcworkspace` s'il n'existe pas déjà
   - Active l'App Group `group.com.senluxtech.runk` sur les deux targets `Runner` et `RunkShareExtension`

2. **Implémentation native** :
   - Implémente `ShareViewController.swift` : récupère l'URL partagée et l'écrit dans le conteneur partagé via `UserDefaults(suiteName:)`

3. **Intégration Dart** :
   - Vérifie que `receive_sharing_intent` récupère bien cette donnée côté Dart
   - **Réutilise le `ShareIntentService` existant de la Tâche 2** — ne duplique jamais la logique de validation d'URL entre iOS et Android, un seul service Dart pour les deux plateformes

## Contraintes

- N'ajoute pas de nouveau service Dart pour iOS — un seul `ShareIntentService` partagé
- Le simulateur iOS n'est pas fiable pour tester le Share Intent — la vérification doit se faire sur appareil physique

## Contrainte de process

Ne fais **aucun commit** avant que je te dise explicitement "commit".

**Critère d'acceptation :** sur un appareil iOS physique, le partage depuis Instagram/TikTok propose Runk et transmet l'URL au même `ShareIntentService` que sur Android.
```
> **Règles transversales, rappelées dans chaque prompt mais valables sur TOUTES les tâches sans exception :**
> - Code modulaire, un fichier = une responsabilité. Aucun "god file".
> - Séparation stricte des couches : `presentation/` ne contient jamais de logique métier ni d'appel réseau direct ; `data/` ne contient jamais de widget.
> - Nommage explicite (voir `CONVENTIONS.md`) — aucune abréviation ambiguë (`bkm`, `svc`, `tmp` proscrits).
> - Chaque classe et fonction publique documentée par un commentaire `///` expliquant son rôle, pas seulement sa signature.
> - Aucune ambiguïté n'est tranchée silencieusement — elle est documentée dans `DECISIONS.md` selon le format standard.
> - **Aucun commit n'est fait avant validation explicite** ("commit" dit clairement par l'utilisateur).
> - À la fin de la tâche (une fois le commit autorisé) : mettre à jour `TODO.md` (cocher les cases), `DECISIONS.md` (si un choix ou un bug a été traité) et `BUGS_AND_ROADMAP.md` (si pertinent).

---

## TÂCHE 4 — Metadata Service : fondations + YouTube + TikTok

```markdown
Contexte : Runk doit récupérer automatiquement titre et miniature d'une vidéo partagée. YouTube et TikTok exposent des endpoints oEmbed officiels et fiables — on commence par eux avant d'étendre aux plateformes plus fragiles (Instagram, Facebook, Threads en Tâche 7). Voir SPEC.md sections 5 (architecture en providers) et 8 (extensibilité).

Branche : feat/metadata-service-base

## Ce qui est demandé

1. **Détection de plateforme** :
   - Crée `lib/core/utils/source_detector.dart` : détection de `VideoSource` par domaine, fonction pure et testable, sans dépendance à Flutter ni à un état global

2. **Interface commune** :
   - Crée `lib/core/services/metadata/providers/metadata_provider.dart` : interface abstraite avec `canHandle(url)` et `fetchMetadata(url)`

3. **Providers YouTube et TikTok** :
   - `youtube_provider.dart` et `tiktok_provider.dart`, chacun s'appuyant sur son endpoint oEmbed officiel respectif
   - Chaque provider ne connaît que sa propre plateforme — aucune référence croisée entre providers

4. **Fallback générique** :
   - `generic_fallback_provider.dart` : retourne un `VideoMetadata` avec `isPartial: true` et un titre par défaut ("Vidéo sans titre")

5. **Orchestrateur** :
   - `metadata_service.dart` : sélectionne le provider adapté via `canHandle`, applique un timeout de 5s (voir SPEC.md section 9), et bascule vers le fallback en cas d'exception ou de timeout

6. **Tests** :
   - Test unitaire par provider (mock des réponses HTTP)
   - Test de l'orchestrateur vérifiant que le fallback est bien appelé si le provider principal échoue

## Contraintes

- `metadata_service.dart` orchestre uniquement — aucune logique de scraping spécifique à une plateforme ne doit y résider
- Ne crée pas encore les providers Instagram/Facebook/Twitter/Threads — c'est la Tâche 7

## Contrainte de process

Ne fais **aucun commit** avant que je te dise explicitement "commit".

**Critère d'acceptation :** `MetadataService.fetch(url)` avec une URL YouTube ou TikTok retourne titre + miniature corrects ; une URL non gérée retourne un résultat `isPartial: true` sans exception non gérée.
```
> **Règles transversales, rappelées dans chaque prompt mais valables sur TOUTES les tâches sans exception :**
> - Code modulaire, un fichier = une responsabilité. Aucun "god file".
> - Séparation stricte des couches : `presentation/` ne contient jamais de logique métier ni d'appel réseau direct ; `data/` ne contient jamais de widget.
> - Nommage explicite (voir `CONVENTIONS.md`) — aucune abréviation ambiguë (`bkm`, `svc`, `tmp` proscrits).
> - Chaque classe et fonction publique documentée par un commentaire `///` expliquant son rôle, pas seulement sa signature.
> - Aucune ambiguïté n'est tranchée silencieusement — elle est documentée dans `DECISIONS.md` selon le format standard.
> - **Aucun commit n'est fait avant validation explicite** ("commit" dit clairement par l'utilisateur).
> - À la fin de la tâche (une fois le commit autorisé) : mettre à jour `TODO.md` (cocher les cases), `DECISIONS.md` (si un choix ou un bug a été traité) et `BUGS_AND_ROADMAP.md` (si pertinent).

---

## TÂCHE 5 — Modèle de données et couche `data/` (Repository)

```markdown
Contexte : Runk fonctionne offline-first — chaque bookmark doit persister localement (Isar) puis se synchroniser vers Supabase. Voir SPEC.md sections 3 (modèle de données complet) et 4 (règle métier 2 sur l'offline-first).

Branche : feat/bookmark-data-layer

## Ce qui est demandé

1. **Modèle applicatif** :
   - Crée `lib/features/bookmarks/domain/video_bookmark.dart` selon SPEC.md section 3.1 — modèle pur, sans dépendance à Isar ni Supabase

2. **Datasource locale** :
   - Crée `lib/features/bookmarks/data/bookmark_local_datasource.dart` avec le modèle Isar `BookmarkEntity` (annoté `@collection`, voir SPEC.md section 3.3) et ses méthodes CRUD locales

3. **Datasource distante** :
   - Crée `lib/features/bookmarks/data/bookmark_remote_datasource.dart` : uniquement les appels Supabase (`insert`, `select`, `update`, `delete`), retournant des `Map` bruts — le mapping vers `VideoBookmark` se fait exclusivement dans le repository, jamais ici

4. **Repository** :
   - Crée `lib/features/bookmarks/data/bookmark_repository.dart` : point d'entrée unique pour la couche présentation, applique la logique offline-first (écriture locale d'abord, `isSynced: false`, tentative de sync immédiate si connecté)

5. **Génération de code** :
   - Lance `dart run build_runner build --delete-conflicting-outputs` pour générer les fichiers Isar

## Contraintes

- Aucun widget ne doit jamais appeler directement Isar ou Supabase — uniquement via `BookmarkRepository`
- Le mapping `Map` → `VideoBookmark` reste dans le repository, jamais dans le datasource distant

## Contrainte de process

Ne fais **aucun commit** avant que je te dise explicitement "commit".

**Critère d'acceptation :** un test d'intégration create → read → update → delete passe sur `BookmarkRepository` avec un Isar en mémoire de test, sans dépendre d'une connexion Supabase réelle (mock du datasource remote).
```

---

## TÂCHE 6 — UI : `AddBookmarkSheet` et `HomeScreen`

```markdown
Contexte : premier flux complet et visible de Runk, de bout en bout, pour YouTube/TikTok. S'appuie sur `ShareIntentService` (Tâches 2-3), `MetadataService` (Tâche 4) et `BookmarkRepository` (Tâche 5), déjà en place. Voir SPEC.md section 11 (écrans) et section 13 (gestion des partages multiples).

Branche : feat/bookmarks-ui-base

## Ce qui est demandé

1. **Modale d'ajout** :
   - Crée `lib/features/bookmarks/presentation/add_bookmark_sheet.dart` (`showModalBottomSheet`) : miniature (ou placeholder si `isPartial`), titre pré-rempli mais éditable, champ de tags, bouton de sauvegarde
   - Appelle `MetadataService` puis `BookmarkRepository` — jamais directement Supabase ou Isar

2. **Carte de bookmark** :
   - Crée `lib/features/bookmarks/presentation/bookmark_card.dart` : composant réutilisable (miniature, titre, tags, icône de plateforme)

3. **Écran d'accueil** :
   - Crée `lib/features/bookmarks/presentation/home_screen.dart` : liste triée par date décroissante, alimentée par un provider Riverpod exposant les bookmarks via le repository

4. **Branchement du Share Intent** :
   - Connecte `ShareIntentService` au widget racine pour ouvrir automatiquement `AddBookmarkSheet` avec l'URL reçue
   - Gère la file d'attente en cas de partages multiples rapides (voir SPEC.md section 13) — une modale à la fois

## Contraintes

- Aucune logique métier dans les widgets — un widget lit un provider et affiche un état, il ne décide jamais lui-même comment récupérer une métadonnée
- Ne développe pas encore `TagsScreen` ni `SearchScreen` (Tâche 9)

## Contrainte de process

Ne fais **aucun commit** avant que je te dise explicitement "commit".

**Critère d'acceptation :** partager un lien YouTube depuis un appareil physique ouvre la modale pré-remplie ; la sauvegarde fait apparaître le bookmark dans `HomeScreen`, persistant après fermeture/réouverture de l'app.
```
> **Règles transversales, rappelées dans chaque prompt mais valables sur TOUTES les tâches sans exception :**
> - Code modulaire, un fichier = une responsabilité. Aucun "god file".
> - Séparation stricte des couches : `presentation/` ne contient jamais de logique métier ni d'appel réseau direct ; `data/` ne contient jamais de widget.
> - Nommage explicite (voir `CONVENTIONS.md`) — aucune abréviation ambiguë (`bkm`, `svc`, `tmp` proscrits).
> - Chaque classe et fonction publique documentée par un commentaire `///` expliquant son rôle, pas seulement sa signature.
> - Aucune ambiguïté n'est tranchée silencieusement — elle est documentée dans `DECISIONS.md` selon le format standard.
> - **Aucun commit n'est fait avant validation explicite** ("commit" dit clairement par l'utilisateur).
> - À la fin de la tâche (une fois le commit autorisé) : mettre à jour `TODO.md` (cocher les cases), `DECISIONS.md` (si un choix ou un bug a été traité) et `BUGS_AND_ROADMAP.md` (si pertinent).

---

## TÂCHE 6.5 — Détection de lien vidéo via clipboard

```markdown
Contexte : en complément du Share Intent, Runk doit proposer (jamais sauvegarder automatiquement) l'ajout d'une vidéo dont le lien a simplement été copié dans le presse-papier — par exemple depuis un navigateur ou un message. S'appuie sur `SourceDetector` (Tâche 4) et `AddBookmarkSheet` (Tâche 6), déjà en place. Voir SPEC.md section 4 règle 7 (non-intrusivité), section 9 (différences iOS/Android) et section 13 (priorité Share Intent > clipboard).

Branche : feat/clipboard-detection

## Ce qui est demandé

1. **Service de détection** :
   - Crée `lib/core/services/clipboard_service.dart` : observe le cycle de vie via `WidgetsBindingObserver`, ne lit le clipboard **que** sur transition vers `AppLifecycleState.resumed` — aucune lecture en arrière-plan, aucun timer périodique
   - Réutilise `SourceDetector` pour valider le contenu ; ignore silencieusement si ce n'est pas une URL vidéo reconnue

2. **Historique des liens déjà traités** :
   - Maintiens un historique léger (SharedPreferences ou table Isar dédiée) des liens déjà proposés ou explicitement ignorés — un même lien ne doit **jamais** être reproposé

3. **Priorité sur le Share Intent** :
   - Avant d'afficher la suggestion, vérifie qu'aucun Share Intent n'est en cours de traitement — le Share Intent (action explicite) a toujours priorité sur la suggestion clipboard (action passive)

4. **UI de suggestion** :
   - Crée `lib/features/bookmarks/presentation/clipboard_suggestion_banner.dart` : bannière non bloquante en haut de `HomeScreen`, actions "Ajouter" (ouvre `AddBookmarkSheet` pré-remplie) et "Ignorer" (mémorise le lien comme ignoré, referme la bannière)

5. **Vérification** :
   - Teste manuellement sur iOS 16+ (`detectPatterns` si le plugin le permet, pour éviter la bannière système) et sur iOS < 16 (bannière système native acceptée comme limitation de plateforme, documentée en commentaire `///`)

## Contraintes

- **Aucune sauvegarde automatique** — le service détecte et propose, seule une action "Ajouter" explicite de l'utilisateur crée un bookmark
- Ne modifie pas `ShareIntentService` lui-même — consulte seulement son état
- Pas de persistance distante de l'historique des liens ignorés — reste local, non synchronisé sur Supabase

## Contrainte de process

Ne fais **aucun commit** avant que je te dise explicitement "commit".

**Critère d'acceptation :** copier un lien TikTok valide, revenir sur Runk fait apparaître la bannière une seule fois ; "Ignorer" puis rouvrir l'app ne la fait plus réapparaître pour ce lien ; un Share Intent en cours empêche temporairement la bannière.
```

> **Règles transversales, rappelées dans chaque prompt mais valables sur TOUTES les tâches sans exception :**
> - Code modulaire, un fichier = une responsabilité. Aucun "god file".
> - Séparation stricte des couches : `presentation/` ne contient jamais de logique métier ni d'appel réseau direct ; `data/` ne contient jamais de widget.
> - Nommage explicite (voir `CONVENTIONS.md`) — aucune abréviation ambiguë (`bkm`, `svc`, `tmp` proscrits).
> - Chaque classe et fonction publique documentée par un commentaire `///` expliquant son rôle, pas seulement sa signature.
> - Aucune ambiguïté n'est tranchée silencieusement — elle est documentée dans `DECISIONS.md` selon le format standard.
> - **Aucun commit n'est fait avant validation explicite** ("commit" dit clairement par l'utilisateur).
> - À la fin de la tâche (une fois le commit autorisé) : mettre à jour `TODO.md` (cocher les cases), `DECISIONS.md` (si un choix ou un bug a été traité) et `BUGS_AND_ROADMAP.md` (si pertinent).

---

## TÂCHE 7 — Extension aux plateformes restantes (X, Instagram, Facebook, Threads)

```markdown
Contexte : couverture complète des 6 plateformes cibles de Runk. Le pattern provider est déjà validé avec YouTube/TikTok (Tâche 4) — cette tâche est le test de l'extensibilité de l'architecture définie en SPEC.md section 8 : aucune autre partie du code ne doit être modifiée hors des fichiers listés ci-dessous.

Branche : feat/metadata-remaining-platforms

## Ce qui est demandé

1. **Nouveaux providers**, suivant exactement le pattern de la Tâche 4 :
   - `twitter_provider.dart` — endpoint oEmbed officiel `publish.twitter.com`
   - `instagram_provider.dart`, `facebook_provider.dart`, `threads_provider.dart` — scraping des balises `og:title`/`og:image`, timeout court, fallback systématique vers `isPartial: true` en cas d'échec (aucune exception de scraping ne doit remonter jusqu'à l'UI)

2. **Enregistrement** :
   - Ajoute chaque provider dans la liste de `metadata_service.dart` — c'est la **seule** modification attendue sur ce fichier

3. **Détection de domaine** :
   - Mets à jour `source_detector.dart` pour reconnaître les domaines de ces 4 plateformes

4. **Icônes** :
   - Ajoute les icônes correspondantes dans `assets/icons/`

5. **Tests** :
   - Teste chaque provider isolément (mock HTTP) avant de l'enregistrer dans l'orchestrateur

## Contraintes

- N'apporte **aucune** modification aux fichiers déjà validés des Tâches 4-6 en dehors de `metadata_service.dart` (enregistrement) et `source_detector.dart` (domaines) — si tu penses qu'une autre modification est nécessaire, documente-le dans DECISIONS.md plutôt que de la faire silencieusement
- `isPartial: true` est un résultat attendu et normal pour Facebook/Threads, pas un bug à corriger à tout prix

## Contrainte de process

Ne fais **aucun commit** avant que je te dise explicitement "commit".

**Critère d'acceptation :** partager un lien de chacune des 6 plateformes produit un bookmark valide, avec `isPartial` correctement positionné pour Facebook/Threads en cas d'échec de scraping.
```

> **Règles transversales, rappelées dans chaque prompt mais valables sur TOUTES les tâches sans exception :**
> - Code modulaire, un fichier = une responsabilité. Aucun "god file".
> - Séparation stricte des couches : `presentation/` ne contient jamais de logique métier ni d'appel réseau direct ; `data/` ne contient jamais de widget.
> - Nommage explicite (voir `CONVENTIONS.md`) — aucune abréviation ambiguë (`bkm`, `svc`, `tmp` proscrits).
> - Chaque classe et fonction publique documentée par un commentaire `///` expliquant son rôle, pas seulement sa signature.
> - Aucune ambiguïté n'est tranchée silencieusement — elle est documentée dans `DECISIONS.md` selon le format standard.
> - **Aucun commit n'est fait avant validation explicite** ("commit" dit clairement par l'utilisateur).
> - À la fin de la tâche (une fois le commit autorisé) : mettre à jour `TODO.md` (cocher les cases), `DECISIONS.md` (si un choix ou un bug a été traité) et `BUGS_AND_ROADMAP.md` (si pertinent).

---

## TÂCHE 8 — `DeepLinkService` (réouverture dans l'app source)

```markdown
Contexte : taper sur une vignette de bookmark dans Runk doit rouvrir la vidéo dans son app d'origine. Voir SPEC.md section 4 règle 5 (priorité au deep link natif + fallback navigateur).

Branche : feat/deep-link-service

## Ce qui est demandé

1. **Service de deep link** :
   - Crée `lib/core/services/deep_link_service.dart` avec une méthode `openInSource(url, source)` : tente le schéma natif de la plateforme, bascule automatiquement vers le navigateur (`url_launcher`, `LaunchMode.externalApplication`) si le schéma échoue ou n'est pas géré

2. **Documentation du risque** :
   - Documente en commentaire `///` que les schémas natifs (`instagram://`, `snssdk1233://`, etc.) sont non officiels et peuvent casser sans préavis — renvoie vers BUGS_AND_ROADMAP.md pour le suivi

3. **Branchement UI** :
   - Connecte ce service au tap de `BookmarkCard`

## Contraintes

- Le fallback navigateur n'est pas optionnel — il doit systématiquement s'exécuter si le deep link natif échoue, jamais de plantage silencieux

## Contrainte de process

Ne fais **aucun commit** avant que je te dise explicitement "commit".

**Critère d'acceptation :** taper sur une vignette Instagram/TikTok ouvre l'app correspondante si installée, sinon le navigateur, sans jamais planter l'app.
```

> **Règles transversales, rappelées dans chaque prompt mais valables sur TOUTES les tâches sans exception :**
> - Code modulaire, un fichier = une responsabilité. Aucun "god file".
> - Séparation stricte des couches : `presentation/` ne contient jamais de logique métier ni d'appel réseau direct ; `data/` ne contient jamais de widget.
> - Nommage explicite (voir `CONVENTIONS.md`) — aucune abréviation ambiguë (`bkm`, `svc`, `tmp` proscrits).
> - Chaque classe et fonction publique documentée par un commentaire `///` expliquant son rôle, pas seulement sa signature.
> - Aucune ambiguïté n'est tranchée silencieusement — elle est documentée dans `DECISIONS.md` selon le format standard.
> - **Aucun commit n'est fait avant validation explicite** ("commit" dit clairement par l'utilisateur).
> - À la fin de la tâche (une fois le commit autorisé) : mettre à jour `TODO.md` (cocher les cases), `DECISIONS.md` (si un choix ou un bug a été traité) et `BUGS_AND_ROADMAP.md` (si pertinent).

---

## TÂCHE 9 — `TagsScreen`, `SearchScreen` et `SyncService`

```markdown
Contexte : fonctionnalités secondaires de navigation (tags, recherche) et robustesse de la synchronisation offline-first déjà amorcée dans `BookmarkRepository` (Tâche 5). Voir SPEC.md section 11 (écrans) et section 3.3 (flags `isSynced`/`isDeletedLocally`).

Branche : feat/secondary-features

## Ce qui est demandé

1. **Écran Tags** :
   - `tags_screen.dart` : liste des tags distincts utilisés, tap sur un tag filtre `HomeScreen` (réutilise `BookmarkCard`, ne duplique pas l'affichage)

2. **Écran Recherche** :
   - `search_screen.dart` : recherche full-text sur titre + tags, en s'appuyant sur les capacités de requête Isar en local — pas d'appel Supabase pour une recherche, la donnée locale est la source de vérité pour l'affichage

3. **Service de synchronisation** :
   - `sync_service.dart` : logique Isar → Supabase, gérant les flags `isSynced` et `isDeletedLocally` (voir SPEC.md section 3.3) ; tourne en tâche de fond (reconnexion réseau + périodique), jamais bloquant pour l'UI

## Contraintes

- Aucun appel réseau direct dans `search_screen.dart` — recherche purement locale
- `sync_service.dart` doit vérifier `isDeletedLocally` en priorité avant tout envoi vers Supabase (voir SPEC.md section 13)

## Contrainte de process

Ne fais **aucun commit** avant que je te dise explicitement "commit".

**Critère d'acceptation :** créer un bookmark hors ligne puis reconnecter le réseau fait apparaître le bookmark sur un second appareil connecté au même compte Supabase, sans action manuelle.
```

> **Règles transversales, rappelées dans chaque prompt mais valables sur TOUTES les tâches sans exception :**
> - Code modulaire, un fichier = une responsabilité. Aucun "god file".
> - Séparation stricte des couches : `presentation/` ne contient jamais de logique métier ni d'appel réseau direct ; `data/` ne contient jamais de widget.
> - Nommage explicite (voir `CONVENTIONS.md`) — aucune abréviation ambiguë (`bkm`, `svc`, `tmp` proscrits).
> - Chaque classe et fonction publique documentée par un commentaire `///` expliquant son rôle, pas seulement sa signature.
> - Aucune ambiguïté n'est tranchée silencieusement — elle est documentée dans `DECISIONS.md` selon le format standard.
> - **Aucun commit n'est fait avant validation explicite** ("commit" dit clairement par l'utilisateur).
> - À la fin de la tâche (une fois le commit autorisé) : mettre à jour `TODO.md` (cocher les cases), `DECISIONS.md` (si un choix ou un bug a été traité) et `BUGS_AND_ROADMAP.md` (si pertinent).

---

## TÂCHE 10 — CI et test d'intégration du flux interne

```markdown
Contexte : protéger le flux principal (Share Intent → Metadata → Save → affichage, opérationnel depuis la Tâche 6) contre les régressions à mesure que les tâches suivantes modifient le code. Voir CONVENTIONS.md section Tests.

Branche : feat/ci-integration-tests

## Ce qui est demandé

1. **Workflow CI** :
   - Crée `.github/workflows/ci.yml` : déclenché sur chaque `pull_request`, exécute `flutter pub get`, `flutter analyze`, `flutter test` dans l'ordre
   - Utilise le cache officiel de `subosito/flutter-action` pour éviter de retélécharger le SDK à chaque run
   - La CI doit échouer (statut rouge) si `flutter analyze` retourne un warning ou si un seul test échoue — aucune exception silencieuse tolérée

2. **Test d'intégration du flux interne** :
   - Crée `integration_test/app_flow_test.dart` — **ne dépend d'aucune app tierce réelle** : simule directement l'émission d'une URL valide dans le stream de `ShareIntentService` (mock ou fake), puis vérifie via `WidgetTester` que la modale s'ouvre, que la sauvegarde crée une entrée dans le repository, et que `HomeScreen` affiche le nouveau bookmark

3. **Documentation** :
   - Documente dans `guide.md` section 6 la commande locale `flutter test integration_test`

## Contraintes

- Ne simule **pas** le partage réel depuis Instagram/TikTok dans ce test — ce comportement reste couvert uniquement par la checklist manuelle sur appareil physique (guide.md section 6.3)
- N'automatise pas les deep links de retour vers les apps sources — même raison (voir DECISIONS.md)

## Contrainte de process

Ne fais **aucun commit** avant que je te dise explicitement "commit".

**Critère d'acceptation :** ouvrir une pull request avec une régression volontaire (ex: casser temporairement `BookmarkRepository.save`) fait échouer la CI visiblement, avant tout merge possible.
```

> **Règles transversales, rappelées dans chaque prompt mais valables sur TOUTES les tâches sans exception :**
> - Code modulaire, un fichier = une responsabilité. Aucun "god file".
> - Séparation stricte des couches : `presentation/` ne contient jamais de logique métier ni d'appel réseau direct ; `data/` ne contient jamais de widget.
> - Nommage explicite (voir `CONVENTIONS.md`) — aucune abréviation ambiguë (`bkm`, `svc`, `tmp` proscrits).
> - Chaque classe et fonction publique documentée par un commentaire `///` expliquant son rôle, pas seulement sa signature.
> - Aucune ambiguïté n'est tranchée silencieusement — elle est documentée dans `DECISIONS.md` selon le format standard.
> - **Aucun commit n'est fait avant validation explicite** ("commit" dit clairement par l'utilisateur).
> - À la fin de la tâche (une fois le commit autorisé) : mettre à jour `TODO.md` (cocher les cases), `DECISIONS.md` (si un choix ou un bug a été traité) et `BUGS_AND_ROADMAP.md` (si pertinent).

---

## TÂCHE 11 — Préparation au déploiement

```markdown
Contexte : Runk est fonctionnellement complet (toutes les tâches précédentes validées) et doit être préparé pour la publication sur Google Play et l'App Store. Voir guide.md sections 7 et 8 pour la procédure complète.

Branche : feat/deployment-prep

## Ce qui est demandé

Suis intégralement guide.md sections 7 (déploiement en production) et 8 (checklist finale) :
- Rédaction et publication de la politique de confidentialité sur runkapp.com/privacy
- Icône d'application et splash screen définitifs
- Création d'un projet Supabase de production séparé du dev
- Signature Android (`key.properties` + keystore)
- Certificats et provisioning iOS configurés
- Publication TestFlight (iOS) et test interne (Android) avant soumission publique

## Contraintes

- Ne coche les cases correspondantes dans TODO.md (Phase 7) qu'une fois chaque point vérifié concrètement — pas de case cochée par anticipation
- Aucune clé de production ne doit apparaître en dur dans le code ou être commitée

## Contrainte de process

Ne fais **aucun commit** avant que je te dise explicitement "commit".

**Critère d'acceptation :** checklist complète de guide.md section 8 validée point par point, build TestFlight et test interne Android disponibles.
```
> **Règles transversales, rappelées dans chaque prompt mais valables sur TOUTES les tâches sans exception :**
> - Code modulaire, un fichier = une responsabilité. Aucun "god file".
> - Séparation stricte des couches : `presentation/` ne contient jamais de logique métier ni d'appel réseau direct ; `data/` ne contient jamais de widget.
> - Nommage explicite (voir `CONVENTIONS.md`) — aucune abréviation ambiguë (`bkm`, `svc`, `tmp` proscrits).
> - Chaque classe et fonction publique documentée par un commentaire `///` expliquant son rôle, pas seulement sa signature.
> - Aucune ambiguïté n'est tranchée silencieusement — elle est documentée dans `DECISIONS.md` selon le format standard.
> - **Aucun commit n'est fait avant validation explicite** ("commit" dit clairement par l'utilisateur).
> - À la fin de la tâche (une fois le commit autorisé) : mettre à jour `TODO.md` (cocher les cases), `DECISIONS.md` (si un choix ou un bug a été traité) et `BUGS_AND_ROADMAP.md` (si pertinent).