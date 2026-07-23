import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Single entry point for logging + crash reporting.
///
/// Nothing in the app should call `print`, `debugPrint`, or talk to
/// [FirebaseCrashlytics] directly — going through here means we can always
/// answer "where did this get logged" and keeps Crashlytics wiring in one
/// place, per the mandatory `runZonedGuarded` + Crashlytics guardrail.
class AppLogger {
  const AppLogger._();

  static bool _crashlyticsReady = false;

  static void markCrashlyticsReady(bool ready) => _crashlyticsReady = ready;

  static void debug(String message, {String name = 'alita'}) {
    if (kDebugMode) {
      developer.log(message, name: name);
    }
  }

  static void info(String message, {String name = 'alita'}) {
    developer.log(message, name: name, level: 800);
    if (_crashlyticsReady) {
      FirebaseCrashlytics.instance.log('[$name] $message');
    }
  }

  static void warning(
    String message, {
    String name = 'alita',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(message, name: name, level: 900, error: error, stackTrace: stackTrace);
    if (_crashlyticsReady) {
      FirebaseCrashlytics.instance.log('[$name][WARN] $message');
    }
  }

  /// Records a caught, non-fatal error. Use this from repository catch
  /// blocks before mapping to an [AppException] — never swallow silently.
  static void recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    developer.log(
      reason ?? 'Recorded error',
      name: 'alita.error',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
    if (_crashlyticsReady) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } else if (kDebugMode) {
      developer.log(
        'Crashlytics not ready yet — error only logged locally',
        name: 'alita.error',
      );
    }
  }
}
