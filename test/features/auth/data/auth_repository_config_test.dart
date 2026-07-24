// Regression test for a specific bug report:
//
// AuthRepository.login() read AppConfig.apiClientId/apiClientSecret directly
// inside the queryParameters map passed to ApiClient.post(...) — outside any
// try-catch. AppConfig's `_require()` throws a raw StateError when the
// underlying env var is missing (e.g. .env not updated after the
// platform-aware client_id/secret change). Because that throw happens
// during argument evaluation, it happens before ApiClient.post's own
// try-catch has a chance to run, so it was never mapped to a Result.failure
// — it escaped as a raw, unmapped exception.
//
// Deliberately does NOT call AppConfig.load() in this file, so
// AppConfig.apiClientId/apiClientSecret throw exactly like they would with a
// missing .env entry — this is a more deterministic repro than mutating the
// real .env file.
import 'dart:typed_data';

import 'package:alita_pricelist/core/network/api_client.dart';
import 'package:alita_pricelist/core/error/app_exception.dart';
import 'package:alita_pricelist/features/auth/data/local/session_local_store.dart';
import 'package:alita_pricelist/features/auth/data/local/token_storage.dart';
import 'package:alita_pricelist/features/auth/data/services/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeTokenStorage implements TokenStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

/// Never actually reached if the bug is present — the exception happens
/// before any request is sent — but kept so a future regression that only
/// half-fixes this (e.g. still crashes after sending) is still caught.
class _UnreachableAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fail('ApiClient should never send a request when apiClientId/apiClientSecret throw');
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('login() returns Result.failure (not a raw/unmapped exception) when '
      'AppConfig.apiClientId/apiClientSecret throw (missing .env entry)', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _UnreachableAdapter();
    final repository = AuthRepository(
      apiClient: ApiClient(dio: dio),
      sessionStore: SessionLocalStore(tokenStorage: FakeTokenStorage()),
    );

    // Must not throw — must resolve to a Result.failure.
    final result = await repository.login(email: 'a@b.com', password: 'pw');

    expect(result.isFailure, isTrue);
    result.fold(
      onSuccess: (_) => fail('expected failure'),
      onFailure: (error) {
        expect(error, isNot(isA<UnknownAppException>()));
        expect(error.message, isNotEmpty);
      },
    );
  });
}
