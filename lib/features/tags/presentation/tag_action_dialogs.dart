import 'package:flutter/material.dart';

/// Demande à l'utilisateur un nom de tag via une boîte de dialogue simple
/// (un seul [TextField]) — utilisée pour la création (Tâche 15,
/// `initialValue` absent) et le renommage (`initialValue` pré-rempli avec le
/// nom actuel).
///
/// Retourne le texte saisi, ou `null` si l'utilisateur annule.
Future<String?> promptForTagName(
  BuildContext context, {
  required String title,
  String? initialValue,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nom du tag'),
        onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(controller.text),
          child: const Text('Valider'),
        ),
      ],
    ),
  );
}

/// Demande confirmation avant de supprimer [tag], en affichant le nombre de
/// bookmarks impactés ([impactedCount]) — la suppression retire le tag de
/// tous ces bookmarks (suppression en cascade, voir DECISIONS.md, entrée
/// « Tâche 15 »).
///
/// Retourne `true` si l'utilisateur confirme, `false`/`null` sinon.
Future<bool?> confirmTagDeletion(
  BuildContext context, {
  required String tag,
  required int impactedCount,
}) {
  final message = impactedCount == 0
      ? 'Supprimer le tag « $tag » ?'
      : 'Ce tag est utilisé par $impactedCount bookmark'
            '${impactedCount > 1 ? 's' : ''}. Le supprimer le retirera de '
            'tous ces bookmarks. Continuer ?';

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Supprimer ce tag ?'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}
