import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_response.freezed.dart';

/// Raw shape of a successful `POST /sign_in` response from the Alita REST
/// API (verified against the legacy app's `auth_service.dart` — NOT
/// guessed). Notably: the top-level token field is named `token`, not
/// `access_token`, and there is no `refresh_token`/`expires_in`/`token_type`.
///
/// `fromJson` is written by hand (not `json_serializable`) because the
/// field-fallback logic below (`name` vs `user_name`, four possible names
/// for the sales code) isn't expressible as a plain annotation — but the
/// guardrail still holds: every field has a default, there is no `!`
/// anywhere, and a malformed/missing `user` object degrades to defaults
/// instead of throwing.
@freezed
class LoginResponse with _$LoginResponse {
  const factory LoginResponse({required String token, required AuthUser user}) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final rawToken = json['token'];
    final rawUser = json['user'];
    return LoginResponse(
      token: rawToken?.toString() ?? '',
      user: AuthUser.fromJson(rawUser is Map<String, dynamic> ? rawUser : const {}),
    );
  }
}

/// The `user` object embedded in the login response. This is a thin,
/// login-specific profile — the *full* profile comes from a separate
/// endpoint (out of scope for this step, see SPEC.md §8 step 3+).
@freezed
class AuthUser with _$AuthUser {
  const factory AuthUser({
    @Default(0) int id,
    @Default('') String email,
    @Default('') String name,
    @Default(0) int areaId,
    @Default('') String imageUrl,
    String? addressNumber,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawAreaId = json['area_id'];
    final rawImage = json['image'];
    final rawAddressNumber =
        json['address_number'] ?? json['sales_code'] ?? json['salesCode'] ?? json['code_sales'];
    final addressNumberString = rawAddressNumber?.toString();

    return AuthUser(
      id: rawId is int ? rawId : (int.tryParse(rawId?.toString() ?? '') ?? 0),
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['user_name']?.toString() ?? '',
      areaId: rawAreaId is num ? rawAreaId.toInt() : (int.tryParse(rawAreaId?.toString() ?? '') ?? 0),
      imageUrl: rawImage is Map ? (rawImage['url']?.toString() ?? '') : '',
      addressNumber: (addressNumberString == null || addressNumberString.isEmpty)
          ? null
          : addressNumberString,
    );
  }
}
