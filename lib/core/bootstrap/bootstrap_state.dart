/// App-level initialization state (env loaded, Firebase ready, etc.).
///
/// This exists so [GoRouter]'s `redirect` never has to guess whether
/// bootstrap-dependent state (e.g. auth session) is ready yet — it can
/// check this explicit state first and stay on a splash screen while
/// [loading], per the mandatory "no redirect on not-yet-loaded state"
/// guardrail.
sealed class BootstrapState {
  const BootstrapState();
}

final class BootstrapLoading extends BootstrapState {
  const BootstrapLoading();
}

final class BootstrapReady extends BootstrapState {
  const BootstrapReady();
}

final class BootstrapFailed extends BootstrapState {
  const BootstrapFailed(this.message);

  final String message;
}
