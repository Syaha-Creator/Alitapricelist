import 'dart:typed_data';

import 'package:alita_pricelist/core/config/app_config.dart';
import 'package:alita_pricelist/core/network/api_client.dart';
import 'package:alita_pricelist/features/auth/data/local/session_local_store.dart';
import 'package:alita_pricelist/features/auth/data/local/token_storage.dart';
import 'package:alita_pricelist/features/auth/data/models/auth_session.dart';
import 'package:alita_pricelist/features/auth/data/services/auth_repository.dart';
import 'package:alita_pricelist/features/auth/data/services/firebase_anonymous_auth.dart';
import 'package:alita_pricelist/features/auth/logic/auth_repository_provider.dart';
import 'package:alita_pricelist/features/auth/logic/auth_status.dart';
import 'package:alita_pricelist/features/auth/logic/auth_status_provider.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class MockUserCredential extends Mock implements UserCredential {}

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

ProviderContainer _buildContainer({
  required HttpClientAdapter adapter,
  required MockFirebaseAuth mockFirebaseAuth,
  SessionLocalStore? sessionStore,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter;
  final apiClient = ApiClient(dio: dio);
  final repository = AuthRepository(
    apiClient: apiClient,
    sessionStore: sessionStore ?? SessionLocalStore(tokenStorage: FakeTokenStorage()),
  );

  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      firebaseAnonymousAuthProvider.overrideWithValue(FirebaseAnonymousAuth(auth: mockFirebaseAuth)),
    ],
  );
}

void main() {
  setUpAll(() async {
    await AppConfig.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('authStatusProvider', () {
    test('resolves to AuthUnauthenticated when there is no saved session', () async {
      final container = _buildContainer(
        adapter: _StubAdapter(statusCode: 200, body: '{}'),
        mockFirebaseAuth: MockFirebaseAuth(),
      );
      addTearDown(container.dispose);

      final status = await container.read(authStatusProvider.future);

      expect(status, isA<AuthUnauthenticated>());
    });

    test('resolves to AuthAuthenticated when a session was already saved', () async {
      final sessionStore = SessionLocalStore(tokenStorage: FakeTokenStorage());
      await sessionStore.save(const AuthSession(accessToken: 'tok', userId: 1, userName: 'Budi'));
      final container = _buildContainer(
        adapter: _StubAdapter(statusCode: 200, body: '{}'),
        mockFirebaseAuth: MockFirebaseAuth(),
        sessionStore: sessionStore,
      );
      addTearDown(container.dispose);

      final status = await container.read(authStatusProvider.future);

      expect(status, isA<AuthAuthenticated>());
      expect((status as AuthAuthenticated).session.userName, 'Budi');
    });

    test('login() success updates state to AuthAuthenticated and triggers Firebase anon sign-in', () async {
      final mockFirebaseAuth = MockFirebaseAuth();
      when(() => mockFirebaseAuth.currentUser).thenReturn(null);
      when(
        () => mockFirebaseAuth.signInAnonymously(),
      ).thenAnswer((_) async => MockUserCredential());
      final container = _buildContainer(
        adapter: _StubAdapter(statusCode: 200, body: '{"token":"tok-abc","user":{"id":1,"name":"Budi"}}'),
        mockFirebaseAuth: mockFirebaseAuth,
      );
      addTearDown(container.dispose);
      await container.read(authStatusProvider.future); // let build() settle first

      final result = await container.read(authStatusProvider.notifier).login(email: 'a@b.com', password: 'pw');

      expect(result.isSuccess, isTrue);
      expect(container.read(authStatusProvider).value, isA<AuthAuthenticated>());
      // Fire-and-forget: give the microtask queue a turn to run it.
      await Future<void>.delayed(Duration.zero);
      verify(() => mockFirebaseAuth.signInAnonymously()).called(1);
    });

    test('login() failure returns a Result.failure and leaves state unauthenticated', () async {
      final container = _buildContainer(
        adapter: _StubAdapter(statusCode: 401, body: '{}'),
        mockFirebaseAuth: MockFirebaseAuth(),
      );
      addTearDown(container.dispose);
      await container.read(authStatusProvider.future);

      final result = await container.read(authStatusProvider.notifier).login(email: 'a@b.com', password: 'wrong');

      expect(result.isFailure, isTrue);
      expect(container.read(authStatusProvider).value, isA<AuthUnauthenticated>());
    });

    test('logout() clears the session and sets state to AuthUnauthenticated', () async {
      final sessionStore = SessionLocalStore(tokenStorage: FakeTokenStorage());
      await sessionStore.save(const AuthSession(accessToken: 'tok', userId: 1));
      final container = _buildContainer(
        adapter: _StubAdapter(statusCode: 200, body: '{}'),
        mockFirebaseAuth: MockFirebaseAuth(),
        sessionStore: sessionStore,
      );
      addTearDown(container.dispose);
      await container.read(authStatusProvider.future);
      expect(container.read(authStatusProvider).value, isA<AuthAuthenticated>());

      await container.read(authStatusProvider.notifier).logout();

      expect(container.read(authStatusProvider).value, isA<AuthUnauthenticated>());
      final restored = await sessionStore.load();
      restored.fold(onSuccess: (session) => expect(session, isNull), onFailure: (_) => fail('expected cleared'));
    });
  });
}
