import 'package:alita_pricelist/features/pricelist/data/models/item_lookup_entry.dart';

/// Groups/looks up `pl_lookup_item_nums` rows (kain/warna — fabric/color —
/// options per product component) for the configurator (SPEC.md §8 Step 4).
///
/// **Join strategy**: [ItemLookupEntry] has no item-number/SKU field shared
/// with `PricelistItem` (`PricelistItem` doesn't carry a lookup item number
/// at all — its own `id` is a pricelist row id, not a lookup key). Read
/// against the legacy app's `item_lookup_provider.dart` (see
/// `tasks/plan.md`), the actual join is structural, not by id: an
/// [ItemLookupEntry.tipe] is the *component role* ("kasur"/"divan"/
/// "headboard"/"sorong" — the same vocabulary as `PricelistItem`'s own
/// `kasur`/`divan`/`headboard`/`sorong` *field names*, not their values) and
/// [ItemLookupEntry.ukuran] is a size, matched against the effective
/// (possibly variant-resolved) size of the `PricelistItem` in play. So a
/// caller resolves fabric/color options for "the kasur component of this
/// item at this size" via `(componentName: 'kasur', ukuran: item.ukuran)`,
/// not via any id equality. This mirrors the plan's documented grouping:
/// `Map<tipe.toLowerCase(): List<ItemLookupEntry>>`, filtered again by
/// `ukuran == effectiveSize`.

/// Groups [entries] by their `tipe` (component role: kasur/divan/headboard/
/// sorong), lower-cased and trimmed so lookups are case/whitespace
/// insensitive. Entries with an empty/blank `tipe` are dropped — there's no
/// component to attach them to. Never throws; an empty input yields an
/// empty map.
Map<String, List<ItemLookupEntry>> groupItemLookupsByTipe(List<ItemLookupEntry> entries) {
  final grouped = <String, List<ItemLookupEntry>>{};
  for (final entry in entries) {
    final key = entry.tipe.trim().toLowerCase();
    if (key.isEmpty) continue;
    grouped.putIfAbsent(key, () => []).add(entry);
  }
  return grouped;
}

/// Looks up the fabric/color entries relevant to a given component
/// ([componentName], e.g. `"kasur"`) at a given size ([ukuran]), using the
/// result of [groupItemLookupsByTipe].
///
/// - No entries for [componentName] at all → empty list (never null/throw).
/// - Blank [ukuran] (no effective size resolved yet) → every entry for that
///   component, unfiltered by size, since there's nothing to filter on.
/// - Otherwise → only entries whose `ukuran` matches, trimmed/exact.
List<ItemLookupEntry> lookupsFor({
  required String componentName,
  required String ukuran,
  required Map<String, List<ItemLookupEntry>> grouped,
}) {
  final candidates = grouped[componentName.trim().toLowerCase()] ?? const [];
  final targetSize = ukuran.trim();
  if (targetSize.isEmpty) return candidates;
  return candidates.where((entry) => entry.ukuran.trim() == targetSize).toList();
}
