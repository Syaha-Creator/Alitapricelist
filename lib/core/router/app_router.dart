import 'package:alita_pricelist/core/bootstrap/bootstrap_provider.dart';
import 'package:alita_pricelist/core/bootstrap/bootstrap_state.dart';
import 'package:alita_pricelist/core/widgets/bootstrap_error_page.dart';
import 'package:alita_pricelist/core/widgets/placeholder_home_page.dart';
import 'package:alita_pricelist/core/widgets/splash_page.dart';
import 'package:alita_pricelist/features/auth/logic/auth_status.dart';
import 'package:alita_pricelist/features/auth/logic/auth_status_provider.dart';
import 'package:alita_pricelist/features/auth/presentation/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Route paths as constants so nothing typos a path string across features.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const login = '/login';
  // Every subsequent route addition must extend the redirect guard below
  // rather than bypass it.
}

/// Manual (non-generated) Riverpod provider — see note in
/// `bootstrap_provider.dart` for why `riverpod_generator` isn't used here.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const PlaceholderHomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
    ],
    redirect: (context, state) {
      // Guardrail: redirect decisions never run against a not-yet-loaded
      // state. `bootstrap` is an AsyncValue, so loading/data/error are all
      // handled explicitly here — there is no implicit "assume ready" path.
      final bootstrap = ref.read(bootstrapProvider);
      final bootstrapRedirect = bootstrap.when(
        loading: () => state.matchedLocation == AppRoutes.splash
            ? null
            : AppRoutes.splash,
        error: (error, stackTrace) => null, // handled by errorBuilder below
        data: (value) => switch (value) {
          BootstrapLoading() => state.matchedLocation == AppRoutes.splash
              ? null
              : AppRoutes.splash,
          BootstrapFailed() => null,
          BootstrapReady() => null, // fall through to the auth check below
        },
      );
      if (bootstrapRedirect != null) return bootstrapRedirect;
      // Bootstrap isn't BootstrapReady yet (loading/failed) — stop here,
      // the auth guard below must never run against a not-yet-loaded
      // bootstrap state.
      final bootstrapValue = bootstrap.valueOrNull;
      if (bootstrapValue is! BootstrapReady) return null;

      // Same guardrail as above, this time for auth: never redirect based
      // on a not-yet-loaded auth status.
      final auth = ref.read(authStatusProvider);
      return auth.when(
        loading: () => state.matchedLocation == AppRoutes.splash
            ? null
            : AppRoutes.splash,
        error: (error, stackTrace) => state.matchedLocation == AppRoutes.login
            ? null
            : AppRoutes.login,
        data: (value) => switch (value) {
          AuthLoading() => state.matchedLocation == AppRoutes.splash
              ? null
              : AppRoutes.splash,
          AuthUnauthenticated() => state.matchedLocation == AppRoutes.login
              ? null
              : AppRoutes.login,
          AuthAuthenticated() => state.matchedLocation == AppRoutes.login ||
                  state.matchedLocation == AppRoutes.splash
              ? AppRoutes.home
              : null,
        },
      );
    },
    errorBuilder: (context, state) {
      final bootstrapValue = ref.read(bootstrapProvider);
      final message = bootstrapValue.hasError
          ? bootstrapValue.error.toString()
          : 'Halaman tidak ditemukan: ${state.uri}';
      return BootstrapErrorPage(message: message);
    },
    refreshListenable: GoRouterRefreshStream(ref),
  );
});

/// Bridges Riverpod's [bootstrapProvider]/[authStatusProvider] changes into
/// something [GoRouter] can listen to, so `redirect` re-runs whenever
/// either state changes (e.g. login/logout).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(bootstrapProvider, (previous, next) => notifyListeners());
    ref.listen(authStatusProvider, (previous, next) => notifyListeners());
  }
}
