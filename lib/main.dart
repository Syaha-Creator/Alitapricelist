import 'dart:async';

import 'package:alita_pricelist/core/config/app_config.dart';
import 'package:alita_pricelist/core/logging/app_logger.dart';
import 'package:alita_pricelist/core/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  // Everything below is wrapped in runZonedGuarded so that truly uncaught
  // errors (not just Flutter framework errors) are still reported instead
  // of silently crashing. This is the mandatory guardrail from SPEC.md §6.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await AppConfig.load();

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

      runApp(const ProviderScope(child: AlitaApp()));
    },
    (error, stackTrace) {
      // Last-resort handler for anything thrown outside the Flutter zone
      // (e.g. during the async gap before runApp).
      AppLogger.recordError(
        error,
        stackTrace,
        reason: 'runZonedGuarded root handler',
        fatal: true,
      );
    },
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
      routerConfig: router,
    );
  }
}
