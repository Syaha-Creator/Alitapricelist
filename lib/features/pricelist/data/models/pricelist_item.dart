import 'package:freezed_annotation/freezed_annotation.dart';

part 'pricelist_item.freezed.dart';
part 'pricelist_item.g.dart';

/// One row of `GET /api/rawdata_price_lists/filtered_pl` — one row per
/// mattress *variant* (a given `kasur` name at a given `ukuran`), not one
/// row per product card (grouping several variants into one card is a
/// UI/provider-level concern, not this model's).
///
/// Every field here mirrors the legacy app's proven-in-production mapping
/// (see `tasks/plan.md` — audited from `alitapricelist copy`, not guessed).
/// This intentionally captures the *entire* raw contract (including
/// configurator-only fields like `disc1..8`/`bonus1..8` that this step's UI
/// doesn't render) so Step 4 (SPEC.md §8) can reuse this model without a
/// second parser.
///
/// `fromJson` (hand-written, not `json_serializable`) parses the *live API*
/// shape (snake_case keys, fallback chains). `fromJsonCache`/`toJson` (code
/// generated) round-trip the *cache* shape (this class's own Dart field
/// names) — the two are deliberately different entry points so a cache
/// migration never risks being fed live-API snake_case by mistake.
@JsonSerializable()
@freezed
class PricelistItem with _$PricelistItem {
  const PricelistItem._();

  const factory PricelistItem({
    @Default('') String id,
    @Default('') String name,
    @Default(0) double price,
    @Default('') String imageUrl,
    @Default('') String category,
    @Default('') String description,
    @Default('') String channel,
    @Default('') String brand,
    @Default('-') String program,
    @Default('') String kasur,
    @Default('') String ukuran,
    @Default('') String divan,
    @Default('') String headboard,
    @Default('') String sorong,
    @Default(false) bool isSet,
    @Default(0) double pricelist,
    @Default(0) double eupKasur,
    @Default(0) double eupDivan,
    @Default(0) double eupHeadboard,
    @Default(0) double eupSorong,
    @Default(0) double plKasur,
    @Default(0) double plDivan,
    @Default(0) double plHeadboard,
    @Default(0) double plSorong,
    String? bonus1,
    String? bonus2,
    String? bonus3,
    String? bonus4,
    String? bonus5,
    String? bonus6,
    String? bonus7,
    String? bonus8,
    int? qtyBonus1,
    int? qtyBonus2,
    int? qtyBonus3,
    int? qtyBonus4,
    int? qtyBonus5,
    int? qtyBonus6,
    int? qtyBonus7,
    int? qtyBonus8,
    double? plBonus1,
    double? plBonus2,
    double? plBonus3,
    double? plBonus4,
    double? plBonus5,
    double? plBonus6,
    double? plBonus7,
    double? plBonus8,
    @Default(0) double bottomPriceAnalyst,
    @Default(0) double disc1,
    @Default(0) double disc2,
    @Default(0) double disc3,
    @Default(0) double disc4,
    @Default(0) double disc5,
    @Default(0) double disc6,
    @Default(0) double disc7,
    @Default(0) double disc8,
  }) = _PricelistItem;

  /// Parses one row of the *live* `filtered_pl` response. `fallbackChannel`/
  /// `fallbackBrand` are the request's own `channel`/`brand` query params —
  /// the row's own `channel`/`brand` keys are sometimes absent, in which
  /// case we already know the answer without guessing.
  factory PricelistItem.fromJson(
    Map<String, dynamic> json, {
    required String fallbackChannel,
    required String fallbackBrand,
  }) {
    final kasur = json['kasur']?.toString() ?? '';
    final ukuran = json['ukuran']?.toString() ?? '';
    final rawName = '$kasur $ukuran'.trim();

    return PricelistItem(
      id: json['id']?.toString() ?? '',
      name: rawName.isEmpty ? 'Produk Tanpa Nama' : rawName,
      price: _parseDouble(json['end_user_price']),
      imageUrl: _firstImageUrl(json) ?? 'placeholder://${json['id']?.toString() ?? ''}',
      category: json['series']?.toString() ?? 'Uncategorized',
      description: json['detail_list']?.toString() ?? 'Detail produk belum tersedia.',
      channel: _nonEmpty(json['channel']) ?? fallbackChannel,
      brand: _nonEmpty(json['brand']) ?? fallbackBrand,
      program: json['program']?.toString() ?? '-',
      kasur: kasur,
      ukuran: ukuran,
      divan: json['divan']?.toString() ?? '',
      headboard: json['headboard']?.toString() ?? '',
      sorong: json['sorong']?.toString() ?? '',
      isSet: json['set'] == true,
      pricelist: _parseDouble(json['pricelist']),
      eupKasur: _parseDouble(json['eup_kasur']),
      eupDivan: _parseDouble(json['eup_divan']),
      eupHeadboard: _parseDouble(json['eup_headboard']),
      eupSorong: _parseDouble(json['eup_sorong']),
      plKasur: _parseDouble(json['pl_kasur']),
      plDivan: _parseDouble(json['pl_divan']),
      plHeadboard: _parseDouble(json['pl_headboard']),
      plSorong: _parseDouble(json['pl_sorong']),
      bonus1: json['bonus_1']?.toString(),
      bonus2: json['bonus_2']?.toString(),
      bonus3: json['bonus_3']?.toString(),
      bonus4: json['bonus_4']?.toString(),
      bonus5: json['bonus_5']?.toString(),
      bonus6: json['bonus_6']?.toString(),
      bonus7: json['bonus_7']?.toString(),
      bonus8: json['bonus_8']?.toString(),
      qtyBonus1: _parseIntNullable(json['qty_bonus1']),
      qtyBonus2: _parseIntNullable(json['qty_bonus2']),
      qtyBonus3: _parseIntNullable(json['qty_bonus3']),
      qtyBonus4: _parseIntNullable(json['qty_bonus4']),
      qtyBonus5: _parseIntNullable(json['qty_bonus5']),
      qtyBonus6: _parseIntNullable(json['qty_bonus6']),
      qtyBonus7: _parseIntNullable(json['qty_bonus7']),
      qtyBonus8: _parseIntNullable(json['qty_bonus8']),
      plBonus1: _parseDoubleNullable(json['pl_bonus_1']),
      plBonus2: _parseDoubleNullable(json['pl_bonus_2']),
      plBonus3: _parseDoubleNullable(json['pl_bonus_3']),
      plBonus4: _parseDoubleNullable(json['pl_bonus_4']),
      plBonus5: _parseDoubleNullable(json['pl_bonus_5']),
      plBonus6: _parseDoubleNullable(json['pl_bonus_6']),
      plBonus7: _parseDoubleNullable(json['pl_bonus_7']),
      plBonus8: _parseDoubleNullable(json['pl_bonus_8']),
      bottomPriceAnalyst: _parseDouble(json['bottom_price_analyst']),
      disc1: _parseDiscount(json, 1),
      disc2: _parseDiscount(json, 2),
      disc3: _parseDiscount(json, 3),
      disc4: _parseDiscount(json, 4),
      disc5: _parseDiscount(json, 5),
      disc6: _parseDiscount(json, 6),
      disc7: _parseDiscount(json, 7),
      disc8: _parseDiscount(json, 8),
    );
  }

  /// Restores a previously-cached row — the cache is always written by this
  /// class's own (code-generated) `toJson`, so this trusts the shape more
  /// than [fromJson] does, but still never throws on a corrupt file (see
  /// `PricelistCacheStore`, which wraps this in a try-catch).
  factory PricelistItem.fromJsonCache(Map<String, dynamic> json) => _$PricelistItemFromJson(json);

  Map<String, dynamic> toJson() => _$PricelistItemToJson(this);
}

const _imageUrlKeys = [
  'image_url',
  'imageUrl',
  'gambar',
  'foto',
  'thumbnail',
  'photo_url',
  'product_image',
  'image',
];

String? _firstImageUrl(Map<String, dynamic> json) {
  for (final key in _imageUrlKeys) {
    final value = json[key]?.toString();
    if (value != null && (value.startsWith('http://') || value.startsWith('https://'))) {
      return value;
    }
  }
  return null;
}

String? _nonEmpty(dynamic value) {
  final string = value?.toString();
  return (string == null || string.isEmpty) ? null : string;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

double? _parseDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _parseIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

/// Discounts can be published under several key spellings for the same
/// index — take the first one present whose value is positive. A value
/// greater than 1 is a percentage (e.g. `10` meaning 10%) and is normalized
/// to a fraction; a value `<= 1` is already a fraction.
double _parseDiscount(Map<String, dynamic> json, int index) {
  for (final key in ['disc_$index', 'disc$index', 'discount_$index', 'max_disc_$index']) {
    final raw = _parseDoubleNullable(json[key]);
    if (raw != null && raw > 0) {
      return raw > 1 ? raw / 100 : raw;
    }
  }
  return 0.0;
}

/// `filtered_pl` has been observed returning either `{"data": [...]}` or a
/// bare `[...]` — same tolerant-envelope reasoning as
/// `parseMasterDataEnvelope`.
List<Map<String, dynamic>> parseFilteredPricelistEnvelope(dynamic decoded) {
  if (decoded is List) {
    return decoded.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }
  if (decoded is Map) {
    final data = decoded['data'];
    if (data is List) {
      return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }
  }
  return const [];
}
