import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one-time-resolved directory `PricelistCacheStore` writes its files
/// into. Resolving `path_provider`'s `getApplicationSupportDirectory()` is
/// async, so — same pattern as `AppConfig.load()` in `main.dart` — it is
/// resolved once during `bootstrap()`, *before* `runApp`, and handed to
/// `ProviderScope` as an override. That keeps every other pricelist
/// provider synchronous and keeps this, the one real platform-channel call,
/// in a single place that's trivial to override in tests.
final pricelistCacheDirectoryProvider = Provider<Directory>((ref) {
  throw UnimplementedError(
    'pricelistCacheDirectoryProvider must be overridden (see main.dart bootstrap() '
    'and test setups) with a real resolved directory before use.',
  );
});
