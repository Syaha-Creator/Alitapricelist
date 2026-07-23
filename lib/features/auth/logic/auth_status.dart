import 'package:alita_pricelist/features/auth/data/models/auth_session.dart';

/// Explicit auth status, mirroring the same pattern as `BootstrapState` —
/// see that file's doc comment for why: [GoRouter]'s `redirect` must never
/// have to guess whether the session has finished loading.
sealed class AuthStatus {
  const AuthStatus();
}

final class AuthLoading extends AuthStatus {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthStatus {
  const AuthAuthenticated(this.session);

  final AuthSession session;
}

final class AuthUnauthenticated extends AuthStatus {
  const AuthUnauthenticated();
}
