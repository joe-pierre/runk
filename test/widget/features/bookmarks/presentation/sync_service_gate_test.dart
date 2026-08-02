import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runk/features/auth/data/auth_repository.dart';
import 'package:runk/features/auth/data/auth_repository_provider.dart';
import 'package:runk/features/bookmarks/data/sync_service.dart';
import 'package:runk/features/bookmarks/data/sync_service_provider.dart';
import 'package:runk/features/bookmarks/presentation/sync_service_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake d'[AuthRepository] : expose un flux d'[AuthState] entièrement
/// contrôlé par le test, sans dépendre d'un client Supabase réel (même
/// raisonnement que `_FakeAuthRepository` dans `auth_form_test.dart`).
class _FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthState>.broadcast();

  void emit(AuthState state) => _controller.add(state);

  @override
  Stream<AuthState> get onAuthStateChange => _controller.stream;

  @override
  User? get currentUser => null;

  @override
  Session? get currentSession => null;

  @override
  Future<void> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signUp({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();
}

/// Fake de [SyncService] : ne fait aucun appel réel, se contente de compter
/// les appels à [syncNow] et [start] (voir prompt de la tâche — vérifier
/// qu'un `signedIn` déclenche bien `syncNow()`).
class _FakeSyncService implements SyncService {
  int syncNowCallCount = 0;
  int startCallCount = 0;

  @override
  Duration get periodicInterval => const Duration(minutes: 2);

  @override
  void start() => startCallCount++;

  @override
  void dispose() {}

  @override
  Future<void> syncNow() async => syncNowCallCount++;
}

void main() {
  Future<_FakeAuthRepository> pumpGate(
    WidgetTester tester,
    _FakeSyncService syncService,
  ) async {
    final authRepository = _FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          syncServiceProvider.overrideWith((ref) async => syncService),
        ],
        child: const SyncServiceGate(child: SizedBox.shrink()),
      ),
    );
    await tester.pumpAndSettle();
    return authRepository;
  }

  testWidgets(
    'un événement signedIn déclenche syncNow() sur SyncService',
    (tester) async {
      final syncService = _FakeSyncService();
      final authRepository = await pumpGate(tester, syncService);
      final callsBeforeSignIn = syncService.syncNowCallCount;

      authRepository.emit(
        AuthState(
          AuthChangeEvent.signedIn,
          Session(
            accessToken: 'token',
            tokenType: 'bearer',
            user: const User(
              id: 'user-1',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: '2026-01-01T00:00:00Z',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(syncService.syncNowCallCount, greaterThan(callsBeforeSignIn));
    },
  );

  testWidgets(
    'un événement signedOut ne déclenche aucun appel superflu à syncNow()',
    (tester) async {
      final syncService = _FakeSyncService();
      final authRepository = await pumpGate(tester, syncService);
      final callsBeforeSignOut = syncService.syncNowCallCount;

      authRepository.emit(const AuthState(AuthChangeEvent.signedOut, null));
      await tester.pumpAndSettle();

      expect(syncService.syncNowCallCount, callsBeforeSignOut);
    },
  );
}
