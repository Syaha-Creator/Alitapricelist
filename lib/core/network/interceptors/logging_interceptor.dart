import 'package:alita_pricelist/core/logging/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Query params whose value must never appear in a log line — the Alita
/// API sends the access token and app credentials as query parameters
/// (see `_AccessTokenQueryInterceptor` in `api_client.dart`), not headers,
/// so redacting only an `Authorization` header would miss them entirely.
const _sensitiveQueryParams = {'access_token', 'client_secret', 'client_id'};

/// Pure function, exposed for testing without needing to trigger
/// `kDebugMode`/`AppLogger` plumbing.
@visibleForTesting
String redactSensitiveQueryParams(Uri uri) {
  if (uri.queryParameters.isEmpty) return uri.toString();
  final redacted = {
    for (final entry in uri.queryParameters.entries)
      entry.key: _sensitiveQueryParams.contains(entry.key) ? 'REDACTED' : entry.value,
  };
  return uri.replace(queryParameters: redacted).toString();
}

/// Debug-only request/response logging. Deliberately a no-op in release
/// builds so we never leak tokens/payloads in production logs.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.debug('--> ${options.method} ${redactSensitiveQueryParams(options.uri)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.debug(
        '<-- ${response.statusCode} ${redactSensitiveQueryParams(response.requestOptions.uri)}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.debug(
        '<-- ERROR ${err.response?.statusCode} '
        '${redactSensitiveQueryParams(err.requestOptions.uri)}: ${err.message}',
      );
    }
    handler.next(err);
  }
}
