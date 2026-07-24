import 'package:alita_pricelist/core/error/app_exception.dart';
import 'package:alita_pricelist/core/error/result.dart';
import 'package:alita_pricelist/core/network/api_client.dart';
import 'package:alita_pricelist/features/pricelist/data/local/pricelist_cache_store.dart';
import 'package:alita_pricelist/features/pricelist/data/models/accessory.dart';
import 'package:alita_pricelist/features/pricelist/data/models/item_lookup_entry.dart';
import 'package:alita_pricelist/features/pricelist/data/models/master_data.dart';
import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';
import 'package:alita_pricelist/features/pricelist/data/models/pricelist_snapshot.dart';

/// Talks to the Alita REST API's pricelist master-data endpoints
/// (`pl_areas`/`pl_channels`/`pl_brands`) and the pricelist browsing/
/// configurator endpoints (`filtered_pl`/`pl_lookup_item_nums`/
/// `pl_accessories`).
///
/// Same shape as `AuthRepository`: every method returns a [Result] — the
/// caller never sees a raw exception or a raw `Map`/`List` straight off the
/// wire (SPEC.md §6).
class PricelistRepository {
  PricelistRepository({required ApiClient apiClient, required PricelistCacheStore cacheStore})
    : _apiClient = apiClient,
      _cacheStore = cacheStore;

  final ApiClient _apiClient;
  final PricelistCacheStore _cacheStore;

  Future<Result<List<Area>>> getAreas() {
    return _apiClient.get<List<Area>>(
      '/pl_areas',
      parser: (json) =>
          parseMasterDataEnvelope(json, listKey: 'pl_areas').map(Area.fromJson).toList(),
    );
  }

  Future<Result<List<Channel>>> getChannels() {
    return _apiClient.get<List<Channel>>(
      '/pl_channels',
      parser: (json) =>
          parseMasterDataEnvelope(json, listKey: 'pl_channels').map(Channel.fromJson).toList(),
    );
  }

  Future<Result<List<Brand>>> getBrands() {
    return _apiClient.get<List<Brand>>(
      '/pl_brands',
      parser: (json) =>
          parseMasterDataEnvelope(json, listKey: 'pl_brands').map(Brand.fromJson).toList(),
    );
  }

  /// Fetches the pricelist rows for a fully-selected area/channel/brand
  /// combination.
  ///
  /// - Network succeeds → refresh the on-disk cache, return
  ///   `isFromStaleCache: false`.
  /// - Network fails with [NetworkException]/[TimeoutAppException]
  ///   (weak/no connectivity) → fall back to the last cached snapshot for
  ///   this exact combination, if any, with `isFromStaleCache: true`.
  /// - Any other failure (401, parsing, server error, ...) is a *real*
  ///   problem, not a connectivity blip — it is never masked by a silent
  ///   fallback to stale data, even if a cache happens to exist.
  Future<Result<PricelistSnapshot>> getFilteredPricelist({
    required String area,
    required String channel,
    required String brand,
  }) async {
    final cacheKey = _cacheStore.keyFor(area: area, channel: channel, brand: brand);
    final networkResult = await _apiClient.get<List<PricelistItem>>(
      '/rawdata_price_lists/filtered_pl',
      queryParameters: {'area': area, 'channel': channel, 'brand': brand},
      parser: (json) => parseFilteredPricelistEnvelope(json)
          .map((row) => PricelistItem.fromJson(row, fallbackChannel: channel, fallbackBrand: brand))
          .toList(),
    );

    switch (networkResult) {
      case Success<List<PricelistItem>>(data: final items):
        await _cacheStore.save(cacheKey, items);
        return Result.success(
          PricelistSnapshot(items: items, isFromStaleCache: false, fetchedAt: DateTime.now()),
        );
      case Failure<List<PricelistItem>>(error: final error):
        if (error is NetworkException || error is TimeoutAppException) {
          final cached = await _cacheStore.load(cacheKey);
          if (cached != null) {
            return Result.success(
              PricelistSnapshot(
                items: cached.items,
                isFromStaleCache: true,
                fetchedAt: cached.cachedAt,
              ),
            );
          }
        }
        return Result.failure(error);
    }
  }

  /// Not rendered by this step's browsing grid (used by the Step 4
  /// configurator) — provided now so nothing has to reach for a raw `Map`.
  Future<Result<List<ItemLookupEntry>>> getItemLookups() {
    return _apiClient.get<List<ItemLookupEntry>>(
      '/pl_lookup_item_nums',
      parser: (json) => parseLookupOrAccessoryEnvelope(json).map(ItemLookupEntry.fromJson).toList(),
    );
  }

  /// Same caveat as [getItemLookups].
  Future<Result<List<Accessory>>> getAccessories() {
    return _apiClient.get<List<Accessory>>(
      '/pl_accessories',
      parser: (json) => parseLookupOrAccessoryEnvelope(json).map(Accessory.fromJson).toList(),
    );
  }
}
