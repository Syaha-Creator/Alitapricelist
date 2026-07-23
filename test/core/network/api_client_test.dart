import 'dart:typed_data';

import 'package:alita_pricelist/core/error/app_exception.dart';
import 'package:alita_pricelist/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures the [RequestOptions] Dio ends up sending, without making any
/// real network call — used to verify what the auth interceptor attaches
/// to the request (a query param), never what it attaches as a header.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({this.statusCode = 200});

  final int statusCode;
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Returns a 200 with a body that is not valid JSON, so Dio's own response
/// transformer fails before ApiClient's `parser` callback ever runs.
class _InvalidJsonAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      'not valid json {{{',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ApiClient access token wiring', () {
    test('adds access_token as a query parameter when a token is available', () async {
      final adapter = _CapturingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter;
      final client = ApiClient(dio: dio, accessTokenProvider: () async => 'secret-token-123');

      await client.get<Map<dynamic, dynamic>>('/orders', parser: (json) => json as Map<dynamic, dynamic>);

      expect(adapter.lastOptions?.queryParameters['access_token'], 'secret-token-123');
      expect(adapter.lastOptions?.headers.containsKey('Authorization'), isFalse);
    });

    test('does not add access_token when no provider is configured', () async {
      final adapter = _CapturingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter;
      final client = ApiClient(dio: dio);

      await client.get<Map<dynamic, dynamic>>('/orders', parser: (json) => json as Map<dynamic, dynamic>);

      expect(adapter.lastOptions?.queryParameters.containsKey('access_token'), isFalse);
    });

    test('does not add access_token when the provider resolves to null', () async {
      final adapter = _CapturingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter;
      final client = ApiClient(dio: dio, accessTokenProvider: () async => null);

      await client.get<Map<dynamic, dynamic>>('/orders', parser: (json) => json as Map<dynamic, dynamic>);

      expect(adapter.lastOptions?.queryParameters.containsKey('access_token'), isFalse);
    });

    test('a syntactically invalid JSON body maps to ParsingException', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = _InvalidJsonAdapter();
      final client = ApiClient(dio: dio);

      final result = await client.get<Map<dynamic, dynamic>>(
        '/orders',
        parser: (json) => json as Map<dynamic, dynamic>,
      );

      expect(result.isFailure, isTrue);
      result.fold(
        onSuccess: (_) => fail('expected failure'),
        onFailure: (error) => expect(error, isA<ParsingException>()),
      );
    });

    test('attachAuth wires a token provider in after construction', () async {
      final adapter = _CapturingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter;
      final client = ApiClient(dio: dio);

      client.attachAuth(accessTokenProvider: () async => 'attached-later');
      await client.get<Map<dynamic, dynamic>>('/orders', parser: (json) => json as Map<dynamic, dynamic>);

      expect(adapter.lastOptions?.queryParameters['access_token'], 'attached-later');
    });

    test('attachAuth wires onUnauthorized so it fires on a 401 response', () async {
      final adapter = _CapturingAdapter(statusCode: 401);
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter;
      final client = ApiClient(dio: dio);
      var unauthorizedCalls = 0;
      client.attachAuth(onUnauthorized: () => unauthorizedCalls++);

      final result = await client.get<Map<dynamic, dynamic>>(
        '/orders',
        parser: (json) => json as Map<dynamic, dynamic>,
      );

      expect(result.isFailure, isTrue);
      expect(unauthorizedCalls, 1);
    });

    test('preserves caller-supplied query parameters alongside access_token', () async {
      final adapter = _CapturingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter;
      final client = ApiClient(dio: dio, accessTokenProvider: () async => 'secret-token-123');

      await client.get<Map<dynamic, dynamic>>(
        '/sign_in',
        parser: (json) => json as Map<dynamic, dynamic>,
        queryParameters: {'client_id': 'cid', 'client_secret': 'csecret'},
      );

      expect(adapter.lastOptions?.queryParameters['access_token'], 'secret-token-123');
      expect(adapter.lastOptions?.queryParameters['client_id'], 'cid');
      expect(adapter.lastOptions?.queryParameters['client_secret'], 'csecret');
    });
  });
}
