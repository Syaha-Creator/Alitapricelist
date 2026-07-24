// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'accessory.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Accessory {
  String get tipe => throw _privateConstructorUsedError;
  String get itemNum => throw _privateConstructorUsedError;
  String get ukuran => throw _privateConstructorUsedError;
  double get pricelist => throw _privateConstructorUsedError;

  /// Create a copy of Accessory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccessoryCopyWith<Accessory> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccessoryCopyWith<$Res> {
  factory $AccessoryCopyWith(Accessory value, $Res Function(Accessory) then) =
      _$AccessoryCopyWithImpl<$Res, Accessory>;
  @useResult
  $Res call({String tipe, String itemNum, String ukuran, double pricelist});
}

/// @nodoc
class _$AccessoryCopyWithImpl<$Res, $Val extends Accessory> implements $AccessoryCopyWith<$Res> {
  _$AccessoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Accessory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tipe = null,
    Object? itemNum = null,
    Object? ukuran = null,
    Object? pricelist = null,
  }) {
    return _then(
      _value.copyWith(
            tipe: null == tipe
                ? _value.tipe
                : tipe // ignore: cast_nullable_to_non_nullable
                      as String,
            itemNum: null == itemNum
                ? _value.itemNum
                : itemNum // ignore: cast_nullable_to_non_nullable
                      as String,
            ukuran: null == ukuran
                ? _value.ukuran
                : ukuran // ignore: cast_nullable_to_non_nullable
                      as String,
            pricelist: null == pricelist
                ? _value.pricelist
                : pricelist // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AccessoryImplCopyWith<$Res> implements $AccessoryCopyWith<$Res> {
  factory _$$AccessoryImplCopyWith(_$AccessoryImpl value, $Res Function(_$AccessoryImpl) then) =
      __$$AccessoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String tipe, String itemNum, String ukuran, double pricelist});
}

/// @nodoc
class __$$AccessoryImplCopyWithImpl<$Res> extends _$AccessoryCopyWithImpl<$Res, _$AccessoryImpl>
    implements _$$AccessoryImplCopyWith<$Res> {
  __$$AccessoryImplCopyWithImpl(_$AccessoryImpl _value, $Res Function(_$AccessoryImpl) _then)
    : super(_value, _then);

  /// Create a copy of Accessory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tipe = null,
    Object? itemNum = null,
    Object? ukuran = null,
    Object? pricelist = null,
  }) {
    return _then(
      _$AccessoryImpl(
        tipe: null == tipe
            ? _value.tipe
            : tipe // ignore: cast_nullable_to_non_nullable
                  as String,
        itemNum: null == itemNum
            ? _value.itemNum
            : itemNum // ignore: cast_nullable_to_non_nullable
                  as String,
        ukuran: null == ukuran
            ? _value.ukuran
            : ukuran // ignore: cast_nullable_to_non_nullable
                  as String,
        pricelist: null == pricelist
            ? _value.pricelist
            : pricelist // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$AccessoryImpl implements _Accessory {
  const _$AccessoryImpl({this.tipe = '', this.itemNum = '', this.ukuran = '', this.pricelist = 0});

  @override
  @JsonKey()
  final String tipe;
  @override
  @JsonKey()
  final String itemNum;
  @override
  @JsonKey()
  final String ukuran;
  @override
  @JsonKey()
  final double pricelist;

  @override
  String toString() {
    return 'Accessory(tipe: $tipe, itemNum: $itemNum, ukuran: $ukuran, pricelist: $pricelist)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccessoryImpl &&
            (identical(other.tipe, tipe) || other.tipe == tipe) &&
            (identical(other.itemNum, itemNum) || other.itemNum == itemNum) &&
            (identical(other.ukuran, ukuran) || other.ukuran == ukuran) &&
            (identical(other.pricelist, pricelist) || other.pricelist == pricelist));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tipe, itemNum, ukuran, pricelist);

  /// Create a copy of Accessory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccessoryImplCopyWith<_$AccessoryImpl> get copyWith =>
      __$$AccessoryImplCopyWithImpl<_$AccessoryImpl>(this, _$identity);
}

abstract class _Accessory implements Accessory {
  const factory _Accessory({
    final String tipe,
    final String itemNum,
    final String ukuran,
    final double pricelist,
  }) = _$AccessoryImpl;

  @override
  String get tipe;
  @override
  String get itemNum;
  @override
  String get ukuran;
  @override
  double get pricelist;

  /// Create a copy of Accessory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccessoryImplCopyWith<_$AccessoryImpl> get copyWith => throw _privateConstructorUsedError;
}
