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

1. Ouvre `ios/Runner.xcworkspace` dans Xcode
2. Ajoute le target `RunkShareExtension` (`File → New → Target → Share Extension`) si ce n'est pas déjà fait
3. Active l'**App Group** `group.com.senluxtech.runk` sur **les deux targets** (`Runner` et `RunkShareExtension`) via `Signing & Capabilities → + Capability → App Groups`
4. Vérifie que le Bundle Identifier de chaque target est unique mais du même préfixe (ex: `com.senluxtech.runk` et `com.senluxtech.runk.ShareExtension`)

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

---

## 6. Tester l'application

### 6.1 Tests unitaires et widgets

```bash
flutter test
```

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
