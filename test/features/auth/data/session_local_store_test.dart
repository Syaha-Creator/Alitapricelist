import 'package:alita_pricelist/features/auth/data/local/session_local_store.dart';
import 'package:alita_pricelist/features/auth/data/local/token_storage.dart';
import 'package:alita_pricelist/features/auth/data/models/auth_session.dart';
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

void main() {
  late FakeTokenStorage fakeTokenStorage;
  late SessionLocalStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeTokenStorage = FakeTokenStorage();
    store = SessionLocalStore(tokenStorage: fakeTokenStorage);
  });

  group('SessionLocalStore', () {
    test('load returns Success(null) when nothing was ever saved', () async {
      final result = await store.load();

      result.fold(
        onSuccess: (session) => expect(session, isNull),
        onFailure: (_) => fail('expected success'),
      );
    });

    test('save then load round-trips every field', () async {
      const session = AuthSession(
        accessToken: 'secret-token-123',
        userId: 42,
        userName: 'Budi',
        userEmail: 'budi@massindo.com',
        userImageUrl: 'https://example.com/avatar.png',
        areaId: 7,
        addressNumber: 'SC-001',
      );

      final saveResult = await store.save(session);
      expect(saveResult.isSuccess, isTrue);

      final loadResult = await store.load();
      loadResult.fold(
        onSuccess: (loaded) => expect(loaded, session),
        onFailure: (error) => fail('expected success, got $error'),
      );
    });

    test('save then load round-trips a null addressNumber', () async {
      const session = AuthSession(accessToken: 'token-no-address', userId: 1);

      await store.save(session);
      final loadResult = await store.load();

      loadResult.fold(
        onSuccess: (loaded) => expect(loaded?.addressNumber, isNull),
        onFailure: (error) => fail('expected success, got $error'),
      );
    });

    test('clear removes the token and all profile fields', () async {
      const session = AuthSession(accessToken: 'to-be-cleared', userId: 1);
      await store.save(session);

      final clearResult = await store.clear();
      expect(clearResult.isSuccess, isTrue);

      final loadResult = await store.load();
      loadResult.fold(
        onSuccess: (session) => expect(session, isNull),
        onFailure: (error) => fail('expected success, got $error'),
      );
    });

    test('the access token is only ever stored via TokenStorage, never SharedPreferences', () async {
      const session = AuthSession(accessToken: 'must-not-leak-into-prefs', userId: 1);
      await store.save(session);

      final prefs = await SharedPreferences.getInstance();
      final allPrefsValues = prefs.getKeys().map(prefs.get).toString();

      expect(allPrefsValues.contains('must-not-leak-into-prefs'), isFalse);
    });
  });
}
