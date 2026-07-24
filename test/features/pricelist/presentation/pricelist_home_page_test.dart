import 'dart:io';
import 'dart:typed_data';

import 'package:alita_pricelist/core/network/api_client.dart';
import 'package:alita_pricelist/core/network/api_client_provider.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_cache_directory_provider.dart';
import 'package:alita_pricelist/features/pricelist/presentation/pricelist_home_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Routes by path suffix so the same fake covers all five pricelist
/// endpoints without a real HTTP stack.
class _RoutedAdapter implements HttpClientAdapter {
  _RoutedAdapter(this.responsesByPathSuffix);

  final Map<String, String> responsesByPathSuffix;
  bool failFilteredPl = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (failFilteredPl && options.path.endsWith('/filtered_pl')) {
      throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
    }
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
  late _RoutedAdapter adapter;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pl_home_page_test_');
    adapter = _RoutedAdapter({
      '/pl_areas': '{"data":[{"name":"Nasional"}]}',
      '/pl_channels': '{"data":[{"id":223,"channel":"Direct"}]}',
      '/pl_brands': '{"data":[{"id":622,"brand":"Comforta","pl_channel_id":223}]}',
      '/filtered_pl':
          '{"data":[{"id":1,"kasur":"Comforta Elite","ukuran":"160x200","end_user_price":5000000}]}',
    });
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildApp() {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter;
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(ApiClient(dio: dio)),
        pricelistCacheDirectoryProvider.overrideWithValue(tempDir),
      ],
      child: const MaterialApp(home: PricelistHomePage()),
    );
  }

  /// Area/Channel selection only ever triggers network-only master-data
  /// providers (no file cache — see `pricelist_master_data_provider.dart`),
  /// so a plain `pumpAndSettle` is enough here.
  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Same reasoning as [tapBrandAndWaitForFetch] — used right after
  /// `pumpWidget` on the *second* app instance in the stale-cache test,
  /// where a stray pending real `Future` from the previous provider tree's
  /// teardown can otherwise make a plain `pumpAndSettle` hang.
  Future<void> pumpInitialFrame(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    });
  }

  /// Selecting the Brand is what completes the filter and triggers
  /// `getFilteredPricelist`, which does real file I/O against [tempDir]
  /// (the on-disk cache). `tester.pump`'s virtual clock never advances real
  /// `dart:io` callbacks, and the loading spinner it shows is a repeating
  /// animation that would make `pumpAndSettle` hang forever waiting for it
  /// to stop — so this bridges to the real event loop via `runAsync`
  /// instead of settling.
  /// The wait is generous enough to cover `RetryInterceptor`'s backoff
  /// (500ms + 1000ms for the two retries a connection error triggers — see
  /// `retry_interceptor.dart`) for the stale-cache scenario, not just a
  /// single successful fetch.
  Future<void> tapBrandAndWaitForFetch(WidgetTester tester, Finder finder) async {
    await tester.runAsync(() async {
      await tester.tap(finder);
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 2000));
      await tester.pump();
    });
  }

  testWidgets('shows only area chips before anything is selected', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pricelist_area_chips')), findsOneWidget);
    expect(find.byKey(const Key('pricelist_channel_chips')), findsNothing);
    expect(find.byKey(const Key('pricelist_brand_chips')), findsNothing);
    expect(find.byKey(const Key('pricelist_select_filter_prompt')), findsOneWidget);
  });

  testWidgets('selecting an area reveals the channel chips', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tapAndSettle(tester, find.text('Nasional'));

    expect(find.byKey(const Key('pricelist_channel_chips')), findsOneWidget);
    expect(find.byKey(const Key('pricelist_brand_chips')), findsNothing);
  });

  testWidgets('selecting area, channel, and brand shows the product grid', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tapAndSettle(tester, find.text('Nasional'));
    await tapAndSettle(tester, find.text('Direct'));
    await tapBrandAndWaitForFetch(tester, find.text('Comforta'));

    expect(find.byKey(const Key('pricelist_grid')), findsOneWidget);
    expect(find.text('Comforta Elite'), findsOneWidget);
    expect(find.byKey(const Key('pricelist_stale_cache_banner')), findsNothing);
  });

  testWidgets('shows the stale-cache banner when filtered_pl falls back to cache', (tester) async {
    // Warm the cache with a successful load first.
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Nasional'));
    await tapAndSettle(tester, find.text('Direct'));
    await tapBrandAndWaitForFetch(tester, find.text('Comforta'));
    expect(find.byKey(const Key('pricelist_grid')), findsOneWidget);

    // Rebuild with a fresh provider tree sharing the same (now-warm) cache
    // directory, but make filtered_pl fail this time.
    adapter.failFilteredPl = true;
    await tester.pumpWidget(buildApp());
    await pumpInitialFrame(tester);
    await tapAndSettle(tester, find.text('Nasional'));
    await tapAndSettle(tester, find.text('Direct'));
    await tapBrandAndWaitForFetch(tester, find.text('Comforta'));

    expect(find.byKey(const Key('pricelist_stale_cache_banner')), findsOneWidget);
    expect(find.text('Comforta Elite'), findsOneWidget);
  });

  testWidgets('typing in the search field narrows the grid', (tester) async {
    adapter.responsesByPathSuffix['/filtered_pl'] =
        '{"data":['
        '{"id":1,"kasur":"Comforta Elite","ukuran":"160x200","end_user_price":5000000},'
        '{"id":2,"kasur":"Simmons Beautyrest","ukuran":"160x200","end_user_price":8000000}'
        ']}';

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Nasional'));
    await tapAndSettle(tester, find.text('Direct'));
    await tapBrandAndWaitForFetch(tester, find.text('Comforta'));

    expect(find.text('Comforta Elite'), findsOneWidget);
    expect(find.text('Simmons Beautyrest'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pricelist_search_field')), 'simmons');
    await tester.pump();

    expect(find.text('Comforta Elite'), findsNothing);
    expect(find.text('Simmons Beautyrest'), findsOneWidget);
  });
}
