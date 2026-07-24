import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/pricelist_item.dart';
import '../pricelist_home_page.dart' show formatRupiah;

/// Product card — same visual structure as the legacy app's `ProductCard`
/// (0.85 aspect-ratio image, rounded 16 corners, soft shadow, name →
/// category → price), minus the favorite button (Favorites isn't built
/// yet — Step 5 — confirmed with the user to omit it for now rather than
/// wire a non-functional icon).
class PricelistProductCard extends StatelessWidget {
  const PricelistProductCard({super.key, required this.item, this.onTap});

  final PricelistItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Lihat detail ${item.name}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: const [
              BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 0.85,
                  child: Container(
                    color: AppColors.surface,
                    child: item.imageUrl.startsWith('http')
                        ? Image.network(
                            item.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const _ImagePlaceholder(),
                          )
                        : const _ImagePlaceholder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.category.isEmpty ? 'Uncategorized' : item.category,
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatRupiah(item.price),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 48, color: AppColors.textTertiary),
    );
  }
}
