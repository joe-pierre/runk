import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository_provider.dart';
import '../features/auth/presentation/auth_form.dart';
import '../features/auth/presentation/link_local_data_prompt.dart';
import '../features/settings/presentation/theme_mode_selector.dart';

/// Contenu du `Drawer` racine d'[AppShell] (Tâche 28, voir DECISIONS.md).
///
/// Affiche `AuthForm` tant qu'aucune session Supabase active n'existe, sinon
/// l'email du compte connecté et un bouton de déconnexion — se met à jour
/// automatiquement via [authStateChangesProvider] (voir SPEC.md section 7).
///
/// Écoute (`ref.listen`) les transitions "aucune session" → "session
/// active" pour déclencher [promptToLinkLocalData], que la session vienne
/// d'une connexion ou d'une inscription (voir DECISIONS.md, Tâche 28 et
/// extension tags remote sync — le rattachement lui-même reste conditionné
/// à l'existence d'au moins un bookmark **ou** tag local non lié, jamais
/// affiché sans raison). Utilise le
/// `BuildContext` de ce widget plutôt que celui d'`AuthForm` : ce dernier
/// disparaît de l'arbre dès que la session change (remplacé par la vue
/// connectée ci-dessous), et pourrait ne plus être monté au moment
/// d'afficher la boîte de dialogue.
///
/// Porte aussi [ThemeModeSelector] (Tâche 29, voir DECISIONS.md), affiché
/// dans tous les cas (session active ou non) au-dessus du contenu lié à
/// l'authentification — le thème n'a aucun lien avec la connexion.
class AppDrawer extends ConsumerWidget {
  /// Crée le drawer.
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateChangesProvider, (previous, next) {
      final hadSession = previous?.value?.session != null;
      final nextSession = next.value?.session;
      if (!hadSession && nextSession != null) {
        unawaited(promptToLinkLocalData(context, ref, nextSession.user.id));
      }
    });

    final session = ref.watch(authStateChangesProvider).value?.session;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const ThemeModeSelector(),
            const Divider(height: 32),
            Expanded(
              child: session == null
                  ? const SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: AuthForm(),
                    )
                  : _SignedInDrawerContent(email: session.user.email ?? ''),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenu du drawer une fois une session active — affiche [email] et un
/// bouton de déconnexion.
///
/// La déconnexion ne supprime aucune donnée locale (voir
/// `AuthRepository.signOut`) : les bookmarks restent visibles hors ligne,
/// seule la synchronisation s'arrête (`SyncService`, inchangé).
class _SignedInDrawerContent extends ConsumerWidget {
  const _SignedInDrawerContent({required this.email});

  /// Email du compte connecté, affiché tel quel.
  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Connecté en tant que',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(email, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
