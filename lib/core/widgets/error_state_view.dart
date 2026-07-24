import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Reusable error state with an optional retry action — copied from the
/// legacy app's `core/widgets/error_state_view.dart`. After tapping retry,
/// the button switches to a spinner for immediate feedback, with an 8s
/// safety reset in case the parent hasn't unmounted yet.
class ErrorStateView extends StatefulWidget {
  const ErrorStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
    this.retryLabel = 'Coba Lagi',
    this.padding = const EdgeInsets.all(24),
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryLabel;
  final EdgeInsetsGeometry padding;

  @override
  State<ErrorStateView> createState() => _ErrorStateViewState();
}

class _ErrorStateViewState extends State<ErrorStateView> {
  bool _isRetrying = false;

  void _handleRetry() {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    widget.onRetry?.call();
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _isRetrying = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Error: ${widget.title}. ${widget.message}',
      child: Center(
        child: Padding(
          padding: widget.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 56, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _isRetrying ? null : _handleRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isRetrying
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(AppColors.onPrimary),
                              ),
                            )
                          : Row(
                              key: const ValueKey('label'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.refresh_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(widget.retryLabel),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
