# TODO

## Phase 1 — Setup du projet ✅

- [x] Création du projet Flutter (`flutter create runk`)
- [x] Ajout des dépendances (`go_router`, `flutter_riverpod`, `isar`, `supabase_flutter`, `receive_sharing_intent`, `any_link_preview`, `http`, `url_launcher`, `uuid`, `intl`)
- [x] Création du projet Supabase + exécution du schéma SQL (table `bookmarks` + RLS)
- [x] Configuration de `Env` (variables Supabase via `--dart-define`)
- [x] Initialisation de Supabase dans `main.dart`
- [x] Dépendances Isar maintenues via `isar_community`/`isar_community_generator` (fork actif), permettant de remonter `flutter_riverpod`/`riverpod_annotation`/`riverpod_generator` en 3.x (voir `DECISIONS.md`, entrée "Migration vers isar_community")

## Phase 2 — Share Intent

- [x] Configuration Android : intent-filters `SEND` / `SEND_MULTIPLE` dans `AndroidManifest.xml`
- [ ] Configuration iOS : création du target `RunkShareExtension` + App Group `group.com.senluxtech.runk`
- [x] Implémentation de `ShareIntentService` (écoute + récupération du lien initial au démarrage)
- [x] Validation d'URL (`_isValidUrl`) avant tout traitement
- [x] Tâche 16 — Extraction d'URL depuis un texte de partage libre (`ShareIntentService._extractBestUrl`) : corrige le rejet silencieux d'un partage TikTok Lite (texte libre + lien promotionnel non pertinent), priorité à l'URL dont `SourceDetector.detect` reconnaît une plateforme, sans régression sur le cas d'URL nue (voir `DECISIONS.md`, entrée "Tâche 16")
- [ ] Branchement dans `main.dart` / widget racine : ouverture automatique de la modale d'ajout
- [ ] Gestion de la file d'attente si plusieurs partages arrivent rapidement (voir `SPEC.md` section 13)
- [ ] Test manuel sur appareil physique Android ET iOS (voir `guide.md` section 5.3)

## Phase 3 — Metadata Service (YouTube + TikTok d'abord)

- [x] Création de l'interface `MetadataProvider`
- [x] `SourceDetector` (détection de plateforme par domaine)
- [x] `YoutubeProvider` (oEmbed officiel)
- [x] `TiktokProvider` (oEmbed officiel)
- [x] `GenericFallbackProvider` (titre par défaut + `is_partial = true`)
- [x] `MetadataService` (orchestrateur, sélection du provider adapté)
- [x] Tests unitaires sur chaque provider

## Phase 3.5 — CI et test d'intégration du flux interne

- [x] Workflow GitHub Actions : `flutter analyze` + `flutter test` déclenchés sur chaque pull request (`.github/workflows/ci.yml`)
- [x] Configuration du cache des dépendances Flutter pour accélérer la CI (`subosito/flutter-action`, `cache: true`)
- [x] Mise en place du dossier `integration_test/`
- [x] Test d'intégration du flux interne : URL déjà validée → ouverture modale → sauvegarde → apparition dans `HomeScreen` (sans dépendance à une app tierce réelle) — `integration_test/app_flow_test.dart`
- [x] Documentation dans `guide.md` de la commande pour lancer ce test en local (`flutter test integration_test`)
- [x] `flutter test` complet débloqué (voir `DECISIONS.md`, entrée Tâche 10 — blocage `testWidgets`/Isar) — reste deux échecs préexistants sans rapport, non corrigés dans cette tâche, marqués `skip` (pas supprimés) pour que la CI soit fiable sans masquer le problème (voir `DECISIONS.md` et `BUGS_AND_ROADMAP.md`, section Points de vigilance, entrée Tâche 10) : `tags_screen_test.dart` (filtre par tag) et `sync_service_test.dart` (minuteur périodique)
- [x] `flutter test` (suite complète) confirmé vert : `91 passed, 2 skipped` en ~97 s, aucun blocage

## Phase 4 — UI de base

- [x] `AddBookmarkSheet` (modale d'ajout : thumbnail, titre éditable, tags, bouton sauvegarder)
- [x] `HomeScreen` (liste chronologique des bookmarks)
- [x] `BookmarkCard` (composant réutilisable d'affichage d'un bookmark)
- [x] `BookmarkRepository` + `BookmarkLocalDatasource` (Isar) + `BookmarkRemoteDatasource` (Supabase)
- [x] Branchement Riverpod : ouverture réelle d'Isar + `ProviderScope` dans `main.dart` (jusqu'ici seulement fait en test, voir DECISIONS.md Tâche 6)
- [x] Branchement du Share Intent au widget racine (`ShareIntentGate`) + file d'attente pour partages multiples rapides (SPEC.md section 13)
- [x] Tâche 20 — Bouton flottant "+" (`HomeScreen`), troisième voie d'entrée déjà prévue par SPEC.md section 11 : nouveau `ManualAddDialog` (`lib/features/bookmarks/presentation/manual_add_dialog.dart`), popup légère qui capte une URL tapée/collée, la valide en réutilisant `UrlTextExtractor.extractBestUrl` (utilitaire déjà factorisé Tâche 18, aucune nouvelle logique de validation), affiche une erreur inline si invalide, puis délègue à `AddBookmarkSheet.show` telle quelle — aucune duplication de la récupération de métadonnées (voir `DECISIONS.md`, entrée "Tâche 20")
- [x] Tâche 21 — Menu contextuel par appui long sur `BookmarkCard` (`HomeScreen`) : nouveau `bookmark_context_menu.dart` (`lib/features/bookmarks/presentation/`), porte toute la logique de mutation (`BookmarkRepository.updateBookmark`/`deleteBookmark` + `bookmarkListProvider.refresh()`) — `BookmarkCard` reste `StatelessWidget` purement présentationnel, `onLongPress` optionnel branché par `HomeScreen` sur le même principe que `onTap`/`openBookmark` (voir `DECISIONS.md`, entrée "Tâche 21"). "Modifier les tags" réutilise `TagInputField` tel quel dans un `AlertDialog` dédié ; "Supprimer" demande confirmation avant suppression définitive. Nouveau `VideoBookmark.copyWith` pour transmettre les nouveaux tags sans altérer les autres champs
- [ ] Flux complet de bout en bout testé **sur appareil physique** : partage → metadata → sauvegarde → affichage dans Home persistant après redémarrage (vérifié en local : `flutter analyze`/`flutter test`/`flutter build apk --debug` OK, run sur `linux` desktop sans crash — reste à valider sur device réel, voir `BUGS_AND_ROADMAP.md`)

## Phase 4.5 — Détection de lien vidéo via clipboard

- [x] `ClipboardService` (détection au retour au premier plan uniquement, jamais en tâche de fond)
- [x] Mémorisation des liens clipboard déjà proposés/ignorés (pour ne jamais les reproposer) — `ClipboardHistoryStore` via `SharedPreferences`
- [x] `ClipboardSuggestionBanner` (UI de suggestion non bloquante sur `HomeScreen`)
- [x] Vérification de priorité Share Intent > suggestion clipboard en cas de simultanéité (voir `SPEC.md` section 13) — `shareIntentProcessingProvider`, alimenté par `ShareIntentGate`
- [x] Tâche 18 — Extraction d'URL depuis un texte de presse-papier (`ClipboardService._checkClipboard`) : corrige le même bug que la Tâche 16 (TikTok Lite copie un texte libre entourant le lien réel), désormais aussi rencontré côté clipboard ; logique d'extraction factorisée dans un nouvel utilitaire partagé `UrlTextExtractor` (`lib/core/utils/url_text_extractor.dart`), réutilisé par `ShareIntentService` (Tâche 16, comportement observable inchangé) et `ClipboardService`, sans nouvelle dépendance (voir `DECISIONS.md`, entrée "Tâche 18")
- [x] Tâche 19 — Renforcement visuel de `ClipboardSuggestionBanner` : couleur d'accent `colorScheme.primaryContainer` (à la place du fond neutre par défaut), apparition en glissement + fondu (`AnimatedSwitcher`, 300 ms) plutôt qu'instantanée, retour haptique `HapticFeedback.lightImpact()` déclenché une seule fois par nouvelle suggestion (`ref.listen`, jamais sur un simple rebuild) — texte, actions "Ajouter"/"Ignorer" et leur comportement strictement inchangés ; nouveau test widget dédié `clipboard_suggestion_banner_test.dart` (4 cas) ; **validé sur un appareil Android physique réel** exceptionnellement disponible durant cette session (voir `DECISIONS.md`, entrée "Tâche 19 — Renforcement visuel...")
- [ ] Test manuel sur appareil physique iOS 16+ ET iOS < 16 (voir `guide.md` section 5.4) — non réalisable dans cet environnement de développement (pas de matériel iOS), reste à faire par l'utilisateur. `detectPatterns` non implémenté (voir `DECISIONS.md`, entrée "Tâche 6.5") : la bannière système iOS est attendue sur toutes les versions.

## Phase 5 — Extension aux plateformes restantes

- [x] `TwitterProvider` (oEmbed officiel `publish.twitter.com` — titre basé sur `author_name`) — Tâche 17 : miniature best-effort ajoutée via scraping `og:image` complémentaire (`OgTagScraper`, timeout dédié 2s), échec silencieux inchangé (`thumbnailUrl: null`, `isPartial: false`), voir `DECISIONS.md` Tâche 17 (remplace le choix initial de la Tâche 7)
- [x] `InstagramProvider` (scraping `og:` tags via `OgTagScraper` partagé, fallback interne vers `isPartial: true`, aucune exception ne remonte)
- [x] `FacebookProvider` (idem Instagram — `is_partial` fréquent et attendu, pas un bug)
- [x] `ThreadsProvider` (idem Instagram/Facebook — `is_partial` fréquent et attendu, pas un bug)
- [x] Providers enregistrés dans `metadata_service.dart` (seule modification apportée à ce fichier) — `source_detector.dart` déjà à jour depuis la Tâche 4, aucune modification nécessaire (voir `DECISIONS.md`)
- [x] Tests unitaires par provider (mock HTTP) + tests de l'utilitaire partagé `OgTagScraper`
- [x] `DeepLinkService` : schémas natifs pour chaque plateforme + fallback navigateur systématique (Tâche 8) — Threads exclu volontairement, aucun schéma connu (voir `DECISIONS.md`)
- [x] Icônes de plateforme ajoutées dans `assets/icons/` (`x.svg`, `instagram.svg`, `facebook.svg`, `threads.svg`) + déclarées dans `pubspec.yaml` — non câblées dans `bookmark_card.dart` (fichier hors périmètre de cette tâche, voir `DECISIONS.md`)
- [x] Tâche 11 — Décodage des entités HTML (`&quot;`, `&#x2014;`, entités numériques hors ASCII) dans `OgTagScraper`, via `html_unescape`, corrigeant les titres illisibles remontés par Instagram/Facebook/Threads (voir `DECISIONS.md` et `BUGS_AND_ROADMAP.md`)
- [ ] Test manuel sur appareil physique : partager un lien de chacune des 6 plateformes produit un bookmark valide, avec `isPartial` correctement positionné — non réalisable dans cet environnement de développement (pas d'appareil Android/iOS physique ni d'émulateur, même limitation que les tâches précédentes, voir `BUGS_AND_ROADMAP.md`), reste à faire par l'utilisateur
- [ ] Test manuel sur appareil physique : taper une vignette Instagram/TikTok/Facebook/X ouvre l'app correspondante si installée, sinon le navigateur ; Threads ouvre toujours le navigateur (aucun schéma natif connu, voir `DECISIONS.md` Tâche 8) — non réalisable dans cet environnement de développement, reste à faire par l'utilisateur
- [x] Tâche 12 — Cache disque local des miniatures (`cached_network_image`), `_MetadataPreview` (`add_bookmark_sheet.dart`) et `_BookmarkThumbnail` (`bookmark_card.dart`) : la miniature reste affichée après redémarrage même si l'URL CDN signée d'origine (Instagram/Facebook) a expiré (voir `DECISIONS.md` et `BUGS_AND_ROADMAP.md`) — reste à valider manuellement sur appareil physique (redémarrage réel après plusieurs heures)
- [x] Tâche 13 — Autocomplétion des tags dans `AddBookmarkSheet` : nouveau widget `TagInputField` (`lib/features/bookmarks/presentation/tag_input_field.dart`), suggestions issues de `distinctTagsProvider` filtrées par préfixe insensible à la casse, affichées sous le champ ; tap sur une suggestion l'ajoute sans doublon (comparaison insensible à la casse) et vide le champ (voir `DECISIONS.md`, entrée "Tâche 13")
- [x] Tâche 14 — Boutons de confirmation explicites : libellé du bouton principal d'`AddBookmarkSheet` harmonisé sur "Ajouter" (cohérent avec `clipboard_suggestion_banner.dart`) ; `TagInputField` dispose désormais d'un bouton "+" (`IconButton.filled`) à côté du champ pour valider un tag tapé manuellement, en plus de la soumission clavier — état local uniquement, persistance toujours déclenchée à la sauvegarde du bookmark (voir `DECISIONS.md`, entrée "Tâche 14")

## Phase 6 — Fonctionnalités secondaires

- [ ] `TagsScreen` (navigation par tag)
- [ ] `SearchScreen` (recherche full-text titre + tags)
- [ ] `SyncService` (synchronisation offline-first Isar ↔ Supabase, gestion `isSynced` / `isDeletedLocally`, exploite `BookmarkRemoteSyncException` pour différencier un vrai échec de sync d'une absence de session — voir DECISIONS.md Tâche 5)
- [ ] Authentification utilisateur (Supabase Auth — email/password ou magic link) — doit aussi renseigner rétroactivement `BookmarkEntity.userId` sur les bookmarks déjà créés hors ligne (voir DECISIONS.md Tâche 5)
- [x] Tâche 15 — Gestion indépendante des tags : collection Isar `TagEntity` (nom unique insensible à la casse), `TagRepository` (`lib/features/tags/data/`, créer/renommer/supprimer avec propagation en cascade vers `BookmarkEntity.tags` dans une transaction Isar unique), `TagsScreen` étendu (bouton d'ajout, menu contextuel renommer/supprimer avec confirmation affichant le nombre de bookmarks impactés), `distinctTagsProvider` fusionnant tags gérés et tags dérivés des bookmarks (voir `DECISIONS.md`, entrée "Tâche 15") — validation visuelle sur appareil physique restant à faire par l'utilisateur (voir `BUGS_AND_ROADMAP.md`)
- [x] Tâche 22 — Section "My Eyes Only" (bookmarks masqués protégés par code) : `VideoBookmark.isHidden`/`BookmarkEntity.isHidden` (synchronisé avec Supabase, colonne `bookmarks.is_hidden`, voir `guide.md` section 3.2/3.2 bis), `MyEyesOnlyService` (`lib/core/services/`, hash SHA-256 via `package:crypto`, jamais le code en clair, strictement local via `shared_preferences`), action "Masquer"/"Ne plus masquer" dans `bookmark_context_menu.dart`, flux d'accès complet (`my_eyes_only_access.dart` : création/saisie du code, "Code oublié ?" avec démasquage groupé `BookmarkRepository.unhideAllBookmarks` puis nouveau code) ouvrant `MyEyesOnlyScreen` (réutilise `BookmarkCard`/`showBookmarkContextMenu` tel quel, filtré sur `isHidden == true`, dérivé de `bookmarkListProvider`), appui long sur le titre "Runk" de `HomeScreen` comme point d'entrée discret (voir `DECISIONS.md`, entrées "Tâche 22") — flux complet validé manuellement sur l'appareil Android physique exceptionnellement disponible durant cette session (voir `BUGS_AND_ROADMAP.md`)
- [x] Tâche 23 — Exclusion des bookmarks "My Eyes Only" des résultats de recherche : `BookmarkLocalDatasource.searchByTitleOrTags` exclut désormais systématiquement les entités `isHidden: true` (même filtre que `isDeletedLocally`, non paramétrable depuis `presentation/`), voir `DECISIONS.md` entrée "Tâche 23" — fuite potentielle distincte identifiée et documentée (non corrigée, hors périmètre) : `distinctTagsProvider` peut révéler l'existence d'un tag porté uniquement par des bookmarks masqués (voir `DECISIONS.md`/`BUGS_AND_ROADMAP.md`)
- [x] Tâche 24 — Retrait de "Masquer"/"Ne plus masquer" du menu contextuel partagé (`bookmark_context_menu.dart`, ajustement explicite de la Tâche 22, pas une correction de bug), qui ne propose plus que "Modifier les tags"/"Supprimer" dans aucun état de l'app ; nouvelle action locale dédiée `HiddenBookmarkMenuButton` (`hidden_bookmark_menu_button.dart`, importée uniquement par `my_eyes_only_screen.dart`) pour "Ne plus masquer"/"Supprimer" depuis `MyEyesOnlyScreen` ; nouvel écran `AddToMyEyesOnlyScreen` (sélection multiple par cases à cocher, "Masquer la sélection"), accessible via un second `FloatingActionButton` sur `MyEyesOnlyScreen`, ouvert par `Navigator.push` comme `MyEyesOnlyScreen` lui-même — aucun nouvel état de session "déverrouillé" (voir `DECISIONS.md`, entrées "Tâche 24")
- [x] Tâche 25 — Masquage d'un tag en cascade sur tous ses bookmarks (existants et futurs) : `TagEntity.isHidden` (`lib/features/tags/data/tag_local_datasource.dart`), `TagRepository.hideTag`/`unhideTag` (transaction Isar unique, `unhideTag` ne démasque pas un bookmark protégé par un autre tag encore masqué) ; `BookmarkRepository.createBookmark`/`updateBookmark` consultent désormais `TagEntity.isHidden` (lecture seule, via `TagLocalDatasource` injecté) pour forcer `isHidden: true` à la création comme à l'édition ("Modifier les tags", Tâche 21) ; `distinctTagsProvider` exclut les tags masqués **et** corrige au passage la fuite préexistante documentée en Tâche 23 (dérivation limitée aux bookmarks `isHidden: false`) ; UI strictement hors du menu normal (`tag_action_dialogs.dart`/`bookmark_context_menu.dart` inchangés) — nouveau mode "Tags" dans `AddToMyEyesOnlyScreen` (`HideTagListView`) et nouvelle section "Tags masqués" dans `MyEyesOnlyScreen` (`HiddenTagListTile`, `hiddenTagsProvider`) — voir `DECISIONS.md`, entrées "Tâche 25". **Limite documentée, non résolue** : impossible de distinguer un bookmark masqué individuellement d'un bookmark masqué via un tag (voir `DECISIONS.md`) — validation visuelle sur appareil physique restant à faire par l'utilisateur (voir `BUGS_AND_ROADMAP.md`)

## Phase 7 — Préparation au déploiement

- [ ] Politique de confidentialité rédigée et publiée sur `runkapp.com/privacy`
- [ ] Icône d'application + splash screen définitifs
- [ ] Projet Supabase de production créé et séparé du dev
- [ ] Signature Android (`key.properties` + keystore)
- [ ] Certificats et provisioning iOS configurés
- [ ] Checklist finale de `guide.md` section 8 validée
- [ ] Publication TestFlight (iOS) et test interne (Android) avant soumission publique
