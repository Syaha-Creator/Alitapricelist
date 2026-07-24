import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central place to read build-time configuration from `.env`.
///
/// No secret/URL should ever be hardcoded in feature code — everything goes
/// through here so environments (dev/staging/prod) can be swapped by
/// swapping the `.env` file, not by editing Dart source.
class AppConfig {
  const AppConfig._();

  static bool _loaded = false;

  /// Must be called once in `main()` before [instance] is used.
  static Future<void> load({String fileName = '.env'}) async {
    if (_loaded) return;
    await dotenv.load(fileName: fileName);
    _loaded = true;
  }

  static String get apiBaseUrl => _require('API_BASE_URL');

  /// The Alita REST API registers a *different* client_id/client_secret per
  /// platform (verified against the legacy app's `AppConfig` — not
  /// guessed), so these must branch on platform rather than read a single
  /// shared value: using the wrong pair makes `/sign_in` reject an
  /// otherwise-correct login with 401.
  static String get apiClientId =>
      Platform.isAndroid ? _require('API_CLIENT_ID_ANDROID') : _require('API_CLIENT_ID_IOS');

  static String get apiClientSecret =>
      Platform.isAndroid ? _require('API_CLIENT_SECRET_ANDROID') : _require('API_CLIENT_SECRET_IOS');

  /// Timeout in milliseconds for network requests. Defaults to 15s.
  static Duration get apiTimeout => Duration(
    milliseconds: int.tryParse(dotenv.env['API_TIMEOUT_MS'] ?? '') ?? 15000,
  );

  static bool get isCrashlyticsEnabled =>
      (dotenv.env['CRASHLYTICS_ENABLED'] ?? 'true').toLowerCase() == 'true';

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required env var "$key". Did you create a .env file from '
        '.env.example?',
      );
    }
    return value;
  }
}
