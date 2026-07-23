import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session.freezed.dart';

/// A logged-in session persisted locally (token in secure storage, the rest
/// in SharedPreferences). Deliberately separate from [LoginResponse] — the
/// storage layer should never be coupled to the exact shape of the login
/// API response.
///
/// No field is nullable-without-a-default here; every field has a sane
/// fallback so no call site ever needs a null-assertion (`!`) to use it.
@freezed
class AuthSession with _$AuthSession {
  const factory AuthSession({
    required String accessToken,
    @Default(0) int userId,
    @Default('') String userName,
    @Default('') String userEmail,
    @Default('') String userImageUrl,
    @Default(0) int areaId,
    String? addressNumber,
  }) = _AuthSession;
}
