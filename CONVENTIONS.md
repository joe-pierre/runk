# CONVENTIONS.md — Règles de codage

## Langue

- **Code** (noms de fichiers, classes, fonctions, variables) : **anglais**, standard dans l'écosystème Flutter/Dart.
- **Commentaires et documentation** (docstrings, `DECISIONS.md`, `TODO.md`, messages de commit) : **français**, langue de travail de l'équipe.
- **Textes affichés à l'utilisateur** : français en premier (marché cible initial), structure prête pour l'internationalisation (`intl`) dès que possible — ne jamais hardcoder une chaîne visible dans un widget sans passer par un fichier de traduction dès que l'app dépasse le prototype.

## Nommage

- **Fichiers** : `snake_case.dart` (ex: `bookmark_repository.dart`)
- **Classes / enums** : `PascalCase` (ex: `VideoBookmark`, `VideoSource`)
- **Variables / fonctions** : `camelCase`
- **Constantes** : `camelCase` précédé de `k` uniquement si ambiguïté possible, sinon `camelCase` simple (suivre la convention Dart officielle, pas de `SCREAMING_CASE`)
- **Un fichier = une responsabilité principale.** Si un fichier dépasse ~200 lignes ou mélange plusieurs responsabilités (ex: logique métier + UI), il doit être découpé. Aucun "god file" toléré (voir `metadata_service.dart` comme exemple de bonne pratique : orchestration seule, zéro logique de scraping).
- **Providers Riverpod** : suffixe `Provider` explicite (ex: `bookmarkListProvider`, `metadataServiceProvider`).
- **Services** : suffixe `Service` pour les classes orchestrant une logique transverse (ex: `ShareIntentService`, `DeepLinkService`).
- **Repositories** : suffixe `Repository`, point d'entrée unique entre une feature et ses sources de données (local + remote).

## Réponses API (Supabase)

- Toujours passer par le `Repository` correspondant, jamais d'appel direct à `supabase.from(...)` depuis un widget ou un provider de présentation.
- Toute réponse Supabase doit être mappée vers le modèle applicatif (`VideoBookmark`) avant d'atteindre la couche UI — jamais de `Map<String, dynamic>` brut affiché ou manipulé en dehors de la couche `data/`.
- Les erreurs réseau/API sont capturées dans le repository et remontées sous forme de résultat typé (ex: `Result<T>` ou exception métier dédiée), jamais de `try/catch` silencieux qui masque l'échec.

## Validation

- Toute URL entrante (Share Intent, saisie manuelle) passe obligatoirement par `SourceDetector` + une validation de schéma (`http`/`https`) avant tout traitement.
- Toute création de `VideoBookmark` invalide (URL vide, malformée) est rejetée avant d'atteindre Isar ou Supabase — la validation se fait au plus proche de la source de la donnée, pas en fin de chaîne.
- Les champs `title` et `note` sont "trim" (espaces superflus retirés) avant sauvegarde.

## Broadcasting / Temps réel

Non utilisé en V1 (voir `SPEC.md` section 6). Si Supabase Realtime est introduit en V2, la souscription à un canal doit être encapsulée dans un service dédié (`realtime_sync_service.dart`), jamais directement dans un widget.

## Tests

- Structure : `test/unit/` pour la logique pure (services, repositories, providers de métadonnées), `test/widget/` pour les composants UI, `integration_test/` pour le flux applicatif interne de bout en bout.
- Chaque nouveau `MetadataProvider` doit avoir un test unitaire vérifiant : (1) `canHandle()` retourne correctement vrai/faux selon l'URL, (2) le comportement de fallback en cas d'échec réseau simulé.
- Pas de couverture minimale imposée en V1, mais **tout service critique au flux principal (Share Intent → Metadata → Save) doit être testé** avant d'être considéré comme terminé dans `TODO.md`.
- **CI obligatoire dès la Tâche 2 :** chaque pull request déclenche `flutter analyze` + `flutter test` via GitHub Actions (voir `TASK_PROMPTS.md` — Tâche 11). Une PR qui échoue à l'un des deux ne doit pas être fusionnée.
- **Test d'intégration du flux interne (`integration_test/`)** : simule la réception d'une URL déjà validée (sans dépendre d'une vraie app tierce) → vérifie ouverture de la modale, sauvegarde, apparition dans `HomeScreen`. Ce test automatisé complète, sans remplacer, la checklist manuelle sur appareil physique (`guide.md` section 6.3) — le partage réel depuis Instagram/TikTok/etc. et les deep links de retour restent testés manuellement, car dépendants de comportements non documentés de plateformes tierces (voir `DECISIONS.md`).
- Pas de crash reporting (Sentry/Crashlytics) attendu avant la Phase 7 (préparation au déploiement) — inutile de l'introduire plus tôt.

## Sécurité

- Aucune clé Supabase `service_role` ne doit jamais apparaître côté client — uniquement la clé `anon`.
- RLS activé sur toute nouvelle table dès sa création, jamais ajouté "plus tard".
- Aucune donnée sensible (email, tokens) ne doit être loguée en clair, même en mode debug.

## Partials / Frontend (Flutter)

- Les widgets d'écran (`*_screen.dart`) orchestrent uniquement la composition ; toute logique de présentation réutilisable (ex: une carte de bookmark) devient un widget dédié dans le même dossier `presentation/` (ex: `bookmark_card.dart`), jamais un widget anonyme inline de 100 lignes dans le `build()` de l'écran.
- Pas de logique métier dans les widgets : un widget lit un provider et affiche un état, il ne décide jamais lui-même comment récupérer une métadonnée ou détecter une source.
- Chaque widget public réutilisé dans plusieurs écrans documente ses paramètres attendus via un commentaire doc (`///`) au-dessus de la classe.
