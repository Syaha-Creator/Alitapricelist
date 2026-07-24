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

PricelistRepository _buildRepository(HttpClientAdapter adapter, Directory cacheDir) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter;
  return PricelistRepository(
    apiClient: ApiClient(dio: dio),
    cacheStore: PricelistCacheStore(directory: cacheDir),
  );
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pl_repo_master_data_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PricelistRepository.getAreas', () {
    test('parses a successful response into a list of Area', () async {
      final repository = _buildRepository(
        _StubAdapter(statusCode: 200, body: '{"data":[{"name":"Nasional"},{"area":"Jawa Barat"}]}'),
        tempDir,
      );

      final result = await repository.getAreas();

      result.fold(
        onSuccess: (areas) => expect(areas.map((a) => a.name), ['Nasional', 'Jawa Barat']),
        onFailure: (error) => fail('expected success, got $error'),
      );
    });

    test('a network error maps to NetworkException, not a raw exception', () async {
      final repository = _buildRepository(_ConnectionErrorAdapter(), tempDir);

      final result = await repository.getAreas();

      result.fold(
        onSuccess: (_) => fail('expected failure'),
        onFailure: (error) => expect(error, isA<NetworkException>()),
      );
    });

    test('a 401 response maps to UnauthorizedException', () async {
      final repository = _buildRepository(_StubAdapter(statusCode: 401, body: '{}'), tempDir);

      final result = await repository.getAreas();

      result.fold(
        onSuccess: (_) => fail('expected failure'),
        onFailure: (error) => expect(error, isA<UnauthorizedException>()),
      );
    });

    test('a malformed body maps to ParsingException', () async {
      final repository = _buildRepository(
        _StubAdapter(statusCode: 200, body: 'not json {{{'),
        tempDir,
      );

      final result = await repository.getAreas();

      result.fold(
        onSuccess: (_) => fail('expected failure'),
        onFailure: (error) => expect(error, isA<ParsingException>()),
      );
    });
  });

  group('PricelistRepository.getChannels', () {
    test('parses a successful response into a list of Channel', () async {
      final repository = _buildRepository(
        _StubAdapter(statusCode: 200, body: '{"data":[{"id":223,"channel":"Direct"}]}'),
        tempDir,
      );

      final result = await repository.getChannels();

      result.fold(
        onSuccess: (channels) {
          expect(channels, hasLength(1));
          expect(channels.first.id, 223);
          expect(channels.first.channel, 'Direct');
        },
        onFailure: (error) => fail('expected success, got $error'),
      );
    });
  });

  group('PricelistRepository.getBrands', () {
    test('parses a successful response into a list of Brand', () async {
      final repository = _buildRepository(
        _StubAdapter(
          statusCode: 200,
          body: '{"data":[{"id":622,"brand":"Comforta","pl_channel_id":223}]}',
        ),
        tempDir,
      );

      final result = await repository.getBrands();

      result.fold(
        onSuccess: (brands) {
          expect(brands, hasLength(1));
          expect(brands.first.brand, 'Comforta');
          expect(brands.first.plChannelId, 223);
        },
        onFailure: (error) => fail('expected success, got $error'),
      );
    });
  });
}
