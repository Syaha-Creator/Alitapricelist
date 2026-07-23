import 'package:alita_pricelist/core/bootstrap/bootstrap_provider.dart';
import 'package:alita_pricelist/core/bootstrap/bootstrap_state.dart';
import 'package:alita_pricelist/core/widgets/bootstrap_error_page.dart';
import 'package:alita_pricelist/core/widgets/placeholder_home_page.dart';
import 'package:alita_pricelist/core/widgets/splash_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Route paths as constants so nothing typos a path string across features.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  // Auth routes are added in step 2; every subsequent route addition must
  // extend the redirect guard below rather than bypass it.
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
    ],
    redirect: (context, state) {
      // Guardrail: redirect decisions never run against a not-yet-loaded
      // state. `bootstrap` is an AsyncValue, so loading/data/error are all
      // handled explicitly here — there is no implicit "assume ready" path.
      final bootstrap = ref.read(bootstrapProvider);
      return bootstrap.when(
        loading: () => state.matchedLocation == AppRoutes.splash
            ? null
            : AppRoutes.splash,
        error: (error, stackTrace) => null, // handled by errorBuilder below
        data: (value) => switch (value) {
          BootstrapLoading() => state.matchedLocation == AppRoutes.splash
              ? null
              : AppRoutes.splash,
          BootstrapFailed() => null,
          BootstrapReady() => state.matchedLocation == AppRoutes.splash
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

/// Bridges Riverpod's [bootstrapProvider] changes into something [GoRouter]
/// can listen to, so `redirect` re-runs whenever bootstrap state changes
/// (e.g. once auth status is added in step 2).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(bootstrapProvider, (previous, next) => notifyListeners());
  }
}
