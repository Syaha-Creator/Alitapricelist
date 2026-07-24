import 'dart:io';
import 'dart:typed_data';

import 'package:alita_pricelist/core/network/api_client.dart';
import 'package:alita_pricelist/core/network/api_client_provider.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_browsing_provider.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_cache_directory_provider.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_filter_provider.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_master_data_provider.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_search_sort.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Routes each endpoint path to a canned response, so one adapter can stand
/// in for the whole master-data + filtered_pl round trip a full filter
/// selection triggers.
class _RoutedAdapter implements HttpClientAdapter {
  _RoutedAdapter(this.responsesByPathSuffix);

  final Map<String, String> responsesByPathSuffix;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    for (final entry in responsesByPathSuffix.entries) {
      if (options.path.endsWith(entry.key)) {
        return ResponseBody.fromString(
          entry.value,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
    }
    throw DioException(
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: 404, data: '{}'),
      type: DioExceptionType.badResponse,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pl_browsing_provider_test_');

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _RoutedAdapter({
        '/pl_channels': '{"data":[{"id":223,"channel":"Direct"}]}',
        '/pl_brands': '{"data":[{"id":622,"brand":"Comforta","pl_channel_id":223}]}',
        '/filtered_pl':
            '{"data":['
            '{"id":1,"kasur":"Comforta Elite","ukuran":"160x200","end_user_price":5000000},'
            '{"id":2,"kasur":"Comforta Elite","ukuran":"180x200","end_user_price":4500000},'
            '{"id":3,"kasur":"Simmons Beautyrest","ukuran":"160x200","end_user_price":8000000}'
            ']}',
      });

    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(ApiClient(dio: dio)),
        pricelistCacheDirectoryProvider.overrideWithValue(tempDir),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('with no filter selected, the browsing list is empty (no network call happens)', () async {
    final items = container.read(filteredSortedPricelistItemsProvider);
    expect(items, isEmpty);
  });

  test('brandsForSelectedChannelProvider is empty until a channel is selected', () async {
    await container.read(pricelistChannelsProvider.future);
    expect(container.read(brandsForSelectedChannelProvider), isEmpty);

    container.read(pricelistFilterProvider.notifier).selectChannel('Direct');
    // Let the brands FutureProvider resolve too.
    await container.read(pricelistBrandsProvider.future);

    final brands = container.read(brandsForSelectedChannelProvider);
    expect(brands.map((b) => b.brand), ['Comforta']);
  });

  test('selecting area+channel+brand fetches, groups by name, and exposes the result', () async {
    final notifier = container.read(pricelistFilterProvider.notifier);
    notifier.selectArea('Nasional');
    notifier.selectChannel('Direct');
    notifier.selectBrand('Comforta');

    // Drive the FutureProvider to completion.
    await container.read(filteredPricelistSnapshotProvider.future);

    final items = container.read(filteredSortedPricelistItemsProvider);
    // "Comforta Elite" appears twice in the raw response (2 sizes) and
    // must collapse into a single grouped card at the lower price.
    expect(items, hasLength(2));
    expect(items.map((i) => i.name), containsAll(['Comforta Elite', 'Simmons Beautyrest']));
    final comforta = items.firstWhere((i) => i.name == 'Comforta Elite');
    expect(comforta.price, 4500000.0);

    final snapshot = container.read(filteredPricelistSnapshotProvider).value;
    expect(snapshot?.isFromStaleCache, isFalse);
  });

  test('changing the search query narrows the already-fetched result', () async {
    final notifier = container.read(pricelistFilterProvider.notifier);
    notifier.selectArea('Nasional');
    notifier.selectChannel('Direct');
    notifier.selectBrand('Comforta');
    await container.read(filteredPricelistSnapshotProvider.future);

    container.read(pricelistSearchQueryProvider.notifier).state = 'simmons';

    final items = container.read(filteredSortedPricelistItemsProvider);
    expect(items.map((i) => i.name), ['Simmons Beautyrest']);
  });

  test('changing the sort option re-sorts the already-fetched result', () async {
    final notifier = container.read(pricelistFilterProvider.notifier);
    notifier.selectArea('Nasional');
    notifier.selectChannel('Direct');
    notifier.selectBrand('Comforta');
    await container.read(filteredPricelistSnapshotProvider.future);

    container.read(pricelistSortOptionProvider.notifier).state = PricelistSortOption.priceDesc;

    final items = container.read(filteredSortedPricelistItemsProvider);
    expect(items.first.name, 'Simmons Beautyrest');
  });
}
