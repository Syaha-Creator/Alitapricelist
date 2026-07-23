import 'dart:typed_data';

import 'package:alita_pricelist/core/config/app_config.dart';
import 'package:alita_pricelist/core/error/app_exception.dart';
import 'package:alita_pricelist/core/network/api_client.dart';
import 'package:alita_pricelist/features/auth/data/local/session_local_store.dart';
import 'package:alita_pricelist/features/auth/data/local/token_storage.dart';
import 'package:alita_pricelist/features/auth/data/services/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory fake so tests never touch the platform keychain/keystore.
class FakeTokenStorage implements TokenStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

/// Returns a canned response body/status for every request, without any
/// real network call.
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

/// Simulates a connection failure (no server reachable at all).
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

AuthRepository _buildRepository(HttpClientAdapter adapter, {SessionLocalStore? sessionStore}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter;
  final apiClient = ApiClient(dio: dio);
  return AuthRepository(apiClient: apiClient, sessionStore: sessionStore ?? SessionLocalStore(tokenStorage: FakeTokenStorage()));
}

void main() {
  setUpAll(() async {
    await AppConfig.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthRepository.login', () {
    test('a successful sign_in maps to an AuthSession and persists it', () async {
      final adapter = _StubAdapter(
        statusCode: 200,
        body: '{"token":"tok-abc","user":{"id":7,"email":"budi@massindo.com","name":"Budi","area_id":3}}',
      );
      final sessionStore = SessionLocalStore(tokenStorage: FakeTokenStorage());
      final repository = _buildRepository(adapter, sessionStore: sessionStore);

      final result = await repository.login(email: 'budi@massindo.com', password: 'secret');

      result.fold(
        onSuccess: (session) {
          expect(session.accessToken, 'tok-abc');
          expect(session.userId, 7);
          expect(session.userName, 'Budi');
          expect(session.areaId, 3);
        },
        onFailure: (error) => fail('expected success, got $error'),
      );

      final restored = await sessionStore.load();
      restored.fold(
        onSuccess: (session) => expect(session?.accessToken, 'tok-abc'),
        onFailure: (error) => fail('expected saved session, got $error'),
      );
    });

    test('sends client_id/client_secret as query parameters, never in the body', () async {
      final adapter = _StubAdapter(statusCode: 200, body: '{"token":"t","user":{"id":1}}');
      final repository = _buildRepository(adapter);

      await repository.login(email: 'a@b.com', password: 'pw');

      expect(adapter.lastOptions?.queryParameters['client_id'], AppConfig.apiClientId);
      expect(adapter.lastOptions?.queryParameters['client_secret'], AppConfig.apiClientSecret);
    });

    test('a 401 response maps to UnauthorizedException, not a raw exception', () async {
      final adapter = _StubAdapter(statusCode: 401, body: '{"error":"invalid credentials"}');
      final repository = _buildRepository(adapter);

      final result = await repository.login(email: 'a@b.com', password: 'wrong');

      result.fold(
        onSuccess: (_) => fail('expected failure'),
        onFailure: (error) => expect(error, isA<UnauthorizedException>()),
      );
    });

    test('a network/connection error maps to NetworkException, not a raw exception', () async {
      final repository = _buildRepository(_ConnectionErrorAdapter());

      final result = await repository.login(email: 'a@b.com', password: 'pw');

      result.fold(
        onSuccess: (_) => fail('expected failure'),
        onFailure: (error) => expect(error, isA<NetworkException>()),
      );
    });

    test('a response body that fails to parse maps to ParsingException, not a raw exception', () async {
      final adapter = _StubAdapter(statusCode: 200, body: 'not valid json at all {{{');
      final repository = _buildRepository(adapter);

      final result = await repository.login(email: 'a@b.com', password: 'pw');

      result.fold(
        onSuccess: (_) => fail('expected failure'),
        onFailure: (error) => expect(error, isA<ParsingException>()),
      );
    });

    test('does not persist a session when login fails', () async {
      final adapter = _StubAdapter(statusCode: 401, body: '{}');
      final sessionStore = SessionLocalStore(tokenStorage: FakeTokenStorage());
      final repository = _buildRepository(adapter, sessionStore: sessionStore);

      await repository.login(email: 'a@b.com', password: 'wrong');

      final restored = await sessionStore.load();
      restored.fold(onSuccess: (session) => expect(session, isNull), onFailure: (_) => fail('expected success(null)'));
    });
  });

  group('AuthRepository unauthorized wiring', () {
    test('a 401/403 on any later call clears the local session', () async {
      final loginAdapter = _StubAdapter(statusCode: 200, body: '{"token":"tok-abc","user":{"id":1}}');
      final sessionStore = SessionLocalStore(tokenStorage: FakeTokenStorage());
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = loginAdapter;
      final apiClient = ApiClient(dio: dio);
      final repository = AuthRepository(apiClient: apiClient, sessionStore: sessionStore);

      await repository.login(email: 'a@b.com', password: 'pw');
      var restored = await sessionStore.load();
      restored.fold(onSuccess: (session) => expect(session, isNotNull), onFailure: (_) => fail('expected a session'));

      // Simulate a later call to some other endpoint returning 401.
      dio.httpClientAdapter = _StubAdapter(statusCode: 401, body: '{}');
      await apiClient.get<dynamic>('/orders', parser: (json) => json);

      // Give the fire-and-forget storage clear a chance to run.
      await Future<void>.delayed(Duration.zero);

      restored = await sessionStore.load();
      restored.fold(onSuccess: (session) => expect(session, isNull), onFailure: (_) => fail('expected no session'));
    });
  });
}
