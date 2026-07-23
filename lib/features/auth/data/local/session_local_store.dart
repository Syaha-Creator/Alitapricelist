import 'package:alita_pricelist/core/error/app_exception.dart';
import 'package:alita_pricelist/core/error/result.dart';
import 'package:alita_pricelist/core/logging/app_logger.dart';
import 'package:alita_pricelist/features/auth/data/local/token_storage.dart';
import 'package:alita_pricelist/features/auth/data/models/auth_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists an [AuthSession] locally: the access token goes to secure
/// storage (Keychain/Keystore), everything else (profile fields, which are
/// not secrets) goes to SharedPreferences.
///
/// Every method returns a [Result] — a storage failure (disk full,
/// keychain locked, etc.) becomes a [CacheException], never a raw
/// exception bubbling up to a repository or the UI.
class SessionLocalStore {
  SessionLocalStore({TokenStorage? tokenStorage}) : _tokenStorage = tokenStorage ?? SecureTokenStorage();

  final TokenStorage _tokenStorage;

  static const _keyAccessToken = 'auth_access_token';
  static const _keyUserId = 'auth_user_id';
  static const _keyUserName = 'auth_user_name';
  static const _keyUserEmail = 'auth_user_email';
  static const _keyUserImageUrl = 'auth_user_image_url';
  static const _keyAreaId = 'auth_area_id';
  static const _keyAddressNumber = 'auth_address_number';

  Future<Result<void>> save(AuthSession session) async {
    try {
      await _tokenStorage.write(_keyAccessToken, session.accessToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyUserId, session.userId);
      await prefs.setString(_keyUserName, session.userName);
      await prefs.setString(_keyUserEmail, session.userEmail);
      await prefs.setString(_keyUserImageUrl, session.userImageUrl);
      await prefs.setInt(_keyAreaId, session.areaId);
      final addressNumber = session.addressNumber;
      if (addressNumber != null && addressNumber.isNotEmpty) {
        await prefs.setString(_keyAddressNumber, addressNumber);
      } else {
        await prefs.remove(_keyAddressNumber);
      }
      return const Result.success(null);
    } catch (error, stackTrace) {
      AppLogger.recordError(error, stackTrace, reason: 'SessionLocalStore.save failed');
      return Result.failure(CacheException(cause: error, stackTrace: stackTrace));
    }
  }

  /// Returns `Success(null)` (not a failure) when there is simply no saved
  /// session — that's an expected, normal state, not an error.
  Future<Result<AuthSession?>> load() async {
    try {
      final token = await _tokenStorage.read(_keyAccessToken);
      if (token == null || token.isEmpty) {
        return const Result.success(null);
      }
      final prefs = await SharedPreferences.getInstance();
      return Result.success(
        AuthSession(
          accessToken: token,
          userId: prefs.getInt(_keyUserId) ?? 0,
          userName: prefs.getString(_keyUserName) ?? '',
          userEmail: prefs.getString(_keyUserEmail) ?? '',
          userImageUrl: prefs.getString(_keyUserImageUrl) ?? '',
          areaId: prefs.getInt(_keyAreaId) ?? 0,
          addressNumber: prefs.getString(_keyAddressNumber),
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.recordError(error, stackTrace, reason: 'SessionLocalStore.load failed');
      return Result.failure(CacheException(cause: error, stackTrace: stackTrace));
    }
  }

  Future<Result<void>> clear() async {
    try {
      await _tokenStorage.delete(_keyAccessToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserImageUrl);
      await prefs.remove(_keyAreaId);
      await prefs.remove(_keyAddressNumber);
      return const Result.success(null);
    } catch (error, stackTrace) {
      AppLogger.recordError(error, stackTrace, reason: 'SessionLocalStore.clear failed');
      return Result.failure(CacheException(cause: error, stackTrace: stackTrace));
    }
  }
}
