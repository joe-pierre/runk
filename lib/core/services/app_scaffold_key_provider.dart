import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clé du `Scaffold` racine d'`AppShell`, partagée avec `HomeScreen`,
/// `TagsScreen` et `SearchScreen` (Tâche 28, voir DECISIONS.md).
///
/// Chacun de ces 3 écrans a son propre `Scaffold` imbriqué sous celui
/// d'`AppShell` (constat déjà documenté en DECISIONS.md avant cette tâche) :
/// `Scaffold.of(context)` depuis leur `AppBar` résoudrait donc à leur propre
/// `Scaffold`, pas à celui d'`AppShell` qui porte le `Drawer`. Exposer cette
/// clé via un provider permet à chacun d'appeler
/// `key.currentState?.openDrawer()` pour ouvrir le bon `Scaffold`, sans
/// avoir à faire descendre la clé manuellement à travers les routes
/// `go_router` (qui construisent ces écrans indépendamment d'`AppShell`).
///
/// Placé dans `core/services/` plutôt que `app/` bien que conceptuellement
/// "créé au niveau d'AppShell" (voir prompt de la Tâche 28) : ce provider ne
/// dépend d'aucune feature, et le faire vivre dans `app/` aurait forcé
/// `HomeScreen`/`TagsScreen`/`SearchScreen` (des `features/`) à importer
/// depuis `app/`, inversant la direction de dépendance établie depuis
/// DECISIONS.md (Tâche 4) : `app/` dépend de `features/`, jamais l'inverse.
/// `AppShell` reste l'unique endroit qui l'assigne à un `Scaffold` (voir
/// `app_shell.dart`) — seul son emplacement de fichier diffère.
///
/// `Provider` simple (pas `autoDispose`) : la clé doit rester stable pour
/// toute la durée de vie de l'app, indépendamment de l'onglet actif.
final appScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>(
  (ref) => GlobalKey<ScaffoldState>(),
);
