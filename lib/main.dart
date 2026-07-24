import 'dart:async';

import 'package:alita_pricelist/core/config/app_config.dart';
import 'package:alita_pricelist/core/logging/app_logger.dart';
import 'package:alita_pricelist/core/router/app_router.dart';
import 'package:alita_pricelist/core/theme/app_theme.dart';
import 'package:alita_pricelist/core/widgets/bootstrap_error_page.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_cache_directory_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  // Everything below is wrapped in runZonedGuarded so that truly uncaught
  // errors (not just Flutter framework errors) are still reported instead
  // of silently crashing. This is the mandatory guardrail from SPEC.md §6.
  runZonedGuarded(bootstrap, (error, stackTrace) {
    // Last-resort handler for anything thrown outside the Flutter zone
    // (e.g. during the async gap before runApp, if something below still
    // manages to escape every other guard). This only logs — it does NOT
    // call runApp() — so `bootstrap` itself must never let an exception
    // reach here without having already called runApp() with an error UI.
    AppLogger.recordError(
      error,
      stackTrace,
      reason: 'runZonedGuarded root handler',
      fatal: true,
    );
  });
}

/// The actual boot sequence, extracted out of `main()` so it can be exercised
/// directly in tests (see `test/bootstrap_test.dart`).
///
/// [loadConfig] is injectable so tests can simulate `AppConfig.load()`
/// failing without needing a real `.env` file.
///
/// Guardrail: every failure in here MUST still result in `runApp()` being
/// called with *some* UI (an error screen, at minimum) — never leave the
/// zone's error handler as the only thing that ran, because that produces a
/// silent blank screen with no on-screen trace and, worse, no Crashlytics
/// trace either (Crashlytics may not even be initialized yet at this point).
@visibleForTesting
Future<void> bootstrap({Future<void> Function() loadConfig = AppConfig.load}) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await loadConfig();
  } catch (error, stackTrace) {
    AppLogger.recordError(
      error,
      stackTrace,
      reason: 'AppConfig.load failed',
      fatal: true,
    );
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BootstrapErrorPage(
          message:
              'Konfigurasi aplikasi (.env) tidak ditemukan atau tidak valid. '
              'Salin .env.example menjadi .env lalu jalankan ulang.',
        ),
      ),
    );
    return;
  }

  await _initFirebase();

  // Catches errors thrown during the Flutter framework's build/layout/
  // paint pipeline (e.g. a bad widget build).
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.recordError(
      details.exception,
      details.stack ?? StackTrace.current,
      reason: 'FlutterError.onError',
      fatal: true,
    );
  };

  // Catches errors that escape the Flutter framework entirely (e.g. in
  // a Future that nothing awaited/caught).
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.recordError(
      error,
      stackTrace,
      reason: 'PlatformDispatcher.onError',
      fatal: true,
    );
    return true;
  };

  // Resolved once, here, before `runApp` — same reasoning as `AppConfig.load()`
  // above: this is the one `path_provider` platform-channel call the whole
  // app needs, and doing it eagerly keeps every pricelist provider that
  // depends on it synchronous (see `pricelistCacheDirectoryProvider`).
  final cacheDirectory = await getApplicationSupportDirectory();

  runApp(
    ProviderScope(
      overrides: [pricelistCacheDirectoryProvider.overrideWithValue(cacheDirectory)],
      child: const AlitaApp(),
    ),
  );
}

Future<void> _initFirebase() async {
  if (!AppConfig.isCrashlyticsEnabled) return;
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    AppLogger.markCrashlyticsReady(true);
  } catch (error) {
    // Firebase project not linked yet (no google-services.json /
    // GoogleService-Info.plist / firebase_options.dart) — this is expected
    // until `flutterfire configure` is run against the real Firebase
    // project. The app must still boot; it just runs without crash
    // reporting until then.
    AppLogger.markCrashlyticsReady(false);
    if (kDebugMode) {
      debugPrint(
        'Firebase not configured yet — Crashlytics disabled for this run. '
        'Run `flutterfire configure` to link the existing project. '
        'Error: $error',
      );
    }
  }
}

class AlitaApp extends ConsumerWidget {
  const AlitaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Alita Pricelist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
