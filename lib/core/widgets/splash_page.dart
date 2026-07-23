import 'package:flutter/material.dart';

/// Shown while [BootstrapState] (or later, auth status) is still loading.
///
/// Its whole purpose is to give the router `redirect` guard somewhere to
/// point at instead of making a redirect decision on incomplete state.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
