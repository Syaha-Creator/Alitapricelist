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

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pl_repo_lookup_test_');
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
      cacheStore: PricelistCacheStore(directory: tempDir),
    );
  }

  group('PricelistRepository.getItemLookups', () {
    test('parses a successful {"status":"success","result":[...]} response', () async {
      final repository = buildRepository(
        _StubAdapter(
          statusCode: 200,
          body: '{"status":"success","result":[{"tipe":"Kasur","item_num":"KSR-001"}]}',
        ),
      );

      final result = await repository.getItemLookups();

      result.fold(
        onSuccess: (entries) {
          expect(entries, hasLength(1));
          expect(entries.first.tipe, 'Kasur');
          expect(entries.first.itemNum, 'KSR-001');
        },
        onFailure: (error) => fail('expected success, got $error'),
      );
    });

    test('a status != success response yields an empty list, not a failure', () async {
      final repository = buildRepository(_StubAdapter(statusCode: 200, body: '{"status":"error"}'));

      final result = await repository.getItemLookups();

      result.fold(
        onSuccess: (entries) => expect(entries, isEmpty),
        onFailure: (error) => fail('expected success(empty), got $error'),
      );
    });

    test('a network/parsing failure still maps to an AppException', () async {
      final repository = buildRepository(_StubAdapter(statusCode: 200, body: 'not json {{{'));

      final result = await repository.getItemLookups();

      result.fold(
        onSuccess: (_) => fail('expected failure'),
        onFailure: (error) => expect(error, isA<ParsingException>()),
      );
    });
  });

  group('PricelistRepository.getAccessories', () {
    test('parses a successful {"status":"success","result":[...]} response', () async {
      final repository = buildRepository(
        _StubAdapter(
          statusCode: 200,
          body:
              '{"status":"success","result":[{"tipe":"Bantal","item_num":"ACC-001","pricelist":150000}]}',
        ),
      );

      final result = await repository.getAccessories();

      result.fold(
        onSuccess: (accessories) {
          expect(accessories, hasLength(1));
          expect(accessories.first.tipe, 'Bantal');
          expect(accessories.first.pricelist, 150000.0);
        },
        onFailure: (error) => fail('expected success, got $error'),
      );
    });
  });
}
