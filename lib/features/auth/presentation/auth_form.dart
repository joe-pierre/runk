import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository_provider.dart';
import '../domain/auth_failure.dart';

/// Formulaire unique d'authentification email/mot de passe (Tâche 28, voir
/// DECISIONS.md), affiché dans `AppDrawer` tant qu'aucune session Supabase
/// active n'existe.
///
/// Bascule entre "Se connecter" et "Créer un compte" via un simple
/// [TextButton] — un seul jeu de champs email/mot de passe, jamais deux
/// formulaires distincts. Délègue toute la logique d'authentification à
/// `AuthRepository` via [authRepositoryProvider] (voir CONVENTIONS.md
/// section Réponses API) : ce widget ne contient aucun appel direct à
/// Supabase. Toute [AuthFailure] (mauvais mot de passe, email déjà utilisé,
/// etc.) est affichée telle quelle à l'utilisateur, jamais avalée
/// silencieusement (voir prompt de la Tâche 28).
class AuthForm extends ConsumerStatefulWidget {
  /// Crée le formulaire.
  const AuthForm({super.key});

  @override
  ConsumerState<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUpMode = false;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final repository = ref.read(authRepositoryProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isSignUpMode) {
        await repository.signUp(email: email, password: password);
      } else {
        await repository.signIn(email: email, password: password);
      }
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() => _errorText = failure.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isSignUpMode ? 'Créer un compte' : 'Se connecter',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            enabled: !_isSubmitting,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) => (value == null || !value.contains('@'))
                ? 'Adresse email invalide'
                : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            enabled: !_isSubmitting,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
            validator: (value) => (value == null || value.length < 6)
                ? 'Au moins 6 caractères'
                : null,
            onFieldSubmitted: (_) => _submit(),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isSignUpMode ? 'Créer un compte' : 'Se connecter'),
          ),
          TextButton(
            onPressed: _isSubmitting ? null : _toggleMode,
            child: Text(
              _isSignUpMode
                  ? 'Déjà un compte ? Se connecter'
                  : 'Pas de compte ? En créer un',
            ),
          ),
        ],
      ),
    );
  }
}
