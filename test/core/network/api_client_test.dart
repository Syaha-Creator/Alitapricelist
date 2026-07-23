import 'dart:typed_data';

import 'package:alita_pricelist/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures the [RequestOptions] Dio ends up sending, without making any
/// real network call — used to verify what the auth interceptor attaches
/// to the request (a query param), never what it attaches as a header.
class _CapturingAdapter implements HttpClientAdapter {
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
