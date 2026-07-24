import 'package:alita_pricelist/features/pricelist/data/models/master_data.dart';
import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';
import 'package:alita_pricelist/features/pricelist/data/models/pricelist_snapshot.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_filter_provider.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_grouping.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_master_data_provider.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_repository_provider.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_search_sort.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The [Channel] object matching `pricelistFilterProvider`'s selected
/// channel *name* — brands are joined by `pl_channel_id`, which needs the
/// object, not just the name string the filter state stores.
final pricelistSelectedChannelProvider = Provider<Channel?>((ref) {
  final selectedName = ref.watch(pricelistFilterProvider).channel;
  if (selectedName == null) return null;
  final channels = ref.watch(pricelistChannelsProvider).valueOrNull ?? const [];
  for (final channel in channels) {
    if (channel.channel == selectedName) return channel;
  }
  return null;
});

final brandsForSelectedChannelProvider = Provider<List<Brand>>((ref) {
  final channel = ref.watch(pricelistSelectedChannelProvider);
  final brands = ref.watch(pricelistBrandsProvider).valueOrNull ?? const [];
  return brandsForChannel(brands: brands, channel: channel);
});

/// `null` (not loading/error) means the filter isn't fully selected yet —
/// there is nothing to fetch, and that's a normal, expected state, not an
/// error (same reasoning as `SessionLocalStore.load()` returning `null` for
/// "no session").
final filteredPricelistSnapshotProvider = FutureProvider<PricelistSnapshot?>((ref) async {
  final filter = ref.watch(pricelistFilterProvider);
  final area = filter.area;
  final channel = filter.channel;
  final brand = filter.brand;
  if (area == null || channel == null || brand == null) return null;

  final result = await ref
      .watch(pricelistRepositoryProvider)
      .getFilteredPricelist(area: area, channel: channel, brand: brand);
  return result.when(success: (snapshot) => snapshot, failure: (error) => throw error);
});

final pricelistSearchQueryProvider = StateProvider<String>((ref) => '');

final pricelistSortOptionProvider = StateProvider<PricelistSortOption>(
  (ref) => PricelistSortOption.nameAsc,
);

/// The pipeline the grid actually renders: raw rows → one card per product
/// name (`groupPricelistItemsByName`) → search + sort
/// (`filterAndSortPricelistItems`). Kept as a `Provider` (not folded into
/// [filteredPricelistSnapshotProvider]) so search/sort changes recompute
/// instantly without re-fetching the network/cache.
final filteredSortedPricelistItemsProvider = Provider<List<PricelistItem>>((ref) {
  final snapshot = ref.watch(filteredPricelistSnapshotProvider).valueOrNull;
  if (snapshot == null) return const [];

  final grouped = groupPricelistItemsByName(snapshot.items);
  final query = ref.watch(pricelistSearchQueryProvider);
  final sortOption = ref.watch(pricelistSortOptionProvider);
  return filterAndSortPricelistItems(items: grouped, searchQuery: query, sortOption: sortOption);
});
