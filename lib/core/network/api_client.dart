import 'dart:io';

import 'package:alita_pricelist/core/config/app_config.dart';
import 'package:alita_pricelist/core/error/app_exception.dart';
import 'package:alita_pricelist/core/error/result.dart';
import 'package:alita_pricelist/core/logging/app_logger.dart';
import 'package:alita_pricelist/core/network/interceptors/logging_interceptor.dart';
import 'package:alita_pricelist/core/network/interceptors/retry_interceptor.dart';
import 'package:dio/dio.dart';

/// Injected by the auth feature so [ApiClient] can attach the current
/// access token without depending on the auth module directly (avoids a
/// core -> feature dependency cycle).
typedef AccessTokenProvider = Future<String?> Function();

/// Called when the API responds 401/403, so the auth module can react
/// (clear session, force logout) without [ApiClient] knowing about it.
typedef UnauthorizedCallback = void Function();

/// Thin wrapper around [Dio] that is the *only* way feature code talks to
/// the network.
///
/// Every call returns a [Result] — callers never see a [DioException] or
/// any other raw exception. This is what makes the "UI never receives a
/// raw exception" guardrail structurally true rather than a convention that
/// can be forgotten.
class ApiClient {
  ApiClient({Dio? dio, AccessTokenProvider? accessTokenProvider, UnauthorizedCallback? onUnauthorized})
    : _accessTokenProvider = accessTokenProvider,
      _onUnauthorized = onUnauthorized,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: AppConfig.apiTimeout,
              receiveTimeout: AppConfig.apiTimeout,
            ),
          ) {
    // Reads `_accessTokenProvider`/`_onUnauthorized` through instance
    // methods (not captured values) so [attachAuth] can wire the auth
    // module in *after* construction without recreating the interceptor —
    // callers that only build ApiClient (e.g. in tests) never need to know
    // about auth at all.
    _dio.interceptors.addAll([
      _AccessTokenQueryInterceptor(getToken: _getAccessToken),
      RetryInterceptor(dio: _dio),
      LoggingInterceptor(),
    ]);
  }

  final Dio _dio;
  AccessTokenProvider? _accessTokenProvider;
  UnauthorizedCallback? _onUnauthorized;

  Future<String?> _getAccessToken() => _accessTokenProvider?.call() ?? Future<String?>.value();

  /// Wires the auth module into an already-constructed [ApiClient].
  ///
  /// This exists so [ApiClient] can be built with no knowledge of auth
  /// (avoiding a core -> feature dependency), while the auth module still
  /// only has to call one method instead of the network layer being
  /// rebuilt around it.
  void attachAuth({AccessTokenProvider? accessTokenProvider, UnauthorizedCallback? onUnauthorized}) {
    _accessTokenProvider = accessTokenProvider;
    _onUnauthorized = onUnauthorized;
  }

  Future<Result<T>> get<T>(
    String path, {
    required T Function(dynamic json) parser,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request<T>(
      parser: parser,
      request: () => _dio.get<dynamic>(path, queryParameters: queryParameters),
    );
  }

  Future<Result<T>> post<T>(
    String path, {
    required T Function(dynamic json) parser,
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request<T>(
      parser: parser,
      request: () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<Result<T>> put<T>(
    String path, {
    required T Function(dynamic json) parser,
    Object? data,
  }) {
    return _request<T>(
      parser: parser,
      request: () => _dio.put<dynamic>(path, data: data),
    );
  }

  Future<Result<T>> delete<T>(
    String path, {
    required T Function(dynamic json) parser,
    Object? data,
  }) {
    return _request<T>(
      parser: parser,
      request: () => _dio.delete<dynamic>(path, data: data),
    );
  }

  Future<Result<T>> _request<T>({
    required Future<Response<dynamic>> Function() request,
    required T Function(dynamic json) parser,
  }) async {
    try {
      final response = await request();
      try {
        return Result.success(parser(response.data));
      } catch (error, stackTrace) {
        AppLogger.recordError(
          error,
          stackTrace,
          reason: 'Failed to parse response for ${response.requestOptions.path}',
        );
        return Result.failure(
          ParsingException(cause: error, stackTrace: stackTrace),
        );
      }
    } on DioException catch (error, stackTrace) {
      return Result.failure(_mapDioException(error, stackTrace));
    } catch (error, stackTrace) {
      AppLogger.recordError(error, stackTrace, reason: 'Unhandled ApiClient error');
      return Result.failure(
        UnknownAppException(cause: error, stackTrace: stackTrace),
      );
    }
  }

  AppException _mapDioException(DioException error, StackTrace stackTrace) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutAppException(cause: error, stackTrace: stackTrace);
      case DioExceptionType.connectionError:
        return NetworkException(cause: error, stackTrace: stackTrace);
      case DioExceptionType.badResponse:
        return _mapBadResponse(error, stackTrace);
      case DioExceptionType.cancel:
        return UnknownAppException(
          message: 'Permintaan dibatalkan.',
          cause: error,
          stackTrace: stackTrace,
        );
      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Koneksi tidak aman terdeteksi.',
          cause: error,
          stackTrace: stackTrace,
        );
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return NetworkException(cause: error, stackTrace: stackTrace);
        }
        // A syntactically-broken body (e.g. non-JSON) fails inside Dio's
        // own response transformer, before our `parser` callback ever
        // runs — that still has to surface as ParsingException, not an
        // opaque "unknown" error.
        if (error.error is FormatException) {
          return ParsingException(cause: error, stackTrace: stackTrace);
        }
        return UnknownAppException(cause: error, stackTrace: stackTrace);
      // Explicit default instead of an exhaustive switch: newer Dio
      // releases occasionally add DioExceptionType values (e.g.
      // transformTimeout); falling back to UnknownAppException here keeps
      // this compiling across Dio versions instead of crashing on an
      // "unhandled case" at runtime.
      default:
        return UnknownAppException(cause: error, stackTrace: stackTrace);
    }
  }

  AppException _mapBadResponse(DioException error, StackTrace stackTrace) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      _onUnauthorized?.call();
      return UnauthorizedException(cause: error, stackTrace: stackTrace);
    }
    if (statusCode != null && statusCode >= 500) {
      return ServerException(
        statusCode: statusCode,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    final data = error.response?.data;
    final message = data is Map && data['message'] is String
        ? data['message'] as String
        : 'Permintaan tidak valid.';
    return BadRequestException(
      message: message,
      cause: error,
      stackTrace: stackTrace,
    );
  }
}

/// The Alita REST API does not use `Authorization: Bearer` — every
/// authenticated call sends the token as an `access_token` query
/// parameter instead (verified against the legacy app; see
/// `tasks/plan.md`). `client_id`/`client_secret` are deliberately *not*
/// added here: they're only required by a handful of endpoints (e.g.
/// `/sign_in`) and are passed explicitly by the caller via
/// `queryParameters`, so this interceptor doesn't need to know about them.
class _AccessTokenQueryInterceptor extends Interceptor {
  _AccessTokenQueryInterceptor({required AccessTokenProvider getToken}) : _getToken = getToken;

  final AccessTokenProvider _getToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      options.queryParameters = {...options.queryParameters, 'access_token': token};
    }
    handler.next(options);
  }
}
