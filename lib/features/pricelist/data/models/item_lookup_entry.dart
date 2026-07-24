import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_lookup_entry.freezed.dart';

/// One row of `GET /api/pl_lookup_item_nums`. Not rendered by the browsing
/// grid in this step — used by the Step 4 configurator — but still modeled
/// now so the repository never hands out a raw `Map` (SPEC.md §6).
@freezed
class ItemLookupEntry with _$ItemLookupEntry {
  const factory ItemLookupEntry({
    @Default('') String tipe,
    @Default('') String ukuran,
    @Default('') String itemNum,
    String? jenisKain,
    String? warnaKain,
  }) = _ItemLookupEntry;

  factory ItemLookupEntry.fromJson(Map<String, dynamic> json) {
    return ItemLookupEntry(
      tipe: json['tipe']?.toString() ?? '',
      ukuran: json['ukuran']?.toString() ?? '',
      itemNum: json['item_num']?.toString() ?? '',
      jenisKain: json['jenis_kain']?.toString(),
      warnaKain: json['warna_kain']?.toString(),
    );
  }
}

/// `pl_lookup_item_nums`/`pl_accessories` both use the same envelope: a
/// `status` field that must equal `"success"`, then a list under `result`
/// (or `data` as a fallback key) — mirrors the legacy app's
/// `itemLookupProvider`/`accessoryProvider`.
List<Map<String, dynamic>> parseLookupOrAccessoryEnvelope(dynamic decoded) {
  if (decoded is! Map || decoded['status'] != 'success') {
    return const [];
  }
  final list = decoded['result'] ?? decoded['data'];
  if (list is! List) {
    return const [];
  }
  return list.whereType<Map>().map(Map<String, dynamic>.from).toList();
}
