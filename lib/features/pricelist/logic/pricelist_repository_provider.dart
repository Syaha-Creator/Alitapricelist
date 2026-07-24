import 'package:alita_pricelist/core/network/api_client_provider.dart';
import 'package:alita_pricelist/features/pricelist/data/local/pricelist_cache_store.dart';
import 'package:alita_pricelist/features/pricelist/data/services/pricelist_repository.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_cache_directory_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manual (non-generated) Riverpod providers — see the note in
/// `bootstrap_provider.dart` for why `riverpod_generator` isn't used here.
final pricelistCacheStoreProvider = Provider<PricelistCacheStore>((ref) {
  return PricelistCacheStore(directory: ref.watch(pricelistCacheDirectoryProvider));
});

final pricelistRepositoryProvider = Provider<PricelistRepository>((ref) {
  return PricelistRepository(
    apiClient: ref.watch(apiClientProvider),
    cacheStore: ref.watch(pricelistCacheStoreProvider),
  );
});
