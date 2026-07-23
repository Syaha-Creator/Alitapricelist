import 'package:alita_pricelist/core/bootstrap/bootstrap_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes app-level bootstrap status as an explicit, watchable state.
///
/// The actual one-time init (load `.env`, init Firebase) happens in
/// `main()` *before* `runApp`, so that `runZonedGuarded` + Crashlytics are
/// wired before any widget builds. This provider exists so that
/// [GoRouter]'s `redirect` — and later, feature providers like
/// `authStatusProvider` — always have an explicit state to check instead of
/// assuming bootstrap has already finished.
///
/// Manual (non-generated) Riverpod provider: `riverpod_generator` currently
/// pulls a transitive `custom_lint_core`/`analyzer` version that conflicts
/// with `freezed`'s `analyzer` constraint in this pub ecosystem snapshot, so
/// providers in this codebase are written by hand until that's resolved
/// upstream.
final bootstrapProvider = AsyncNotifierProvider<BootstrapNotifier, BootstrapState>(
  BootstrapNotifier.new,
);

class BootstrapNotifier extends AsyncNotifier<BootstrapState> {
  @override
  Future<BootstrapState> build() async {
    return const BootstrapReady();
  }
}
