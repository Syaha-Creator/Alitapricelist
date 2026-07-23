import 'dart:async';
import 'dart:io';

import 'package:alita_pricelist/core/logging/app_logger.dart';
import 'package:dio/dio.dart';

/// Retries idempotent requests (GET) on connection/timeout errors and 5xx
/// responses, with capped exponential backoff.
///
/// Centralizing retry here means feature code never has to remember to
/// wrap a call in its own retry loop.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 500),
  });

  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;

  static const _retryCountKey = 'alita_retry_count';

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final isRetryable = _isRetryableError(err) && request.method == 'GET';

    final currentAttempt = (request.extra[_retryCountKey] as int?) ?? 0;

    if (!isRetryable || currentAttempt >= maxRetries) {
      return handler.next(err);
    }

    final nextAttempt = currentAttempt + 1;
    final delay = baseDelay * (1 << (nextAttempt - 1)); // 500ms, 1s, 2s...

    AppLogger.warning(
      'Retrying ${request.method} ${request.path} '
      '(attempt $nextAttempt/$maxRetries) after ${delay.inMilliseconds}ms',
    );

    await Future<void>.delayed(delay);

    try {
      request.extra[_retryCountKey] = nextAttempt;
      final response = await dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _isRetryableError(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    if (err.error is SocketException) return true;
    final statusCode = err.response?.statusCode;
    return statusCode != null && statusCode >= 500;
  }
}
