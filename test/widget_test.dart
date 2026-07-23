// Skeleton smoke test: verifies the app boots, bootstrap resolves, and the
// router redirects past the splash screen without throwing. Since step 2
// (auth module) landed, an unauthenticated user lands on the login screen
// rather than home — that's the router guard working as intended. Real
// feature widget tests are added per-step as features land (see SPEC.md
// §7).

import 'package:alita_pricelist/core/config/app_config.dart';
import 'package:alita_pricelist/core/network/api_client.dart';
import 'package:alita_pricelist/core/network/api_client_provider.dart';
import 'package:alita_pricelist/features/auth/data/local/session_local_store.dart';
import 'package:alita_pricelist/features/auth/data/local/token_storage.dart';
import 'package:alita_pricelist/features/auth/data/services/auth_repository.dart';
import 'package:alita_pricelist/features/auth/logic/auth_repository_provider.dart';
import 'package:alita_pricelist/features/auth/presentation/login_page.dart';
import 'package:alita_pricelist/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory fake so this smoke test never touches the platform
/// keychain/keystore (which has no mock handler registered in plain
/// `flutter_test` and would otherwise hang restoreSession() forever).
class _FakeTokenStorage implements TokenStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

void main() {
  testWidgets('app boots and redirects past splash to the login screen when unauthenticated', (
    tester,
  ) async {
    await AppConfig.load();
    SharedPreferences.setMockInitialValues({});
    final apiClient = ApiClient();
    final authRepository = AuthRepository(
      apiClient: apiClient,
      sessionStore: SessionLocalStore(tokenStorage: _FakeTokenStorage()),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
        child: const AlitaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
