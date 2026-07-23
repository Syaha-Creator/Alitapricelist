// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AuthSession {
  String get accessToken => throw _privateConstructorUsedError;
  int get userId => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError;
  String get userEmail => throw _privateConstructorUsedError;
  String get userImageUrl => throw _privateConstructorUsedError;
  int get areaId => throw _privateConstructorUsedError;
  String? get addressNumber => throw _privateConstructorUsedError;

  /// Create a copy of AuthSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthSessionCopyWith<AuthSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthSessionCopyWith<$Res> {
  factory $AuthSessionCopyWith(
    AuthSession value,
    $Res Function(AuthSession) then,
  ) = _$AuthSessionCopyWithImpl<$Res, AuthSession>;
  @useResult
  $Res call({
    String accessToken,
    int userId,
    String userName,
    String userEmail,
    String userImageUrl,
    int areaId,
    String? addressNumber,
  });
}

/// @nodoc
class _$AuthSessionCopyWithImpl<$Res, $Val extends AuthSession>
    implements $AuthSessionCopyWith<$Res> {
  _$AuthSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? userId = null,
    Object? userName = null,
    Object? userEmail = null,
    Object? userImageUrl = null,
    Object? areaId = null,
    Object? addressNumber = freezed,
  }) {
    return _then(
      _value.copyWith(
            accessToken: null == accessToken
                ? _value.accessToken
                : accessToken // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as int,
            userName: null == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String,
            userEmail: null == userEmail
                ? _value.userEmail
                : userEmail // ignore: cast_nullable_to_non_nullable
                      as String,
            userImageUrl: null == userImageUrl
                ? _value.userImageUrl
                : userImageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            areaId: null == areaId
                ? _value.areaId
                : areaId // ignore: cast_nullable_to_non_nullable
                      as int,
            addressNumber: freezed == addressNumber
                ? _value.addressNumber
                : addressNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthSessionImplCopyWith<$Res>
    implements $AuthSessionCopyWith<$Res> {
  factory _$$AuthSessionImplCopyWith(
    _$AuthSessionImpl value,
    $Res Function(_$AuthSessionImpl) then,
  ) = __$$AuthSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String accessToken,
    int userId,
    String userName,
    String userEmail,
    String userImageUrl,
    int areaId,
    String? addressNumber,
  });
}

/// @nodoc
class __$$AuthSessionImplCopyWithImpl<$Res>
    extends _$AuthSessionCopyWithImpl<$Res, _$AuthSessionImpl>
    implements _$$AuthSessionImplCopyWith<$Res> {
  __$$AuthSessionImplCopyWithImpl(
    _$AuthSessionImpl _value,
    $Res Function(_$AuthSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? userId = null,
    Object? userName = null,
    Object? userEmail = null,
    Object? userImageUrl = null,
    Object? areaId = null,
    Object? addressNumber = freezed,
  }) {
    return _then(
      _$AuthSessionImpl(
        accessToken: null == accessToken
            ? _value.accessToken
            : accessToken // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as int,
        userName: null == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String,
        userEmail: null == userEmail
            ? _value.userEmail
            : userEmail // ignore: cast_nullable_to_non_nullable
                  as String,
        userImageUrl: null == userImageUrl
            ? _value.userImageUrl
            : userImageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        areaId: null == areaId
            ? _value.areaId
            : areaId // ignore: cast_nullable_to_non_nullable
                  as int,
        addressNumber: freezed == addressNumber
            ? _value.addressNumber
            : addressNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$AuthSessionImpl implements _AuthSession {
  const _$AuthSessionImpl({
    required this.accessToken,
    this.userId = 0,
    this.userName = '',
    this.userEmail = '',
    this.userImageUrl = '',
    this.areaId = 0,
    this.addressNumber,
  });

  @override
  final String accessToken;
  @override
  @JsonKey()
  final int userId;
  @override
  @JsonKey()
  final String userName;
  @override
  @JsonKey()
  final String userEmail;
  @override
  @JsonKey()
  final String userImageUrl;
  @override
  @JsonKey()
  final int areaId;
  @override
  final String? addressNumber;

  @override
  String toString() {
    return 'AuthSession(accessToken: $accessToken, userId: $userId, userName: $userName, userEmail: $userEmail, userImageUrl: $userImageUrl, areaId: $areaId, addressNumber: $addressNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthSessionImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userEmail, userEmail) ||
                other.userEmail == userEmail) &&
            (identical(other.userImageUrl, userImageUrl) ||
                other.userImageUrl == userImageUrl) &&
            (identical(other.areaId, areaId) || other.areaId == areaId) &&
            (identical(other.addressNumber, addressNumber) ||
                other.addressNumber == addressNumber));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    accessToken,
    userId,
    userName,
    userEmail,
    userImageUrl,
    areaId,
    addressNumber,
  );

  /// Create a copy of AuthSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthSessionImplCopyWith<_$AuthSessionImpl> get copyWith =>
      __$$AuthSessionImplCopyWithImpl<_$AuthSessionImpl>(this, _$identity);
}

abstract class _AuthSession implements AuthSession {
  const factory _AuthSession({
    required final String accessToken,
    final int userId,
    final String userName,
    final String userEmail,
    final String userImageUrl,
    final int areaId,
    final String? addressNumber,
  }) = _$AuthSessionImpl;

  @override
  String get accessToken;
  @override
  int get userId;
  @override
  String get userName;
  @override
  String get userEmail;
  @override
  String get userImageUrl;
  @override
  int get areaId;
  @override
  String? get addressNumber;

  /// Create a copy of AuthSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthSessionImplCopyWith<_$AuthSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
