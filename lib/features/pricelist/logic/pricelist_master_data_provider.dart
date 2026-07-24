import 'package:alita_pricelist/features/pricelist/data/models/master_data.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `Result.failure`'s [AppException] is rethrown here so each list surfaces
/// through Riverpod's own `AsyncValue.error` — consistent with how
/// `FutureProvider` is meant to represent failure, and how the UI already
/// handles `loading`/`data`/`error` for `bootstrapProvider`/
/// `authStatusProvider` (SPEC.md §6: no un-handled "in-between" state).
///
/// No file cache for these three (confirmed with the user — see
/// tasks/plan.md decision #1): every watch is a live network call.
final pricelistAreasProvider = FutureProvider<List<Area>>((ref) async {
  final result = await ref.watch(pricelistRepositoryProvider).getAreas();
  return result.when(success: (areas) => areas, failure: (error) => throw error);
});

final pricelistChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  final result = await ref.watch(pricelistRepositoryProvider).getChannels();
  return result.when(success: (channels) => channels, failure: (error) => throw error);
});

final pricelistBrandsProvider = FutureProvider<List<Brand>>((ref) async {
  final result = await ref.watch(pricelistRepositoryProvider).getBrands();
  return result.when(success: (brands) => brands, failure: (error) => throw error);
});
