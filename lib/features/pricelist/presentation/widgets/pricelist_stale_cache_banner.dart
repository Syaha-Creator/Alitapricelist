import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Stale-cache indicator banner — same warning-tinted `Material` treatment
/// and literal copy as the legacy app's stale-cache banner in
/// `product_list_page.dart`.
class PricelistStaleCacheBanner extends StatelessWidget {
  const PricelistStaleCacheBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        key: const Key('pricelist_stale_cache_banner'),
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.history_edu_outlined, size: 18, color: AppColors.warning),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Menampilkan data terakhir yang tersimpan. Tarik untuk refresh agar harga '
                  'mengikuti server terbaru.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
