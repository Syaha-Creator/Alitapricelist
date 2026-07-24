import 'dart:async';

import 'package:alita_pricelist/core/config/app_config.dart';
import 'package:alita_pricelist/core/error/app_exception.dart';
import 'package:alita_pricelist/core/error/result.dart';
import 'package:alita_pricelist/core/logging/app_logger.dart';
import 'package:alita_pricelist/core/network/api_client.dart';
import 'package:alita_pricelist/features/auth/data/local/session_local_store.dart';
import 'package:alita_pricelist/features/auth/data/models/auth_session.dart';
import 'package:alita_pricelist/features/auth/data/models/login_response.dart';

/// Talks to the Alita REST API's `/sign_in` endpoint and turns a successful
/// login into a persisted [AuthSession].
///
/// This is the *only* place that knows about [LoginResponse] (the raw API
/// shape) — everything above this class only ever sees [AuthSession] or a
/// [Result] failure.
class AuthRepository {
  AuthRepository({required ApiClient apiClient, SessionLocalStore? sessionStore})
    : _apiClient = apiClient,
      _sessionStore = sessionStore ?? SessionLocalStore() {
    // Wire ourselves into the network layer: attach the current token to
    // every subsequent request, and react to 401/403 by dropping the
    // local session. See tasks/plan.md decision #5 — this must not call
    // back into ApiClient (no re-entrancy), only touch local state.
    _apiClient.attachAuth(
      accessTokenProvider: _readCurrentAccessToken,
      onUnauthorized: _handleUnauthorized,
    );
  }

  final ApiClient _apiClient;
  final SessionLocalStore _sessionStore;

  /// Set by [login] and [restoreSession] so [_readCurrentAccessToken] can
  /// serve it without hitting secure storage on every single request.
  AuthSession? _currentSession;

  Future<String?> _readCurrentAccessToken() async => _currentSession?.accessToken;

  void _handleUnauthorized() {
    _currentSession = null;
    // Fire-and-forget: clearing local storage doesn't need to block the
    // caller whose request just failed with 401/403.
    unawaited(_sessionStore.clear());
  }

  Future<Result<AuthSession>> login({required String email, required String password}) async {
    // AppConfig.apiClientId/apiClientSecret can throw (missing .env entry —
    // e.g. a dev machine not yet updated after client credentials became
    // platform-aware). Reading them must happen inside this try, not as
    // part of building ApiClient.post's arguments — an exception thrown
    // while evaluating an argument expression happens before post() (and
    // its own try-catch) ever runs, so it would otherwise escape login()
    // as a raw, unmapped exception instead of a Result.failure.
    final Map<String, String> clientCredentials;
    try {
      clientCredentials = {
        'client_id': AppConfig.apiClientId,
        'client_secret': AppConfig.apiClientSecret,
      };
    } catch (error, stackTrace) {
      AppLogger.recordError(
        error,
        stackTrace,
        reason: 'Missing/invalid API client credentials in .env',
      );
      return Result.failure(ConfigException(cause: error, stackTrace: stackTrace));
    }

    final loginResult = await _apiClient.post<LoginResponse>(
      '/sign_in',
      data: {'email': email, 'password': password},
      queryParameters: clientCredentials,
      parser: (json) => LoginResponse.fromJson(json as Map<String, dynamic>),
    );

    return switch (loginResult) {
      Failure<LoginResponse>(error: final error) => Result.failure(error),
      Success<LoginResponse>(data: final loginResponse) => await _persistSession(
        _toSession(loginResponse, fallbackEmail: email),
      ),
    };
  }

  /// Restores a previously-saved session (e.g. on app start) without
  /// hitting the network. Returns `Success(null)` when there is none.
  Future<Result<AuthSession?>> restoreSession() async {
    final loadResult = await _sessionStore.load();
    loadResult.fold(onSuccess: (session) => _currentSession = session, onFailure: (_) {});
    return loadResult;
  }

  Future<Result<void>> logout() async {
    final session = _currentSession;
    _currentSession = null;
    if (session != null) {
      await _remoteSignOut(session);
    }
    return _sessionStore.clear();
  }

  /// Best-effort call to `DELETE /sign_out` so the token is invalidated on
  /// the backend too. Deliberately swallows every failure (missing
  /// client_id/client_secret config, network error, non-2xx, ...): dropping
  /// the *local* session is the security-critical half of logout and must
  /// always happen, even if the remote call can't be made.
  Future<void> _remoteSignOut(AuthSession session) async {
    try {
      // Unlike every other endpoint, `/sign_out` takes client_id/
      // client_secret/access_token in the request body rather than as
      // query parameters — see tasks/api-map.md. Building this map is
      // inside the try for the same reason as in [login]: AppConfig's
      // getters can throw on a misconfigured .env.
      await _apiClient.delete<void>(
        '/sign_out',
        data: {
          'client_id': AppConfig.apiClientId,
          'client_secret': AppConfig.apiClientSecret,
          'access_token': session.accessToken,
        },
        parser: (_) {},
      );
    } catch (error, stackTrace) {
      AppLogger.recordError(
        error,
        stackTrace,
        reason: 'Remote /sign_out failed; local session is still cleared',
      );
    }
  }

  AuthSession _toSession(LoginResponse response, {required String fallbackEmail}) {
    final email = response.user.email.isNotEmpty ? response.user.email : fallbackEmail;
    return AuthSession(
      accessToken: response.token,
      userId: response.user.id,
      userName: response.user.name,
      userEmail: email,
      userImageUrl: response.user.imageUrl,
      areaId: response.user.areaId,
      addressNumber: response.user.addressNumber,
    );
  }

  Future<Result<AuthSession>> _persistSession(AuthSession session) async {
    final saveResult = await _sessionStore.save(session);
    return saveResult.when(
      success: (_) {
        _currentSession = session;
        return Result.success(session);
      },
      failure: (error) => Result.failure(error),
    );
  }
}
