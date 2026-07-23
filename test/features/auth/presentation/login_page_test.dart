import 'dart:typed_data';

import 'package:alita_pricelist/core/config/app_config.dart';
import 'package:alita_pricelist/core/network/api_client.dart';
import 'package:alita_pricelist/features/auth/data/local/session_local_store.dart';
import 'package:alita_pricelist/features/auth/data/local/token_storage.dart';
import 'package:alita_pricelist/features/auth/data/services/auth_repository.dart';
import 'package:alita_pricelist/features/auth/data/services/firebase_anonymous_auth.dart';
import 'package:alita_pricelist/features/auth/logic/auth_repository_provider.dart';
import 'package:alita_pricelist/features/auth/presentation/login_page.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

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

Widget _buildApp({required int statusCode, required String body}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..httpClientAdapter = _StubAdapter(statusCode: statusCode, body: body);
  final apiClient = ApiClient(dio: dio);
  final repository = AuthRepository(
    apiClient: apiClient,
    sessionStore: SessionLocalStore(tokenStorage: FakeTokenStorage()),
  );
  final mockFirebaseAuth = MockFirebaseAuth();
  when(() => mockFirebaseAuth.currentUser).thenReturn(null);

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      firebaseAnonymousAuthProvider.overrideWithValue(FirebaseAnonymousAuth(auth: mockFirebaseAuth)),
    ],
    child: const MaterialApp(home: LoginPage()),
  );
}

void main() {
  setUpAll(() async {
    await AppConfig.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders email/password fields and a submit button', (tester) async {
    await tester.pumpWidget(_buildApp(statusCode: 200, body: '{}'));

    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.byKey(const Key('login_password_field')), findsOneWidget);
    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
  });

  testWidgets('shows validation errors when submitting empty fields', (tester) async {
    await tester.pumpWidget(_buildApp(statusCode: 200, body: '{}'));

    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });

  testWidgets('shows the mapped error message when login fails (401)', (tester) async {
    await tester.pumpWidget(_buildApp(statusCode: 401, body: '{}'));

    await tester.enterText(find.byKey(const Key('login_email_field')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('login_password_field')), 'wrong');
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_error_text')), findsOneWidget);
  });

  testWidgets('submitting valid credentials calls the notifier without throwing', (tester) async {
    await tester.pumpWidget(
      _buildApp(statusCode: 200, body: '{"token":"tok-abc","user":{"id":1,"name":"Budi"}}'),
    );

    await tester.enterText(find.byKey(const Key('login_email_field')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('login_password_field')), 'correct');
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_error_text')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
