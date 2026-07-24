import 'package:alita_pricelist/core/error/app_exception.dart';
import 'package:alita_pricelist/core/router/app_router.dart';
import 'package:alita_pricelist/core/theme/app_colors.dart';
import 'package:alita_pricelist/core/widgets/empty_state_view.dart';
import 'package:alita_pricelist/core/widgets/error_state_view.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_browsing_provider.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_filter_provider.dart';
import 'package:alita_pricelist/features/pricelist/presentation/widgets/pricelist_filter_header.dart';
import 'package:alita_pricelist/features/pricelist/presentation/widgets/pricelist_product_card.dart';
import 'package:alita_pricelist/features/pricelist/presentation/widgets/pricelist_search_bar.dart';
import 'package:alita_pricelist/features/pricelist/presentation/widgets/pricelist_sort_button.dart';
import 'package:alita_pricelist/features/pricelist/presentation/widgets/pricelist_stale_cache_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

/// Home page (SPEC.md §5 point 2 — there is no separate dashboard). Visual
/// layout mirrors the legacy app's `product_list_page.dart` 1:1 (pinned
/// search+sort row, Area→Channel→Brand filter pills opening a bottom-sheet
/// picker, 2-column masonry grid, stale-cache banner) — replicated on
/// purpose per the user's explicit request, not redesigned. The only
/// legacy elements intentionally omitted here are AppBar actions
/// (profile/toko-mode/favorites) and the cart FAB, since those features
/// don't exist yet in this rewrite (confirmed with the user to add them
/// back when each feature is actually built).
class PricelistHomePage extends ConsumerWidget {
  const PricelistHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Alita Pricelist')),
      body: const CustomScrollView(
        slivers: [
          SliverPersistentHeader(pinned: true, delegate: _SearchSortHeaderDelegate()),
          SliverToBoxAdapter(child: PricelistFilterHeader()),
          _PricelistBody(),
        ],
      ),
    );
  }
}

class _SearchSortHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SearchSortHeaderDelegate();

  static const double _height = 68;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: const Row(
        children: [
          Expanded(child: PricelistSearchBar()),
          SizedBox(width: 12),
          PricelistSortButton(),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}

/// Everything below the pinned header/filter row: depends on how much of
/// the Area→Channel→Brand filter is selected, and on the resulting network
/// call's state — kept as its own widget (rather than inline in `build`)
/// purely for readability.
class _PricelistBody extends ConsumerWidget {
  const _PricelistBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(pricelistFilterProvider);
    if (filter.area == null || filter.channel == null || filter.brand == null) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateView(
          key: Key('pricelist_select_filter_prompt'),
          icon: Icons.filter_list_rounded,
          title: 'Pilih Channel & Brand',
          subtitle: 'Silakan pilih channel dan brand terlebih dahulu\nuntuk melihat daftar produk.',
        ),
      );
    }

    final snapshotAsync = ref.watch(filteredPricelistSnapshotProvider);

    return snapshotAsync.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorStateView(
          key: const Key('pricelist_error_text'),
          title: 'Gagal memuat produk',
          message: _appExceptionMessage(error),
          icon: Icons.cloud_off_rounded,
          onRetry: () => ref.invalidate(filteredPricelistSnapshotProvider),
        ),
      ),
      data: (snapshot) {
        final items = ref.watch(filteredSortedPricelistItemsProvider);
        return SliverMainAxisGroup(
          slivers: [
            if (snapshot?.isFromStaleCache ?? false)
              const SliverToBoxAdapter(child: PricelistStaleCacheBanner()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '${items.length} produk ditemukan',
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ),
            ),
            if (items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  key: Key('pricelist_empty_text'),
                  icon: Icons.search_off_outlined,
                  title: 'Tidak ada produk ditemukan',
                  subtitle: 'Coba kata kunci atau kombinasi filter lain',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverMasonryGrid.count(
                  key: const Key('pricelist_grid'),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return PricelistProductCard(
                      key: ValueKey(item.name),
                      item: item,
                      onTap: () => context.push(AppRoutes.configurator, extra: item),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

String _appExceptionMessage(Object error) {
  return error is AppException ? error.message : 'Terjadi kesalahan yang tidak diketahui.';
}

String formatRupiah(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return 'Rp $buffer';
}
