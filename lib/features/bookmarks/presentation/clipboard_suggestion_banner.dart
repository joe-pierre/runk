import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_bookmark_sheet.dart';
import 'clipboard_suggestion_provider.dart';

/// Bannière non bloquante affichée en haut de `HomeScreen` lorsqu'un lien
/// vidéo valide et nouveau est détecté dans le presse-papier (voir SPEC.md
/// section 11).
///
/// Deux actions explicites, jamais de sauvegarde automatique (SPEC.md
/// section 4 règle 7) :
/// - **Ajouter** : ouvre `AddBookmarkSheet` pré-remplie avec le lien détecté ;
/// - **Ignorer** : mémorise le lien comme vu et referme la bannière, sans
///   jamais le reproposer.
///
/// N'affiche rien (`SizedBox.shrink`) tant qu'aucune suggestion n'est
/// active — jamais de widget intermédiaire visible (spinner, etc.), pour
/// rester non intrusive. Purement présentationnel : toute la logique de
/// détection, de priorité et d'historique vit dans `ClipboardSuggestion`
/// (voir CONVENTIONS.md section Partials / Frontend).
///
/// Renforcement visuel (Tâche 19) : fond `colorScheme.primaryContainer`
/// (accent cohérent avec le thème Material 3 sombre de l'app — voir
/// DECISIONS.md, entrée "Tâche 19"), apparition en glissement + fondu depuis
/// le haut (`AnimatedSwitcher`) plutôt qu'instantanée, et un léger retour
/// haptique (`HapticFeedback.lightImpact`) déclenché une seule fois par
/// nouvelle suggestion — `ref.listen` ne réagit qu'à un vrai changement
/// d'état du provider, jamais à un simple rebuild du widget.
class ClipboardSuggestionBanner extends ConsumerWidget {
  const ClipboardSuggestionBanner({super.key});

  static const _appearanceTransitionDuration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedUrl = ref.watch(clipboardSuggestionProvider);
    final notifier = ref.read(clipboardSuggestionProvider.notifier);

    ref.listen<String?>(clipboardSuggestionProvider, (previous, next) {
      if (next != null && next != previous) {
        HapticFeedback.lightImpact();
      }
    });

    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: _appearanceTransitionDuration,
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: suggestedUrl == null
          ? const SizedBox.shrink(key: ValueKey('clipboard-banner-empty'))
          : MaterialBanner(
              key: ValueKey('clipboard-banner-$suggestedUrl'),
              backgroundColor: colorScheme.primaryContainer,
              content: Text(
                'Un lien vidéo a été détecté dans le presse-papier.',
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
              leading: Icon(Icons.link, color: colorScheme.onPrimaryContainer),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                  onPressed: () => _add(context, notifier, suggestedUrl),
                  child: const Text('Ajouter'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                  onPressed: () => notifier.markAsSeen(suggestedUrl),
                  child: const Text('Ignorer'),
                ),
              ],
            ),
    );
  }

  Future<void> _add(
    BuildContext context,
    ClipboardSuggestion notifier,
    String url,
  ) async {
    await notifier.markAsSeen(url);
    if (context.mounted) {
      await AddBookmarkSheet.show(context, url: url);
    }
  }
}
