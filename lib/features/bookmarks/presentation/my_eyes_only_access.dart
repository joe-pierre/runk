import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/my_eyes_only_service.dart';
import '../../../core/services/my_eyes_only_service_provider.dart';
import '../data/bookmark_repository_provider.dart';
import 'bookmark_list_provider.dart';
import 'my_eyes_only_screen.dart';

/// Résultat de la boîte de dialogue de saisie du code existant (voir
/// [_EnterPinDialog]).
enum _EnterPinResult { unlocked, forgotten }

/// Nombre minimal de chiffres requis pour un code "My Eyes Only" (voir
/// Tâche 22).
const _minPinLength = 4;

/// Ouvre le flux d'accès à la section "My Eyes Only" (Tâche 22, voir
/// DECISIONS.md), déclenché par un appui long sur le titre "Runk" de
/// `HomeScreen` :
/// - aucun code défini → dialogue de création (saisie + confirmation) ;
/// - un code est défini → dialogue de saisie, avec un lien "Code oublié ?"
///   qui démasque tous les bookmarks masqués et permet d'en définir un
///   nouveau.
///
/// Porte toute la logique de mutation (`MyEyesOnlyService` +
/// `BookmarkRepository`, via leurs providers respectifs) — ni
/// `MyEyesOnlyScreen` ni `HomeScreen` n'accèdent directement à ces couches
/// (voir CONVENTIONS.md section Partials / Frontend).
Future<void> openMyEyesOnly(BuildContext context, WidgetRef ref) async {
  final service = await ref.read(myEyesOnlyServiceProvider.future);
  if (!context.mounted) return;

  if (!service.hasPinSet()) {
    await _createPinThenOpen(context, ref, service);
    return;
  }

  final result = await showDialog<_EnterPinResult>(
    context: context,
    builder: (dialogContext) => _EnterPinDialog(service: service),
  );
  if (result == null || !context.mounted) return;

  switch (result) {
    case _EnterPinResult.unlocked:
      _pushMyEyesOnlyScreen(context);
    case _EnterPinResult.forgotten:
      await _handleForgotPin(context, ref, service);
  }
}

/// Demande confirmation, puis efface le code et démasque tous les
/// bookmarks masqués (aucune perte de données) avant d'enchaîner
/// immédiatement sur la création d'un nouveau code.
Future<void> _handleForgotPin(
  BuildContext context,
  WidgetRef ref,
  MyEyesOnlyService service,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Code oublié ?'),
      content: const Text(
        'Ça démasquera tous les bookmarks masqués, continuer ?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Continuer'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  await service.resetPin();
  final repository = await ref.read(bookmarkRepositoryProvider.future);
  await repository.unhideAllBookmarks();
  await ref.read(bookmarkListProvider.notifier).refresh();
  if (!context.mounted) return;

  await _createPinThenOpen(context, ref, service);
}

/// Ouvre le dialogue de création de code, puis enregistre le code saisi et
/// ouvre `MyEyesOnlyScreen` — sans effet si l'utilisateur annule.
Future<void> _createPinThenOpen(
  BuildContext context,
  WidgetRef ref,
  MyEyesOnlyService service,
) async {
  final pin = await showDialog<String>(
    context: context,
    builder: (dialogContext) => const _CreatePinDialog(),
  );
  if (pin == null || !context.mounted) return;

  await service.setPin(pin);
  if (!context.mounted) return;

  _pushMyEyesOnlyScreen(context);
}

void _pushMyEyesOnlyScreen(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const MyEyesOnlyScreen()));
}

/// Dialogue de création d'un nouveau code : saisie + confirmation, validées
/// au moins [_minPinLength] chiffres et identiques avant de pouvoir valider.
class _CreatePinDialog extends StatefulWidget {
  const _CreatePinDialog();

  @override
  State<_CreatePinDialog> createState() => _CreatePinDialogState();
}

class _CreatePinDialogState extends State<_CreatePinDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _pinController.text;
    final confirmation = _confirmController.text;

    if (pin.length < _minPinLength || int.tryParse(pin) == null) {
      setState(
        () => _errorText = 'Le code doit contenir au moins $_minPinLength '
            'chiffres.',
      );
      return;
    }
    if (pin != confirmation) {
      setState(() => _errorText = 'Les deux codes ne correspondent pas.');
      return;
    }

    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Définir un code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Code'),
          ),
          TextField(
            controller: _confirmController,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Confirmer le code'),
            onSubmitted: (_) => _submit(),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Valider')),
      ],
    );
  }
}

/// Dialogue de saisie du code existant, avec un lien "Code oublié ?".
///
/// Ne connaît ni `BookmarkRepository` ni la logique de réinitialisation :
/// se contente de retourner [_EnterPinResult.forgotten] si l'utilisateur
/// choisit ce lien — la confirmation et la mutation elle-même vivent dans
/// [_handleForgotPin], appelée par [openMyEyesOnly] une fois ce dialogue
/// fermé.
class _EnterPinDialog extends StatefulWidget {
  const _EnterPinDialog({required this.service});

  final MyEyesOnlyService service;

  @override
  State<_EnterPinDialog> createState() => _EnterPinDialogState();
}

class _EnterPinDialogState extends State<_EnterPinDialog> {
  final _pinController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.service.verifyPin(_pinController.text)) {
      Navigator.of(context).pop(_EnterPinResult.unlocked);
      return;
    }
    setState(() => _errorText = 'Code incorrect.');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Code requis'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Code'),
            onSubmitted: (_) => _submit(),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_EnterPinResult.forgotten),
              child: const Text('Code oublié ?'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Valider')),
      ],
    );
  }
}
