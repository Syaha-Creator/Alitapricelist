import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_anchor.dart';

/// Sibling/variant resolution for the configurator (SPEC.md §8 Step 4),
/// **kasur-anchor only** — the user's confirmed scope for this step. Products
/// whose anchor is divan/headboard/sorong (no `kasur` present) are out of
/// scope; [findVariantSiblings] degrades safely for them (see below) rather
/// than throwing, but the configurator UI itself should not be reachable for
/// non-kasur-anchored items yet.
///
/// All functions here are pure (no `BuildContext`/`Widget`, no network) and
/// operate on the raw `List<PricelistItem>` already fetched by
/// `filteredPricelistSnapshotProvider` (Step 3) — no new API call.

/// Finds every row in [allItems] that belongs to the same model as
/// [representative], mirroring the exact grouping key
/// `pricelist_grouping.dart`'s `_modelGroupName` uses for the grid (same
/// `kasur` value, trimmed, case-sensitive) so the sibling set here is always
/// consistent with what the user saw grouped into one card.
///
/// Scoped to kasur-anchor only: if [representative] itself has no `kasur`
/// present (per [isComponentPresent]), there is nothing well-defined to
/// match on for this step's simplified scope, so this returns just
/// `[representative]` (no siblings) instead of throwing or returning an
/// empty list — the caller always has at least the item the user tapped.
List<PricelistItem> findVariantSiblings(
  PricelistItem representative,
  List<PricelistItem> allItems,
) {
  if (!isComponentPresent(representative.kasur)) {
    return [representative];
  }
  final key = representative.kasur.trim();
  final siblings = allItems.where((item) => item.kasur.trim() == key).toList();
  return siblings.isEmpty ? [representative] : siblings;
}

/// Distinct, sorted `ukuran` (size) values available across [siblings].
/// Empty/whitespace-only sizes are dropped (nothing for the user to pick).
/// Sorted with a "natural" comparison (leading numeric run compared
/// numerically, e.g. `"90x200"` before `"160x200"`) since sizes are
/// conventionally `<width>x<length>` and a plain string sort would put
/// `"160x200"` before `"90x200"`; falls back to plain string comparison for
/// values that don't start with digits.
List<String> distinctVariantSizes(List<PricelistItem> siblings) {
  final sizes = <String>{};
  for (final item in siblings) {
    final ukuran = item.ukuran.trim();
    if (ukuran.isNotEmpty) sizes.add(ukuran);
  }
  final result = sizes.toList()..sort(_compareSizes);
  return result;
}

int _compareSizes(String a, String b) {
  final numA = _leadingNumber(a);
  final numB = _leadingNumber(b);
  if (numA != null && numB != null && numA != numB) {
    return numA.compareTo(numB);
  }
  return a.compareTo(b);
}

num? _leadingNumber(String value) {
  final match = RegExp(r'^\d+').firstMatch(value);
  return match == null ? null : num.tryParse(match.group(0)!);
}

/// Resolves the single active/selected [PricelistItem] out of [siblings]
/// given the user's currently selected `ukuran` (size).
///
/// - Empty [siblings] never throws — returns a safe, empty-field default
///   [PricelistItem] (SPEC.md §6: never crash, always degrade).
/// - A `null`/empty [selectedUkuran], or one that matches no sibling, falls
///   back to the first sibling rather than returning nothing.
/// - Duplicate `ukuran` values among siblings resolve to the first match,
///   which is a deterministic, harmless choice (the duplicates are, by
///   definition, indistinguishable by size alone).
PricelistItem resolveActiveVariant({
  required List<PricelistItem> siblings,
  String? selectedUkuran,
}) {
  if (siblings.isEmpty) return const PricelistItem();
  final wanted = selectedUkuran?.trim();
  if (wanted != null && wanted.isNotEmpty) {
    for (final item in siblings) {
      if (item.ukuran.trim() == wanted) return item;
    }
  }
  return siblings.first;
}
