import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../logic/pricelist_browsing_provider.dart';
import '../../logic/pricelist_search_sort.dart';

/// 48x48 rounded-square sort trigger — same visual treatment as the legacy
/// app's `_SortButton`, with a small accent dot when a non-default sort is
/// active. Opens [PricelistSortSheet] on tap.
class PricelistSortButton extends ConsumerWidget {
  const PricelistSortButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(pricelistSortOptionProvider) != PricelistSortOption.nameAsc;

    return GestureDetector(
      key: const Key('pricelist_sort_button'),
      onTap: () => _showSortSheet(context),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 2)),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.sort_rounded,
                size: 22,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
            if (isActive)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => const PricelistSortSheet(),
    );
  }
}

/// Bottom sheet listing every [PricelistSortOption] — same visual treatment
/// as the legacy app's `SortBottomSheet` (36x36 icon chip, check on the
/// selected row).
class PricelistSortSheet extends ConsumerWidget {
  const PricelistSortSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(pricelistSortOptionProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Urutkan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          for (final option in PricelistSortOption.values)
            _SortOptionTile(
              option: option,
              isSelected: option == current,
              onTap: () {
                ref.read(pricelistSortOptionProvider.notifier).state = option;
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  const _SortOptionTile({required this.option, required this.isSelected, required this.onTap});

  final PricelistSortOption option;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon => switch (option) {
    PricelistSortOption.nameAsc => Icons.sort_by_alpha_rounded,
    PricelistSortOption.priceAsc => Icons.arrow_upward_rounded,
    PricelistSortOption.priceDesc => Icons.arrow_downward_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('pricelist_sort_option_${option.name}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _icon,
                size: 18,
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_rounded, size: 22, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
