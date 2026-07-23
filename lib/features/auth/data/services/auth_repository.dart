import 'dart:async';

import 'package:alita_pricelist/core/config/app_config.dart';
import 'package:alita_pricelist/core/error/result.dart';
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
    _apiClient.attachAuth(accessTokenProvider: _readCurrentAccessToken, onUnauthorized: _handleUnauthorized);
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
    final loginResult = await _apiClient.post<LoginResponse>(
      '/sign_in',
      data: {'email': email, 'password': password},
      queryParameters: {'client_id': AppConfig.apiClientId, 'client_secret': AppConfig.apiClientSecret},
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
    _currentSession = null;
    return _sessionStore.clear();
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
