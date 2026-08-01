# guide.md — Installation, lancement, test et déploiement de Runk

> Runk est une application mobile Flutter qui permet de sauvegarder et catégoriser des vidéos trouvées sur YouTube, Instagram, TikTok, Facebook, X (Twitter) et Threads, avec récupération automatique de miniature/titre et réouverture directe dans l'app source.

Ce guide part du principe que tu découvres le projet pour la première fois. Chaque étape est reproductible sur une machine vierge.

---

## 1. Prérequis

| Outil | Version minimale | Usage |
|---|---|---|
| Flutter SDK | 3.22+ (Dart 3.4+) | Framework principal |
| Android Studio | dernière stable | SDK Android, émulateur, signature APK/AAB |
| Xcode | 15+ (macOS uniquement) | Build iOS, Share Extension, certificats |
| Git | toute version récente | Gestion de version |
| Compte Supabase | gratuit (tier Free suffit au démarrage) | Backend (Auth, DB, Storage) |
| Compte Google Play Console | 25$ (frais unique) | Publication Android |
| Compte Apple Developer | 99$/an | Publication iOS |
| VS Code (recommandé) + extensions Flutter/Dart | — | Éditeur |

**Note plateforme :** le build iOS (compilation, Share Extension, signature) nécessite obligatoirement une machine macOS. Le développement Android peut se faire sur Windows/Linux/macOS.

---

## 2. Installation de l'environnement de développement

### 2.1 Installer Flutter

```bash
# macOS (via Homebrew)
brew install --cask flutter

# Windows / Linux : télécharger l'archive officielle
# https://docs.flutter.dev/get-started/install
```

Vérifie l'installation :

```bash
flutter doctor
```

Résous chaque `✗` affiché (licences Android non acceptées, Xcode non configuré, etc.) avant de continuer.

### 2.2 Accepter les licences Android

```bash
flutter doctor --android-licenses
```

Accepte toutes les licences proposées (`y` à chaque question).

### 2.3 Configurer Xcode (macOS uniquement, pour iOS)

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

Ouvre Xcode une première fois manuellement pour valider l'installation des composants additionnels.

### 2.4 Installer CocoaPods (macOS, pour iOS)

```bash
sudo gem install cocoapods
```

### 2.5 Cloner le projet

```bash
git clone https://github.com/<ton-compte>/runk.git
cd runk
```

### 2.6 Installer les dépendances Flutter

```bash
flutter pub get
```

### 2.7 Générer le code (Isar, Riverpod)

Le projet utilise `build_runner` pour générer les fichiers `.g.dart` (modèles Isar, providers Riverpod annotés) :

```bash
dart run build_runner build --delete-conflicting-outputs
```

À relancer chaque fois que tu modifies un modèle Isar (`@collection`) ou un provider annoté (`@riverpod`).

---

## 3. Configuration de Supabase

### 3.1 Créer le projet

1. Va sur [supabase.com](https://supabase.com) → **New Project**
2. Choisis un nom (ex: `runk-dev`), une région proche de tes utilisateurs (Europe de l'Ouest recommandé pour le Sénégal/France)
3. Note le mot de passe de la base généré — tu en auras besoin

### 3.2 Exécuter le schéma SQL

Dans **SQL Editor** de Supabase, exécute :

```sql
create extension if not exists "uuid-ossp";

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
  is_hidden boolean not null default false,
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

### 3.2 bis Mettre à jour un projet Supabase existant

Ce projet ne gère aucune migration automatisée : toute évolution du schéma d'un projet Supabase déjà créé (dev ou prod) doit être exécutée **manuellement** dans le **SQL Editor** de Supabase, sur chaque projet concerné.

Tâche 22 (« My Eyes Only ») a ajouté la colonne `is_hidden` après la création initiale de certains projets — exécute ce script sur tout projet créé avant cette tâche :

```sql
alter table bookmarks add column is_hidden boolean not null default false;
```

### 3.3 Récupérer les clés d'API

Dans **Project Settings → API**, note :
- `Project URL`
- `anon public key`

### 3.4 Configurer les variables d'environnement dans Flutter

**Ne jamais committer les clés en dur dans le code**, et ne jamais les committer dans un fichier versionné (`.env.local` doit rester dans `.gitignore`).

Crée `lib/core/config/env.dart` :

```dart
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
```

Crée un fichier `.env.local` (ajouté à `.gitignore`) au format simple `CLE=valeur` :
```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJxxxxx...
```

Puis lance l'app avec :

```bash
flutter run --dart-define-from-file=.env.local
```

> Aucun package n'est nécessaire pour ça : `--dart-define-from-file` est une fonctionnalité native de Flutter (lecture au format `.env` supportée depuis Flutter 3.13+, très en dessous de la version utilisée sur ce projet). Les valeurs sont injectées comme constantes de compilation via `String.fromEnvironment` — pas de `flutter_dotenv` à ajouter dans `pubspec.yaml`.

**Note sur la nature de la clé `anon`** : cette clé est conçue par Supabase pour être publique et exposée côté client (d'où son nom — voir la doc officielle Supabase). Elle finit de toute façon embarquée dans le binaire compilé de l'app, quelle que soit la méthode utilisée (`--dart-define` ou un package comme `flutter_dotenv`) — un décompilateur peut l'en extraire dans les deux cas, ce n'est pas une différence de sécurité entre les deux approches. La protection réelle des données utilisateur repose sur les policies RLS (voir section 3.2), pas sur la difficulté à retrouver cette clé. Le rôle de `.gitignore` ici est différent : éviter que la clé ne fuite dans l'historique Git public (dépôt accidentellement public, scan automatisé de repos), pas d'empêcher l'utilisateur final de la retrouver dans sa propre installation de l'app.

Pour éviter de retaper la commande à chaque lancement, deux options pratiques :

**Option A — script shell :**
```bash
# scripts/run_dev.sh
#!/bin/bash
flutter run --dart-define-from-file=.env.local
```
```bash
chmod +x scripts/run_dev.sh
./scripts/run_dev.sh
```

**Option B — configuration de lancement VS Code**, dans `.vscode/launch.json` (crée le dossier `.vscode/` à la racine du projet s'il n'existe pas) :
```json
{
  "configurations": [
    {
      "name": "Runk (dev)",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "args": ["--dart-define-from-file=.env.local"]
    }
  ]
}
```
Lance ensuite via `F5` ou le bouton Run de VS Code. Si un `launch.json` existe déjà (généré par l'extension Flutter), ajoute cette configuration dans le tableau `configurations` existant plutôt que d'écraser le fichier. `.vscode/` doit être versionné normalement (ne pas l'ajouter au `.gitignore`) pour que cette configuration reste partagée entre postes.

---

## 4. Configuration native (Android + iOS)

### 4.1 Android — Intent de partage

Vérifie que `android/app/src/main/AndroidManifest.xml` contient les intent-filters décrits dans `SPEC.md` (section Architecture). Sans ça, le partage depuis Instagram/TikTok/etc. n'atteindra jamais l'app.

### 4.2 iOS — Share Extension + App Group

> Cette section ne peut être exécutée que sur macOS avec Xcode (voir section 1) : la création d'un target et l'activation d'une capability se font dans l'éditeur graphique Xcode, aucune commande ne les remplace. Les fichiers applicatifs de l'extension (`ShareViewController.swift`, `Info.plist`, `MainInterface.storyboard`) sont déjà présents dans `ios/RunkShareExtension/` — cette section explique uniquement comment les brancher dans le projet Xcode.

1. **Créer le target** : ouvre `ios/Runner.xcworkspace` (ou `ios/Runner.xcodeproj` si le workspace n'existe pas encore, avant le premier `pod install`) dans Xcode → `File → New → Target… → Share Extension` → nomme-le exactement `RunkShareExtension` → décoche "Activate scheme" si proposé (pas nécessaire pour du développement).
2. **Aligner la cible de déploiement** : dans `Runner` → `Build Settings` → `iOS Deployment Target`, note la valeur, puis règle la même valeur sur le target `RunkShareExtension`.
3. **Remplacer les fichiers générés par Xcode** par ceux déjà présents dans `ios/RunkShareExtension/` :
   - Xcode crée par défaut son propre `Info.plist`, `ShareViewController.swift` (et éventuellement `MainInterface.storyboard` ou un `SwiftUI View` selon la version d'Xcode) dans un dossier `RunkShareExtension/`. Supprime leur contenu généré et remplace-le par le contenu déjà écrit dans `ios/RunkShareExtension/Info.plist`, `ShareViewController.swift` et `Base.lproj/MainInterface.storyboard`.
   - Si Xcode a généré une interface SwiftUI plutôt qu'un storyboard, supprime ce fichier et ajoute `Base.lproj/MainInterface.storyboard` (déjà fourni) au target `RunkShareExtension`, puis vérifie que le `Info.plist` de l'extension référence bien `NSExtensionMainStoryboard = MainInterface` (déjà le cas dans le fichier fourni).
   - Assure-toi que chaque fichier a bien pour "Target Membership" **uniquement** `RunkShareExtension`, jamais `Runner`.
4. **Activer l'App Group sur les deux targets** : pour `Runner` **et** `RunkShareExtension` séparément → `Signing & Capabilities` → `+ Capability` → `App Groups` → ajoute (ou sélectionne s'il existe déjà) `group.com.senluxtech.runk`. Ce doit être exactement la même valeur des deux côtés — c'est elle qui est déjà câblée en dur dans `ios/Runner/Info.plist` (clé `AppGroupId`) et `ios/RunkShareExtension/Info.plist`. Xcode génère automatiquement un fichier `.entitlements` par target à cette étape ; ne pas en créer manuellement.
5. **Vérifier le Bundle Identifier** du target `RunkShareExtension` : Xcode le préremplit en général en `com.senluxtech.runk.RunkShareExtension` (suffixe du bundle id de `Runner`) — c'est la convention attendue, ne pas le modifier pour qu'il diverge.
6. **Ordonner les Build Phases de `Runner`** : `Runner` → `Build Phases` → fais glisser `Embed Foundation Extensions` **au-dessus** de `Thin Binary`. Sans cette étape, le build de `Runner` échoue avec `No such module 'receive_sharing_intent'` dans `ShareViewController.swift` (limitation connue du package, voir son README).
7. **Podfile** : `ios/Podfile` n'existe pas encore dans ce dépôt (jamais générée, aucun build iOS n'a encore eu lieu sur ce projet). Lance une première fois `flutter pub get` puis ouvre le projet dans Xcode (ou `cd ios && pod install`) pour que Flutter génère le `Podfile` par défaut. Ajoute ensuite ce bloc **à l'intérieur** du `target 'Runner' do … end` existant, juste après `flutter_install_all_ios_pods` :
   ```ruby
   target 'RunkShareExtension' do
     inherit! :search_paths
   end
   ```
   Relance `pod install` après cette modification.
8. **Vérifier le Bundle Identifier** de chaque target : unique par target mais du même préfixe (ex: `com.senluxtech.runk` et `com.senluxtech.runk.RunkShareExtension`).

Ces étapes ne sont réalisables qu'une fois sur macOS ; une fois faites, elles sont conservées dans `project.pbxproj` (versionné) et n'ont pas besoin d'être répétées par les développeurs suivants qui clonent le dépôt.

---

## 5. Lancer l'application en local

### 5.1 Lister les appareils disponibles

```bash
flutter devices
```

### 5.2 Lancer sur émulateur/simulateur

```bash
# Android (émulateur déjà démarré via Android Studio, AVD Manager)
flutter run --dart-define-from-file=.env.local

# iOS (simulateur)
open -a Simulator
flutter run --dart-define-from-file=.env.local
```

> `--dart-define-from-file` (Flutter 3.7+) permet de lire toutes les clés depuis un fichier au lieu de les passer une par une en ligne de commande.

### 5.3 Tester le Share Intent en conditions réelles

**Important :** le partage depuis une app tierce (Instagram, TikTok) ne fonctionne fiablement que sur un **appareil physique**, pas toujours sur simulateur/émulateur.

1. Branche un téléphone Android ou iOS en mode développeur
2. Build et installe l'app : `flutter run --release` (le mode debug peut avoir un comportement différent sur le Share Sheet)
3. Ouvre Instagram/TikTok sur le téléphone, partage une vidéo, sélectionne "Runk" dans le menu de partage
4. Vérifie que l'app s'ouvre avec la modale d'ajout pré-remplie

### 5.4 Tester la détection clipboard en conditions réelles

1. Sur un appareil physique (ou simulateur/émulateur, la lecture du presse-papier fonctionne aussi hors appareil physique contrairement au Share Intent), copie un lien vidéo valide (ex: lien TikTok) depuis une autre app ou le navigateur.
2. Reviens sur Runk (l'app doit déjà être ouverte en arrière-plan, ou la relancer déclenche aussi la transition vers `resumed`) → la bannière de suggestion doit apparaître en haut de `HomeScreen`, une seule fois.
3. Teste "Ignorer" : la bannière se ferme, quitte et rouvre l'app avec le même lien toujours dans le presse-papier → la bannière **ne doit plus jamais réapparaître** pour ce lien.
4. Teste "Ajouter" : `AddBookmarkSheet` s'ouvre pré-remplie avec ce lien.
5. Partage explicitement un autre lien vidéo (Share Intent) **pendant** qu'un lien différent est aussi présent dans le presse-papier depuis peu : vérifie que seule la modale du Share Intent s'affiche, jamais la bannière clipboard en même temps.
6. **Spécifique iOS** : sur iOS 16+, comme sur iOS < 16, la bannière système native ("Runk a collé depuis…") s'affichera à la lecture du presse-papier — c'est une limitation de plateforme documentée et acceptée (voir `DECISIONS.md`, entrée "Tâche 6.5"), pas un bug : l'API `UIPasteboard.detectPatterns` qui permettrait de l'éviter sur iOS 16+ nécessiterait un canal de plateforme Swift custom, non implémenté à ce stade (pas d'environnement Xcode disponible pour le développer, voir aussi section 4.2).

---

## 6. Tester l'application

### 6.1 Tests unitaires et widgets

```bash
flutter test
```

### 6.1 bis Test d'intégration du flux interne

`integration_test/app_flow_test.dart` (Tâche 10) rejoue le flux principal
Share Intent → Metadata → Save → affichage de bout en bout via
`WidgetTester`, sans dépendre d'aucune app tierce réelle : une URL déjà
validée est émise directement dans le stream d'un `ShareIntentService` fake,
ce qui ouvre `AddBookmarkSheet`, déclenche la sauvegarde via
`BookmarkRepository` (Isar en répertoire temporaire, aucun appel Supabase
réel) et vérifie que `HomeScreen` affiche le nouveau bookmark.

S'exécute comme un test Flutter classique (pas de `flutter drive` ni
d'appareil physique requis), mais nécessite de préciser un appareil cible
explicitement s'il y en a plusieurs de connectés :

```bash
flutter test integration_test
# ou, si plusieurs appareils/plateformes sont détectés :
flutter test integration_test -d linux
```

Ce test complète, sans la remplacer, la checklist manuelle sur appareil
physique (section 6.3 ci-dessous) — le partage réel depuis Instagram/TikTok
et les deep links de retour vers les apps sources restent hors de son
périmètre (voir `DECISIONS.md`, entrée Tâche 10).

Structure attendue des tests (voir `CONVENTIONS.md`) :
```
test/
├── unit/
│   ├── services/
│   │   ├── metadata_service_test.dart
│   │   └── source_detector_test.dart
│   └── repositories/
│       └── bookmark_repository_test.dart
└── widget/
    └── add_bookmark_sheet_test.dart
```

### 6.2 Analyse statique

```bash
flutter analyze
```

Aucun warning ne doit être ignoré sans justification documentée dans `DECISIONS.md`.

### 6.3 Checklist de test manuel avant chaque release

- [ ] Partage d'un lien YouTube → metadata correcte, thumbnail visible
- [ ] Partage d'un lien TikTok → metadata correcte
- [ ] Partage d'un lien Instagram → metadata récupérée ou fallback propre si échec
- [ ] Partage d'un lien Facebook/Threads → `is_partial` affiché correctement à l'utilisateur, pas de crash
- [ ] Tap sur une vignette → ouverture dans l'app source (ou navigateur en fallback)
- [ ] Ajout de tags, recherche par tag
- [ ] Recherche full-text sur titre
- [ ] Fonctionnement hors ligne (mode avion) → l'ajout reste possible localement
- [ ] Reconnexion réseau → sync automatique vers Supabase
- [ ] Suppression d'un bookmark → synchronisée sur un second appareil connecté au même compte
- [ ] Détection clipboard : lien copié → bannière affichée une seule fois, "Ignorer" empêche toute réapparition, priorité au Share Intent en cas de simultanéité (voir section 5.4)

---

## 7. Déploiement en production

### 7.1 Créer un environnement Supabase de production séparé

Ne réutilise jamais le projet Supabase de dev en prod. Crée un second projet (`runk-prod`), réplique le schéma SQL (section 3.2), et génère de nouvelles clés d'API dédiées.

### 7.2 Android — Build et publication

**Générer une clé de signature :**

```bash
keytool -genkey -v -keystore ~/runk-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias runk
```

**Configurer `android/key.properties`** (jamais commité) :

```
storePassword=<mot de passe>
keyPassword=<mot de passe>
keyAlias=runk
storeFile=/chemin/absolu/vers/runk-release-key.jks
```

**Builder l'App Bundle :**

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=<url_prod> \
  --dart-define=SUPABASE_ANON_KEY=<clé_prod>
```

Le fichier généré est dans `build/app/outputs/bundle/release/app-release.aab`.

**Publier :**
1. Google Play Console → **Créer une application**
2. Renseigner fiche store (nom "Runk", description, captures d'écran, icône, politique de confidentialité)
3. **Production → Créer une version** → upload de l'AAB
4. Compléter le questionnaire de contenu et de confidentialité (obligatoire pour être validé)
5. Soumettre pour review (délai habituel : quelques heures à quelques jours)

### 7.3 iOS — Build et publication

**Configurer la signature dans Xcode :**
1. `Runner.xcworkspace` → target `Runner` → `Signing & Capabilities`
2. Sélectionner ton compte Apple Developer, activer "Automatically manage signing"
3. Répéter pour le target `RunkShareExtension`

**Builder :**

```bash
flutter build ipa --release \
  --dart-define=SUPABASE_URL=<url_prod> \
  --dart-define=SUPABASE_ANON_KEY=<clé_prod>
```

**Publier via Transporter ou Xcode Organizer :**
1. Ouvrir `build/ios/archive/Runner.xcarchive` dans Xcode Organizer, ou utiliser l'app Transporter avec le `.ipa` généré
2. Uploader vers App Store Connect
3. Créer la fiche App Store (captures, description, politique de confidentialité — obligatoire pour l'usage des URL de tiers)
4. Soumettre en TestFlight d'abord pour un test réel avant la review App Store

### 7.4 Politique de confidentialité (obligatoire des deux côtés)

Runk manipule des URLs et métadonnées de plateformes tierces — les deux stores exigeront une politique de confidentialité publique (hébergeable simplement sur `runkapp.com/privacy`).

### 7.5 Suivi post-lancement

- Active les **Supabase Logs** pour surveiller les erreurs API
- Configure un outil de crash reporting (ex: Sentry ou Firebase Crashlytics) avant la publication grand public
- Surveille les schémas d'URL natifs (`instagram://`, `tiktok://`) qui peuvent casser silencieusement après une mise à jour des apps tierces — prévoir une vérification mensuelle

---

## 8. Checklist finale avant chaque publication

- [ ] `flutter analyze` sans erreur
- [ ] `flutter test` tous verts
- [ ] Test manuel complet (section 6.3) sur appareil physique Android **et** iOS
- [ ] Variables d'environnement de production correctement injectées (pas les clés de dev)
- [ ] Politique de confidentialité à jour et accessible publiquement
- [ ] Numéro de version (`pubspec.yaml`) incrémenté
- [ ] `DECISIONS.md`, `TODO.md`, `BUGS_AND_ROADMAP.md` à jour
