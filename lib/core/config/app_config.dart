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

  static String get apiClientId => _require('API_CLIENT_ID');

  static String get apiClientSecret => _require('API_CLIENT_SECRET');

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
