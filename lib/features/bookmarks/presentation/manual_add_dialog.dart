import 'package:flutter/material.dart';

import '../../../core/utils/url_text_extractor.dart';
import 'add_bookmark_sheet.dart';

/// Popup de saisie manuelle d'une URL — troisième voie d'entrée d'un
/// bookmark (voir SPEC.md section 11), déclenchée par le bouton "+" de
/// `HomeScreen`.
///
/// Unique responsabilité : capter une chaîne tapée ou collée par
/// l'utilisateur et la valider comme URL exploitable, en réutilisant
/// [UrlTextExtractor] (même règle de validation que le Share Intent et la
/// détection clipboard, voir CONVENTIONS.md section Validation) — aucune
/// logique de récupération de métadonnées, de miniature ou de titre : tout
/// ça reste exclusivement dans [AddBookmarkSheet].
class ManualAddDialog extends StatefulWidget {
  const ManualAddDialog({super.key});

  /// Affiche la popup de saisie au-dessus de l'écran courant. Si
  /// l'utilisateur y valide une URL exploitable, enchaîne automatiquement
  /// sur `AddBookmarkSheet.show` avec cette URL — sinon (annulation), ne
  /// fait rien.
  static Future<void> show(BuildContext context) async {
    final validUrl = await showDialog<String>(
      context: context,
      builder: (context) => const ManualAddDialog(),
    );
    if (validUrl != null && context.mounted) {
      await AddBookmarkSheet.show(context, url: validUrl);
    }
  }

  @override
  State<ManualAddDialog> createState() => _ManualAddDialogState();
}

class _ManualAddDialogState extends State<ManualAddDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Valide la chaîne saisie via [UrlTextExtractor.extractBestUrl] : si
  /// aucune URL exploitable n'en ressort, affiche une erreur inline sans
  /// fermer la popup ; sinon, referme la popup en lui transmettant l'URL
  /// validée (voir [ManualAddDialog.show]).
  void _submit() {
    final input = _controller.text.trim();
    final validUrl = UrlTextExtractor.extractBestUrl(input);

    if (validUrl == null) {
      setState(() => _errorText = 'Ce n\'est pas un lien valide.');
      return;
    }

    Navigator.of(context).pop(validUrl);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un lien'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: 'Lien de la vidéo',
          border: const OutlineInputBorder(),
          errorText: _errorText,
        ),
        onChanged: (_) {
          if (_errorText != null) setState(() => _errorText = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Ajouter')),
      ],
    );
  }
}
