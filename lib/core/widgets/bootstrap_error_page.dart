import 'package:flutter/material.dart';

/// Shown when app-level bootstrap (env/Firebase init) fails outright.
///
/// This is the explicit "error" branch of the loading|data|error triad —
/// there is no silent fallback to a broken app state.
class BootstrapErrorPage extends StatelessWidget {
  const BootstrapErrorPage({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Gagal memulai aplikasi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
