import 'package:freezed_annotation/freezed_annotation.dart';

part 'accessory.freezed.dart';

/// One row of `GET /api/pl_accessories`. Same caveat as [ItemLookupEntry]:
/// not used by the browsing grid in this step, modeled now so the
/// repository never hands out a raw `Map`. Envelope handled by
/// `parseLookupOrAccessoryEnvelope` (`item_lookup_entry.dart`), shared with
/// `pl_lookup_item_nums` since both endpoints use the same shape.
@freezed
class Accessory with _$Accessory {
  const factory Accessory({
    @Default('') String tipe,
    @Default('') String itemNum,
    @Default('') String ukuran,
    @Default(0) double pricelist,
  }) = _Accessory;

  factory Accessory.fromJson(Map<String, dynamic> json) {
    final rawPricelist = json['pricelist'];
    return Accessory(
      tipe: json['tipe']?.toString() ?? '',
      itemNum: json['item_num']?.toString() ?? '',
      ukuran: json['ukuran']?.toString() ?? '',
      pricelist: rawPricelist is num
          ? rawPricelist.toDouble()
          : (double.tryParse(rawPricelist?.toString() ?? '') ?? 0.0),
    );
  }
}
