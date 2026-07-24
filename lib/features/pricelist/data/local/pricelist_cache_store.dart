import 'dart:convert';
import 'dart:io';

import 'package:alita_pricelist/core/error/app_exception.dart';
import 'package:alita_pricelist/core/error/result.dart';
import 'package:alita_pricelist/core/logging/app_logger.dart';
import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';

/// A previously-saved `filtered_pl` snapshot, plus when it was written —
/// the caller (`PricelistRepository`) uses [cachedAt] to show "data dari
/// cache jam ..." when this is served as a stale fallback.
class PricelistCachedSnapshot {
  const PricelistCachedSnapshot({required this.items, required this.cachedAt});

  final List<PricelistItem> items;
  final DateTime cachedAt;
}

/// File-based (not SharedPreferences/Hive — see SPEC.md §4) cache of the
/// last successful `filtered_pl` result per area/channel/brand combination.
///
/// Deliberately takes the storage [directory] as a constructor parameter
/// instead of resolving `path_provider`'s
/// `getApplicationSupportDirectory()` itself — that keeps this class
/// trivially testable with a plain temp directory and keeps the one
/// platform-channel call in a single place (the provider that constructs
/// this in production).
///
/// [load] never throws: a missing or corrupt cache file is treated as "no
/// cache" (`null`), never a [Result.failure] — a cache miss is an expected,
/// normal outcome, not an error (same reasoning as
/// `SessionLocalStore.load()`).
class PricelistCacheStore {
  PricelistCacheStore({required Directory directory}) : _directory = directory;

  final Directory _directory;

  /// A stable, filesystem-safe key for a given area/channel/brand
  /// combination — case/whitespace-insensitive so "Nasional" and
  /// " nasional " share a cache entry (mirrors the legacy app's
  /// `pricelistCacheStorageKey`).
  String keyFor({required String area, required String channel, required String brand}) {
    final normalized =
        '${area.trim().toLowerCase()}|${channel.trim().toLowerCase()}|${brand.trim().toLowerCase()}';
    return normalized.hashCode.toUnsigned(32).toRadixString(16);
  }

  Future<Result<void>> save(String key, List<PricelistItem> items) async {
    try {
      final file = _fileFor(key);
      await file.create(recursive: true);
      final payload = {
        'cachedAt': DateTime.now().toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(payload));
      return const Result.success(null);
    } catch (error, stackTrace) {
      AppLogger.recordError(error, stackTrace, reason: 'PricelistCacheStore.save failed');
      return Result.failure(CacheException(cause: error, stackTrace: stackTrace));
    }
  }

  Future<PricelistCachedSnapshot?> load(String key) async {
    try {
      final file = _fileFor(key);
      if (!await file.exists()) return null;

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return null;

      final rawItems = decoded['items'];
      if (rawItems is! List) return null;

      final items = rawItems
          .whereType<Map>()
          .map((row) => PricelistItem.fromJsonCache(Map<String, dynamic>.from(row)))
          .toList();
      final cachedAt = DateTime.tryParse(decoded['cachedAt']?.toString() ?? '') ?? DateTime.now();

      return PricelistCachedSnapshot(items: items, cachedAt: cachedAt);
    } catch (error, stackTrace) {
      AppLogger.recordError(
        error,
        stackTrace,
        reason: 'PricelistCacheStore.load failed — treating as no cache available',
      );
      return null;
    }
  }

  File _fileFor(String key) => File('${_directory.path}/pl_cache_$key.json');
}
