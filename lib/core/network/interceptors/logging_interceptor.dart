import 'package:alita_pricelist/core/logging/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug-only request/response logging. Deliberately a no-op in release
/// builds so we never leak tokens/payloads in production logs.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.debug('--> ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.debug(
        '<-- ${response.statusCode} ${response.requestOptions.uri}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.debug(
        '<-- ERROR ${err.response?.statusCode} ${err.requestOptions.uri}: ${err.message}',
      );
    }
    handler.next(err);
  }
}
