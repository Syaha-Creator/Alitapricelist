import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Reusable empty-state block (`icon -> title -> subtitle -> optional
/// action`) — copied from the legacy app's `core/widgets/empty_state_view.dart`
/// so "no results"/"nothing selected yet" states look the same across the
/// rewrite as they did in the legacy app.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.padding = const EdgeInsets.all(24),
    this.iconSize = 80,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final EdgeInsetsGeometry padding;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600);
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary, height: 1.5);

    return Semantics(
      label: '$title. $subtitle',
      child: Center(
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(title, style: titleStyle, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subtitle, style: subtitleStyle, textAlign: TextAlign.center),
              if (action case final a?) ...[const SizedBox(height: 24), a],
            ],
          ),
        ),
      ),
    );
  }
}
