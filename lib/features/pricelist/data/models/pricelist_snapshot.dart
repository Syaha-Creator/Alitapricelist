import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';

/// Result of [PricelistRepository.getFilteredPricelist] — a plain value
/// object (not Freezed; nothing here needs `copyWith`/pattern-matching) that
/// tells the UI not just what to show, but whether it's a live result or a
/// stale local fallback (SPEC.md §5 point 2).
class PricelistSnapshot {
  const PricelistSnapshot({
    required this.items,
    required this.isFromStaleCache,
    required this.fetchedAt,
  });

  final List<PricelistItem> items;

  /// `true` when the network call failed and this came from
  /// [PricelistCacheStore] instead. `false` means this is a live result
  /// (and the cache has just been refreshed with it).
  final bool isFromStaleCache;

  /// When this data was actually produced — `DateTime.now()` for a live
  /// result, or the cache file's own `cachedAt` when [isFromStaleCache].
  final DateTime fetchedAt;
}
