import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../logic/pricelist_browsing_provider.dart';

/// Pill-shaped search field — same visual treatment as the legacy app's
/// `SearchBarWidget` (56px tall, 28-radius pill, soft shadow), wired to
/// [pricelistSearchQueryProvider].
class PricelistSearchBar extends ConsumerWidget {
  const PricelistSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      key: const Key('pricelist_search_field_container'),
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: TextField(
        key: const Key('pricelist_search_field'),
        onChanged: (value) => ref.read(pricelistSearchQueryProvider.notifier).state = value,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          hintStyle: const TextStyle(color: AppColors.textTertiary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
