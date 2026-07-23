import 'dart:async';

import 'package:alita_pricelist/core/error/result.dart';
import 'package:alita_pricelist/features/auth/data/services/auth_repository.dart';
import 'package:alita_pricelist/features/auth/data/services/firebase_anonymous_auth.dart';
import 'package:alita_pricelist/features/auth/logic/auth_repository_provider.dart';
import 'package:alita_pricelist/features/auth/logic/auth_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes auth status as an explicit, watchable state — same pattern as
/// `bootstrapProvider`. `GoRouter`'s `redirect` must check the loading
/// [AsyncValue] state first, per the "no redirect on not-yet-loaded state"
/// guardrail (see `bootstrap_state.dart`).
///
/// Manual (non-generated) Riverpod provider — see the note in
/// `bootstrap_provider.dart` for why `riverpod_generator` isn't used here.
final authStatusProvider = AsyncNotifierProvider<AuthStatusNotifier, AuthStatus>(AuthStatusNotifier.new);

class AuthStatusNotifier extends AsyncNotifier<AuthStatus> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  FirebaseAnonymousAuth get _firebaseAnonymousAuth => ref.read(firebaseAnonymousAuthProvider);

  @override
  Future<AuthStatus> build() async {
    final result = await _repository.restoreSession();
    return result.when(
      success: (session) => session == null ? const AuthUnauthenticated() : AuthAuthenticated(session),
      // A storage read failure on startup is treated as "not logged in"
      // rather than surfacing a loading-forever/error state — the user can
      // just log in again.
      failure: (_) => const AuthUnauthenticated(),
    );
  }

  /// Returns the [Result] so the login screen can show a field-level error
  /// message; [state] is only updated on success.
  Future<Result<void>> login({required String email, required String password}) async {
    final result = await _repository.login(email: email, password: password);
    return result.when(
      success: (session) {
        state = AsyncData(AuthAuthenticated(session));
        // Fire-and-forget: Firebase anonymous auth must never block or
        // fail the login that already succeeded against the REST API
        // (SPEC.md §5.1).
        unawaited(_firebaseAnonymousAuth.ensureSignedIn());
        return const Result.success(null);
      },
      failure: (error) => Result.failure(error),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncData(AuthUnauthenticated());
  }
}
