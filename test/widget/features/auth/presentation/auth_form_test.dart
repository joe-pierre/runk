import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/features/auth/data/auth_repository.dart';
import 'package:runk/features/auth/data/auth_repository_provider.dart';
import 'package:runk/features/auth/domain/auth_failure.dart';
import 'package:runk/features/auth/presentation/auth_form.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake d'[AuthRepository] : n'effectue jamais d'appel Supabase réel — permet
/// de vérifier que `AuthForm` affiche les erreurs sans les avaler
/// silencieusement (voir prompt de la Tâche 28), sans dépendre du réseau
/// (même raisonnement que `FakeBookmarkRemoteDatasource`, voir DECISIONS.md
/// Tâche 4).
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.signInError, this.signUpError});

  final AuthFailure? signInError;
  final AuthFailure? signUpError;
  final List<String> calls = [];

  @override
  Future<void> signIn({required String email, required String password}) async {
    calls.add('signIn:$email');
    if (signInError != null) throw signInError!;
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    calls.add('signUp:$email');
    if (signUpError != null) throw signUpError!;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
  }

  @override
  User? get currentUser => null;

  @override
  Session? get currentSession => null;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();
}

void main() {
  Future<_FakeAuthRepository> pumpAuthForm(
    WidgetTester tester, {
    AuthFailure? signInError,
    AuthFailure? signUpError,
  }) async {
    final fakeRepository = _FakeAuthRepository(
      signInError: signInError,
      signUpError: signUpError,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: AuthForm())),
        ),
      ),
    );
    return fakeRepository;
  }

  testWidgets(
    'affiche une erreur de validation et n\'appelle jamais le repository '
    'si l\'email est invalide',
    (tester) async {
      final fakeRepository = await pumpAuthForm(tester);

      await tester.enterText(find.byType(TextFormField).first, 'pas-un-email');
      await tester.enterText(find.byType(TextFormField).last, 'motdepasse');
      await tester.tap(find.text('Se connecter').last);
      await tester.pumpAndSettle();

      expect(find.text('Adresse email invalide'), findsOneWidget);
      expect(fakeRepository.calls, isEmpty);
    },
  );

  testWidgets(
    'affiche le message d\'AuthFailure renvoyé par le repository à la '
    'connexion, sans jamais l\'avaler silencieusement',
    (tester) async {
      await pumpAuthForm(
        tester,
        signInError: const AuthFailure('Mot de passe incorrect'),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'user@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'motdepasse');
      await tester.tap(find.text('Se connecter').last);
      await tester.pumpAndSettle();

      expect(find.text('Mot de passe incorrect'), findsOneWidget);
    },
  );

  testWidgets(
    'bascule vers le mode inscription et appelle signUp plutôt que signIn',
    (tester) async {
      final fakeRepository = await pumpAuthForm(tester);

      await tester.tap(find.text('Pas de compte ? En créer un'));
      await tester.pumpAndSettle();
      expect(find.text('Créer un compte'), findsWidgets);

      await tester.enterText(
        find.byType(TextFormField).first,
        'nouveau@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'motdepasse');
      await tester.tap(find.text('Créer un compte').last);
      await tester.pumpAndSettle();

      expect(fakeRepository.calls, ['signUp:nouveau@example.com']);
    },
  );
}
