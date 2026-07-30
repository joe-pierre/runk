import 'package:flutter/material.dart';
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
class ClipboardSuggestionBanner extends ConsumerWidget {
  const ClipboardSuggestionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedUrl = ref.watch(clipboardSuggestionProvider);
    if (suggestedUrl == null) return const SizedBox.shrink();

    final notifier = ref.read(clipboardSuggestionProvider.notifier);

    return MaterialBanner(
      content: const Text(
        'Un lien vidéo a été détecté dans le presse-papier.',
      ),
      leading: const Icon(Icons.link),
      actions: [
        TextButton(
          onPressed: () => _add(context, notifier, suggestedUrl),
          child: const Text('Ajouter'),
        ),
        TextButton(
          onPressed: () => notifier.markAsSeen(suggestedUrl),
          child: const Text('Ignorer'),
        ),
      ],
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
