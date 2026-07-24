// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_lookup_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ItemLookupEntry {
  String get tipe => throw _privateConstructorUsedError;
  String get ukuran => throw _privateConstructorUsedError;
  String get itemNum => throw _privateConstructorUsedError;
  String? get jenisKain => throw _privateConstructorUsedError;
  String? get warnaKain => throw _privateConstructorUsedError;

  /// Create a copy of ItemLookupEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItemLookupEntryCopyWith<ItemLookupEntry> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemLookupEntryCopyWith<$Res> {
  factory $ItemLookupEntryCopyWith(ItemLookupEntry value, $Res Function(ItemLookupEntry) then) =
      _$ItemLookupEntryCopyWithImpl<$Res, ItemLookupEntry>;
  @useResult
  $Res call({String tipe, String ukuran, String itemNum, String? jenisKain, String? warnaKain});
}

/// @nodoc
class _$ItemLookupEntryCopyWithImpl<$Res, $Val extends ItemLookupEntry>
    implements $ItemLookupEntryCopyWith<$Res> {
  _$ItemLookupEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItemLookupEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tipe = null,
    Object? ukuran = null,
    Object? itemNum = null,
    Object? jenisKain = freezed,
    Object? warnaKain = freezed,
  }) {
    return _then(
      _value.copyWith(
            tipe: null == tipe
                ? _value.tipe
                : tipe // ignore: cast_nullable_to_non_nullable
                      as String,
            ukuran: null == ukuran
                ? _value.ukuran
                : ukuran // ignore: cast_nullable_to_non_nullable
                      as String,
            itemNum: null == itemNum
                ? _value.itemNum
                : itemNum // ignore: cast_nullable_to_non_nullable
                      as String,
            jenisKain: freezed == jenisKain
                ? _value.jenisKain
                : jenisKain // ignore: cast_nullable_to_non_nullable
                      as String?,
            warnaKain: freezed == warnaKain
                ? _value.warnaKain
                : warnaKain // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ItemLookupEntryImplCopyWith<$Res> implements $ItemLookupEntryCopyWith<$Res> {
  factory _$$ItemLookupEntryImplCopyWith(
    _$ItemLookupEntryImpl value,
    $Res Function(_$ItemLookupEntryImpl) then,
  ) = __$$ItemLookupEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String tipe, String ukuran, String itemNum, String? jenisKain, String? warnaKain});
}

/// @nodoc
class __$$ItemLookupEntryImplCopyWithImpl<$Res>
    extends _$ItemLookupEntryCopyWithImpl<$Res, _$ItemLookupEntryImpl>
    implements _$$ItemLookupEntryImplCopyWith<$Res> {
  __$$ItemLookupEntryImplCopyWithImpl(
    _$ItemLookupEntryImpl _value,
    $Res Function(_$ItemLookupEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ItemLookupEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tipe = null,
    Object? ukuran = null,
    Object? itemNum = null,
    Object? jenisKain = freezed,
    Object? warnaKain = freezed,
  }) {
    return _then(
      _$ItemLookupEntryImpl(
        tipe: null == tipe
            ? _value.tipe
            : tipe // ignore: cast_nullable_to_non_nullable
                  as String,
        ukuran: null == ukuran
            ? _value.ukuran
            : ukuran // ignore: cast_nullable_to_non_nullable
                  as String,
        itemNum: null == itemNum
            ? _value.itemNum
            : itemNum // ignore: cast_nullable_to_non_nullable
                  as String,
        jenisKain: freezed == jenisKain
            ? _value.jenisKain
            : jenisKain // ignore: cast_nullable_to_non_nullable
                  as String?,
        warnaKain: freezed == warnaKain
            ? _value.warnaKain
            : warnaKain // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ItemLookupEntryImpl implements _ItemLookupEntry {
  const _$ItemLookupEntryImpl({
    this.tipe = '',
    this.ukuran = '',
    this.itemNum = '',
    this.jenisKain,
    this.warnaKain,
  });

  @override
  @JsonKey()
  final String tipe;
  @override
  @JsonKey()
  final String ukuran;
  @override
  @JsonKey()
  final String itemNum;
  @override
  final String? jenisKain;
  @override
  final String? warnaKain;

  @override
  String toString() {
    return 'ItemLookupEntry(tipe: $tipe, ukuran: $ukuran, itemNum: $itemNum, jenisKain: $jenisKain, warnaKain: $warnaKain)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemLookupEntryImpl &&
            (identical(other.tipe, tipe) || other.tipe == tipe) &&
            (identical(other.ukuran, ukuran) || other.ukuran == ukuran) &&
            (identical(other.itemNum, itemNum) || other.itemNum == itemNum) &&
            (identical(other.jenisKain, jenisKain) || other.jenisKain == jenisKain) &&
            (identical(other.warnaKain, warnaKain) || other.warnaKain == warnaKain));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tipe, ukuran, itemNum, jenisKain, warnaKain);

  /// Create a copy of ItemLookupEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemLookupEntryImplCopyWith<_$ItemLookupEntryImpl> get copyWith =>
      __$$ItemLookupEntryImplCopyWithImpl<_$ItemLookupEntryImpl>(this, _$identity);
}

abstract class _ItemLookupEntry implements ItemLookupEntry {
  const factory _ItemLookupEntry({
    final String tipe,
    final String ukuran,
    final String itemNum,
    final String? jenisKain,
    final String? warnaKain,
  }) = _$ItemLookupEntryImpl;

  @override
  String get tipe;
  @override
  String get ukuran;
  @override
  String get itemNum;
  @override
  String? get jenisKain;
  @override
  String? get warnaKain;

  /// Create a copy of ItemLookupEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItemLookupEntryImplCopyWith<_$ItemLookupEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
