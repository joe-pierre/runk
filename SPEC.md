# SPEC.md — Spécifications fonctionnelles et techniques

## 1. Vue d'ensemble

**Runk** (du wolof "garder / archiver") est une application mobile permettant de centraliser des vidéos trouvées sur différents réseaux sociaux (YouTube, Instagram, TikTok, Facebook, X/Twitter, Threads).

Problème résolu : aujourd'hui, quand un utilisateur tombe sur une vidéo intéressante, il n'a aucun endroit unique pour la retrouver — les vidéos sauvegardées sont dispersées entre plusieurs apps, et l'utilisateur oublie souvent sur quelle plateforme il avait trouvé telle ou telle vidéo.

Fonctionnement cible :
1. L'utilisateur trouve une vidéo sur une app tierce (Instagram, TikTok, etc.)
2. Il la partage vers Runk via le menu de partage natif du téléphone **— ou** copie simplement le lien puis ouvre Runk
3. Runk récupère automatiquement la miniature et le titre de la vidéo
4. L'utilisateur peut ajouter un nom personnalisé et des tags
5. La vidéo est stockée dans Runk (uniquement l'URL et les métadonnées, jamais le fichier vidéo)
6. Plus tard, l'utilisateur retrouve la vidéo dans Runk (par tag, recherche, ou liste chronologique) et tape sur la vignette pour l'ouvrir directement dans l'app source

**Deux voies d'entrée équivalentes pour ajouter une vidéo :**
- **Share Intent** — partage explicite via le menu natif du téléphone
- **Détection de clipboard** — au retour au premier plan de l'app, Runk vérifie si le presse-papier contient un lien vidéo non déjà proposé, et affiche une bannière discrète de suggestion (jamais de sauvegarde automatique, voir section 4 règle 7)

## 2. Stack technique

| Composant | Choix | Justification |
|---|---|---|
| Framework mobile | Flutter | Confort développeur (pas React/RN), un seul codebase iOS+Android |
| State management | Riverpod (`flutter_riverpod` + `riverpod_annotation`) | Testable, pas de BuildContext requis, génération de code |
| Navigation | `go_router` | Standard Flutter moderne, gestion des deep links |
| Base locale | Isar, via `isar_community`/`isar_community_generator` | Offline-first, rapide, NoSQL adapté au modèle simple de bookmark. Le package original `isar`/`isar_generator` est abandonné depuis Isar v3 et bloquait la mise à jour de Riverpod (voir DECISIONS.md, entrées "Riverpod 2.x" et "Migration isar_community") ; `isar_community` en est le fork communautaire activement maintenu, API identique. |
| Backend | Supabase (Auth + Postgres + Storage) | SDK Flutter officiel maintenu, RLS natif, pas de backend custom à héberger |
| Réception de partage | `receive_sharing_intent` | Gère Android Intent + iOS Share Extension avec une API unifiée |
| Récupération de métadonnées | `http` + parsing manuel des balises `og:` + endpoints oEmbed officiels | Pas de solution tout-en-un fiable pour toutes les plateformes ciblées |
| Ouverture de lien externe | `url_launcher` | Standard pour deep links + fallback navigateur |
| Détection de connectivité | `connectivity_plus` | Déclenche une tentative de resynchronisation à la reconnexion réseau (voir section 13 et DECISIONS.md Tâche 9) — signale une interface réseau active, jamais une garantie d'accès Internet ni de session Supabase joignable ; le succès réel reste jugé par l'appel Supabase lui-même |

## 3. Modèle de données

### 3.1 Modèle applicatif (Dart)

```dart
enum VideoSource { youtube, tiktok, instagram, facebook, twitter, threads, unknown }

class VideoBookmark {
  final String id;              // UUID généré côté client
  final String url;              // URL originale partagée
  final String title;            // titre auto ou saisi par l'utilisateur
  final String? thumbnailUrl;    // image de prévisualisation
  final VideoSource source;      // plateforme détectée
  final bool isPartial;          // true si les métadonnées n'ont pas pu être récupérées entièrement
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? note;            // note libre optionnelle
}
```

### 3.2 Schéma Supabase (Postgres)

```sql
create table bookmarks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  url text not null,
  title text,
  thumbnail_url text,
  source text,
  tags text[] default '{}',
  note text,
  is_partial boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table bookmarks enable row level security;

create policy "Users can only access their own bookmarks"
on bookmarks for all
using (auth.uid() = user_id);

create index on bookmarks using gin(tags);
create index on bookmarks (user_id, created_at desc);
```

### 3.3 Modèle local (Isar)

Miroir du modèle applicatif, avec un champ additionnel de synchronisation :

```dart
@collection
class BookmarkEntity {
  Id isarId = Isar.autoIncrement;
  late String remoteId;      // correspond à bookmarks.id côté Supabase
  String? userId;            // correspond à bookmarks.user_id — nullable tant
                              // qu'aucune authentification n'existe (Phase 6),
                              // rempli rétroactivement une fois l'utilisateur
                              // authentifié (voir DECISIONS.md, Tâche 5)
  late String url;
  String? title;
  String? thumbnailUrl;
  late String source;
  bool isPartial = false;
  List<String> tags = [];
  String? note;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool isSynced = false;     // false = en attente de sync vers Supabase
  bool isDeletedLocally = false; // suppression en attente de propagation
}
```

## 4. Règles métier critiques

1. **Aucun fichier vidéo n'est jamais stocké** — Runk ne stocke que l'URL et les métadonnées (titre, miniature, tags). Le contenu reste hébergé sur la plateforme d'origine.
2. **Offline-first** — toute action (ajout, tag, suppression) doit fonctionner sans connexion réseau. La synchronisation vers Supabase se fait dès que la connexion revient.
3. **Dégradation propre des métadonnées** — si la récupération automatique du titre/miniature échoue (cas fréquent pour Facebook/Threads), le bookmark est **quand même créé**, marqué `is_partial = true`, avec un titre par défaut modifiable manuellement. On ne bloque jamais l'utilisateur.
4. **Détection de plateforme par le domaine de l'URL**, jamais par un choix manuel de l'utilisateur (sauf cas `unknown`).
5. **Un seul appui suffit pour rouvrir la vidéo** — priorité au deep link natif vers l'app source ; fallback automatique et silencieux vers le navigateur si le schéma natif échoue ou si l'app n'est pas installée.
6. **Confidentialité** — chaque utilisateur ne voit et ne modifie que ses propres bookmarks (appliqué via RLS Supabase, jamais uniquement côté client).
7. **Détection de clipboard non intrusive** — la lecture du presse-papier se fait uniquement au retour de l'app au premier plan (jamais en tâche de fond), ne déclenche **jamais** de sauvegarde automatique (confirmation utilisateur obligatoire via une bannière de suggestion), et ne propose jamais deux fois le même lien déjà accepté ou ignoré.

## 5. Architecture code

```
lib/
├── main.dart
├── app/
│   ├── router.dart
│   ├── app_shell.dart                               # bottom nav 3 onglets, voir section 11
│   └── app_drawer.dart                              # sidebar auth, voir DECISIONS.md Tâche 28
├── features/
│   ├── bookmarks/
│   │   ├── data/
│   │   │   ├── bookmark_repository.dart
│   │   │   ├── bookmark_local_datasource.dart      # Isar
│   │   │   ├── bookmark_remote_datasource.dart     # Supabase
│   │   │   └── sync_service.dart                   # voir DECISIONS.md Tâche 9 : ici plutôt
│   │   │                                            # que core/services/, pour ne pas faire
│   │   │                                            # dépendre core/ de BookmarkRepository
│   │   ├── domain/
│   │   │   └── video_bookmark.dart
│   │   └── presentation/
│   │       ├── home_screen.dart
│   │       ├── add_bookmark_sheet.dart
│   │       └── bookmark_card.dart
│   ├── tags/
│   │   └── presentation/tags_screen.dart
│   ├── search/
│   │   └── presentation/search_screen.dart
│   └── auth/                                        # Tâche 28, voir DECISIONS.md
│       ├── data/
│       │   ├── auth_repository.dart                # point d'entrée unique vers
│       │   │                                        # SupabaseService.client.auth
│       │   └── auth_repository_provider.dart
│       ├── domain/
│       │   └── auth_failure.dart                   # exception métier dédiée, voir
│       │                                            # DECISIONS.md Tâche 28
│       └── presentation/
│           ├── auth_form.dart
│           └── link_local_bookmarks_prompt.dart
└── core/
    ├── services/
    │   ├── share_intent_service.dart
    │   ├── clipboard_service.dart
    │   ├── deep_link_service.dart
    │   ├── supabase_service.dart
    │   ├── app_scaffold_key_provider.dart           # voir DECISIONS.md Tâche 28 : ici plutôt
    │   │                                             # que app/, pour ne pas faire dépendre
    │   │                                             # les features/ de app/
    │   └── metadata/
    │       ├── metadata_service.dart
    │       ├── providers/
    │       │   ├── metadata_provider.dart          # interface
    │       │   ├── youtube_provider.dart
    │       │   ├── tiktok_provider.dart
    │       │   ├── twitter_provider.dart
    │       │   ├── instagram_provider.dart
    │       │   ├── facebook_provider.dart
    │       │   └── threads_provider.dart
    │       └── generic_fallback_provider.dart
    └── utils/
        └── source_detector.dart
```

**Règle non négociable :** aucun fichier ne doit dépasser une responsabilité unique. `metadata_service.dart` orchestre, il ne contient aucune logique de scraping spécifique à une plateforme — celle-ci vit exclusivement dans son propre `*_provider.dart`.

## 6. Événements WebSocket / temps réel

Aucun besoin de temps réel critique en V1 (Runk n'est pas collaboratif). Optionnel pour une V2 : utiliser **Supabase Realtime** sur la table `bookmarks` pour synchroniser instantanément entre plusieurs appareils du même utilisateur (ex: ajout sur mobile, apparition immédiate sur une future version web/tablette). Non implémenté en V1 — la synchronisation V1 se fait par polling/sync explicite (voir section 13).

## 7. Endpoints / API

Aucun backend custom : toutes les opérations passent par le SDK Supabase (PostgREST généré automatiquement + Auth).

| Opération | Méthode SDK Supabase | Table |
|---|---|---|
| Créer un bookmark | `supabase.from('bookmarks').insert(...)` | bookmarks |
| Lister les bookmarks | `supabase.from('bookmarks').select().order('created_at', ascending: false)` | bookmarks |
| Modifier (tags, titre, note) | `supabase.from('bookmarks').update(...).eq('id', id)` | bookmarks |
| Supprimer | `supabase.from('bookmarks').delete().eq('id', id)` | bookmarks |
| Recherche par tag | `supabase.from('bookmarks').select().contains('tags', [tag])` | bookmarks |
| Auth (inscription/connexion) | `supabase.auth.signUp / signInWithPassword` | auth.users (géré par Supabase) |

## 8. Extensibilité

Le point d'extension principal du projet est l'ajout d'une nouvelle plateforme vidéo. Pour ajouter une plateforme :

1. Ajouter la valeur dans `enum VideoSource`
2. Ajouter la détection de domaine dans `source_detector.dart`
3. Créer `core/services/metadata/providers/<plateforme>_provider.dart` implémentant `MetadataProvider`
4. Enregistrer le provider dans la liste de `metadata_service.dart`
5. Ajouter le schéma de deep link (si connu) dans `deep_link_service.dart`
6. Ajouter l'icône correspondante dans `assets/icons/`

Aucune autre partie du code ne doit être modifiée pour ajouter une plateforme — c'est le test de validité de l'architecture en providers.

## 9. Sécurité et validations

- **RLS Supabase activé sur toutes les tables** — jamais de filtrage de sécurité uniquement côté client.
- **Validation d'URL** avant tout traitement : schéma `http`/`https` obligatoire, rejet silencieux sinon (voir `ShareIntentService._isValidUrl`).
- **Aucune clé secrète en dur dans le code** — uniquement `anon key` publique côté client, jamais de clé `service_role`.
- **Scraping de métadonnées** : requêtes HTTP avec timeout court (5s max) pour éviter de bloquer l'UI si une plateforme tierce répond lentement ou plus du tout.
- **Pas de stockage de contenu tiers** : seules les URLs de miniatures externes sont référencées (pas de re-upload), ce qui limite l'exposition légale liée au droit d'auteur.
- **Lecture du clipboard respectueuse de la vie privée** : sur iOS 16+, utiliser l'API `detectPatterns` (vérifie la présence d'une URL sans lire ni exposer le contenu réel, évite la bannière système "Runk a collé depuis..."). Sur iOS < 16, la bannière système native est inévitable — limitation de la plateforme, pas un choix de conception à corriger côté app. Sur Android, la lecture reste silencieuse mais doit être strictement limitée au retour au premier plan (`AppLifecycleState.resumed`), jamais en arrière-plan.

## 10. Identité visuelle

- **Nom** : Runk
- **Domaine** : runkapp.com
- **Thème par défaut** : suit le thème du système d'exploitation (`ThemeMode.system`) tant que l'utilisateur n'a jamais choisi explicitement un mode dans l'app — révision de l'ancien "sombre par défaut" en Tâche 29 (voir `DECISIONS.md`), pour respecter la contrainte "le mode système doit suivre le thème OS à la première ouverture". Bascule manuelle clair/sombre/système disponible dans la sidebar (`ThemeModeSelector`), persistée via `SharedPreferences`, sans redémarrage de l'app.
- `useMaterial3: true` conservé. `ColorScheme` construit explicitement (`ColorScheme.light`/`.dark`, jamais `.fromSeed`) — voir `lib/core/theme/app_theme.dart`.

### Palette (Tâche 29, figée avec l'utilisateur)

**Mode sombre**

| Rôle | Valeur |
|---|---|
| `background` (fond d'écran) | `#1B1512` |
| `surface` (fond de carte) | `#241C17` |
| `border` (bordure de carte) | `#362A20` |
| `textPrimary` | `#FBF3E7` |
| `textMuted` (icônes secondaires) | `#A08D74` |
| `textMutedInactive` (icônes de nav inactives) | `#6B5D4D` |
| `accent` | `#D85A30` |
| `tagBackground` | `#3D2A18` |
| `tagText` | `#FAC775` |
| `badgeOverlay` (badge plateforme sur miniature) | `rgba(20,12,8,0.5)` |
| `badgeText` | `#FDEEE7` |

**Mode clair**

| Rôle | Valeur |
|---|---|
| `background` | `#FAF2E4` |
| `surface` | `#FFFFFF` |
| `border` | `#E7D9C2` |
| `textPrimary` | `#2B2015` |
| `textMuted` | `#9C8B72` |
| `textMutedInactive` | `#B3A488` |
| `accent` | `#D85A30` (identique au sombre) |
| `tagBackground` | `#F1E1C4` |
| `tagText` | `#7A5518` |
| `badgeOverlay` | `rgba(20,12,8,0.5)` (identique) |
| `badgeText` | `#FDEEE7` (identique) |

**Palette de miniatures placeholder** (3 couleurs cycliques, identiques dans les deux modes) : `#D85A30`, `#B84C6F`, `#3C7A63` — assignation déterministe par bookmark (`thumbnailPalette[bookmark.id.hashCode.abs() % thumbnailPalette.length]`), jamais aléatoire ni liée à la plateforme. S'applique uniquement au placeholder (`_BookmarkThumbnail`, cas `isPartial`/URL absente/erreur de chargement), jamais à une vraie miniature réseau.

**Implémentation** : `lib/core/theme/app_palette.dart` (constantes brutes), `app_color_tokens.dart` (`AppColorTokens extends ThemeExtension`, rôles hors `ColorScheme` standard : `cardBorder`, `tagBackground`, `tagText`, `badgeOverlay`, `badgeText`, `thumbnailPalette`), `app_theme.dart` (`AppTheme.light`/`.dark`). Voir `DECISIONS.md`, entrées "Tâche 29", pour le détail des choix de mapping (`textMuted`→`onSurfaceVariant`, `textMutedInactive`→`outline`, etc.).

Icônes de plateforme : SVG dédiés (`assets/icons/x.svg`, `instagram.svg`, `facebook.svg`, `threads.svg`) câblés dans `BookmarkCard` depuis la Tâche 29, teintés selon le thème actif. YouTube/TikTok n'ont pas d'icône SVG dédiée : icônes Material génériques conservées, teintées à l'identique.

## 11. Écrans

| Écran | Rôle |
|---|---|
| **Home** | Liste chronologique de tous les bookmarks, tri par date. Depuis la Tâche 30 (voir `DECISIONS.md`), porte aussi la recherche full-text (titre + tags) via une barre flottante en haut de l'écran — absorbe le rôle de l'ancien écran Search, supprimé |
| **Clipboard Suggestion Banner** | Bannière discrète et non bloquante affichée en haut de `HomeScreen` au retour au premier plan si un lien vidéo valide et nouveau est détecté dans le presse-papier ; deux actions : "Ajouter" (ouvre `AddBookmarkSheet`) ou "Ignorer" (le lien n'est plus reproposé) |
| **Add Bookmark Sheet** | Modale déclenchée par le Share Intent, la Clipboard Suggestion Banner, ou un bouton "+", pré-remplie avec metadata, permet titre custom + tags |
| **Tags** | Navigation par catégorie/tag |

Navigation : `Bottom Navigation Bar` à 2 onglets (Home / Tags, réduite de 3 à 2 en Tâche 30 — voir `DECISIONS.md`), la modale d'ajout se superpose par-dessus n'importe quel écran.

**Recherche intégrée à `HomeScreen` (Tâche 30, écart assumé par rapport à la version initiale de cette section) :** barre de recherche placée dans le `bottom:` d'un `SliverAppBar(floating: true, snap: true)`, qui se masque/réapparaît avec le titre "Runk" au scroll (comportement natif Flutter, sans logique de détection de direction custom). Requête vide → liste normale (`bookmarkListProvider`, filtrée par `bookmarkTagFilterProvider` si actif) ; requête non vide → bascule sur `bookmarkSearchProvider` (recherche purement locale, aucun appel réseau), le chip de filtre par tag est alors masqué — les deux filtres ne se combinent jamais. `SearchScreen` et l'onglet Recherche sont supprimés, leur fonction est entièrement absorbée par cette barre.

## 12. Tâches

Voir `TODO.md` pour le détail des phases et `TASK_PROMPTS.md` pour les instructions détaillées données à Claude Code sur chaque tâche.

## 13. Race conditions

| Scénario | Risque | Mitigation |
|---|---|---|
| Partage multiple rapide (plusieurs vidéos partagées coup sur coup) | Deux modales d'ajout qui se superposent, ou perte d'un des liens | File d'attente (`Queue<String>`) dans `ShareIntentService` — une modale à la fois, la suivante s'ouvre à la fermeture de la précédente |
| Modification d'un bookmark sur deux appareils hors ligne, puis reconnexion simultanée | Conflit d'écriture sur Supabase | Politique **last-write-wins** basée sur `updated_at` (comportement par défaut du update Supabase) — accepté comme limitation V1, pas de merge intelligent |
| Suppression locale pendant que la sync est en cours vers Supabase | Le bookmark supprimé pourrait réapparaître après sync | Le flag `isDeletedLocally` est vérifié en priorité par `sync_service.dart` avant tout envoi vers Supabase ; la suppression distante est confirmée avant suppression définitive locale |
| Échec réseau en plein scraping de métadonnées | Bookmark bloqué en attente indéfiniment | Timeout de 5s (voir section 9) + fallback automatique vers `is_partial = true`, jamais de blocage de l'UI |
| Retour au premier plan alors qu'un Share Intent est aussi en cours de traitement | La bannière clipboard et la modale d'ajout du Share Intent pourraient s'afficher simultanément | Le `ClipboardService` vérifie l'état de la file d'attente du `ShareIntentService` avant d'afficher sa bannière ; priorité systématique au Share Intent (action explicite de l'utilisateur) sur la suggestion clipboard (action passive) |
