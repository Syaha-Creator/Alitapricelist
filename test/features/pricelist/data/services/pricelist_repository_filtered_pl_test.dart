import 'dart:io';
import 'dart:typed_data';

import 'package:alita_pricelist/core/error/app_exception.dart';
import 'package:alita_pricelist/core/network/api_client.dart';
import 'package:alita_pricelist/features/pricelist/data/local/pricelist_cache_store.dart';
import 'package:alita_pricelist/features/pricelist/data/services/pricelist_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    if (statusCode >= 400) {
      throw DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: statusCode, data: body),
        type: DioExceptionType.badResponse,
      );
    }
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _ConnectionErrorAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tempDir;
  late PricelistCacheStore cacheStore;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pl_repo_test_');
    cacheStore = PricelistCacheStore(directory: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  PricelistRepository buildRepository(HttpClientAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter;
    return PricelistRepository(
      apiClient: ApiClient(dio: dio),
      cacheStore: cacheStore,
    );
  }

  const filteredPlBody =
      '{"data":[{"id":1,"kasur":"Comforta Elite","ukuran":"160x200","end_user_price":5000000}]}';

  group('PricelistRepository.getFilteredPricelist', () {
    test(
      'a successful network call marks isFromStaleCache=false and refreshes the cache',
      () async {
        final repository = buildRepository(_StubAdapter(statusCode: 200, body: filteredPlBody));

        final result = await repository.getFilteredPricelist(
          area: 'Nasional',
          channel: 'Direct',
          brand: 'Comforta',
        );

        result.fold(
          onSuccess: (snapshot) {
            expect(snapshot.isFromStaleCache, isFalse);
            expect(snapshot.items, hasLength(1));
            expect(snapshot.items.first.name, 'Comforta Elite 160x200');
          },
          onFailure: (error) => fail('expected success, got $error'),
        );

        final key = cacheStore.keyFor(area: 'Nasional', channel: 'Direct', brand: 'Comforta');
        final cached = await cacheStore.load(key);
        expect(cached, isNotNull);
        expect(cached!.items, hasLength(1));
      },
    );

    test('sends area/channel/brand as query parameters', () async {
      final adapter = _StubAdapter(statusCode: 200, body: filteredPlBody);
      final repository = buildRepository(adapter);

      await repository.getFilteredPricelist(area: 'Nasional', channel: 'Direct', brand: 'Comforta');

      expect(adapter.lastOptions?.queryParameters['area'], 'Nasional');
      expect(adapter.lastOptions?.queryParameters['channel'], 'Direct');
      expect(adapter.lastOptions?.queryParameters['brand'], 'Comforta');
    });

    test(
      'a network failure with an existing cache falls back to it with isFromStaleCache=true',
      () async {
        final key = cacheStore.keyFor(area: 'Nasional', channel: 'Direct', brand: 'Comforta');
        final warmRepository = buildRepository(_StubAdapter(statusCode: 200, body: filteredPlBody));
        await warmRepository.getFilteredPricelist(
          area: 'Nasional',
          channel: 'Direct',
          brand: 'Comforta',
        );
        final cachedBefore = await cacheStore.load(key);
        expect(cachedBefore, isNotNull);

        final repository = buildRepository(_ConnectionErrorAdapter());

        final result = await repository.getFilteredPricelist(
          area: 'Nasional',
          channel: 'Direct',
          brand: 'Comforta',
        );

        result.fold(
          onSuccess: (snapshot) {
            expect(snapshot.isFromStaleCache, isTrue);
            expect(snapshot.items, hasLength(1));
          },
          onFailure: (error) => fail('expected a stale-cache success, got $error'),
        );
      },
    );

    test('a network failure with no cache propagates the original failure', () async {
      final repository = buildRepository(_ConnectionErrorAdapter());

      final result = await repository.getFilteredPricelist(
        area: 'Nasional',
        channel: 'Direct',
        brand: 'Comforta',
      );

      result.fold(
        onSuccess: (_) => fail('expected failure'),
        onFailure: (error) => expect(error, isA<NetworkException>()),
      );
    });

    test('a non-network error (401) does not fall back to cache even if one exists', () async {
      final key = cacheStore.keyFor(area: 'Nasional', channel: 'Direct', brand: 'Comforta');
      final warmRepository = buildRepository(_StubAdapter(statusCode: 200, body: filteredPlBody));
      await warmRepository.getFilteredPricelist(
        area: 'Nasional',
        channel: 'Direct',
        brand: 'Comforta',
      );
      expect(await cacheStore.load(key), isNotNull);

      final repository = buildRepository(_StubAdapter(statusCode: 401, body: '{}'));

      final result = await repository.getFilteredPricelist(
        area: 'Nasional',
        channel: 'Direct',
        brand: 'Comforta',
      );

      result.fold(
        onSuccess: (_) => fail('expected failure, not a silent fallback to stale cache'),
        onFailure: (error) => expect(error, isA<UnauthorizedException>()),
      );
    });

    test('a parsing error does not fall back to cache', () async {
      final key = cacheStore.keyFor(area: 'Nasional', channel: 'Direct', brand: 'Comforta');
      final warmRepository = buildRepository(_StubAdapter(statusCode: 200, body: filteredPlBody));
      await warmRepository.getFilteredPricelist(
        area: 'Nasional',
        channel: 'Direct',
        brand: 'Comforta',
      );
      expect(await cacheStore.load(key), isNotNull);

      final repository = buildRepository(_StubAdapter(statusCode: 200, body: 'not json {{{'));

      final result = await repository.getFilteredPricelist(
        area: 'Nasional',
        channel: 'Direct',
        brand: 'Comforta',
      );

      result.fold(
        onSuccess: (_) => fail('expected failure, not a silent fallback to stale cache'),
        onFailure: (error) => expect(error, isA<ParsingException>()),
      );
    });
  });
}
