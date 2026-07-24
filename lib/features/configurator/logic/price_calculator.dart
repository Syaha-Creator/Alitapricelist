/// Pure price-calculation pipeline for the configurator (SPEC.md §8 Step 4).
/// No `Widget`/`BuildContext` dependency, no rounding anywhere (rounding is a
/// display-layer concern only) and no throwing — every function here
/// degrades to a safe default (`0`, `[]`) per SPEC.md §6, even on malformed
/// input such as an all-zero-EUP item.
library;

import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_anchor.dart';

/// Anchor-masked EUP sum. `kasur` EUP only counts when the anchor itself is
/// `kasur`; `divan` EUP counts for both `kasur` and `divan` anchors (a
/// divan-anchored product still has its own divan cost); `headboard`/
/// `sorong` EUP always count, since they're accessories layered on top of
/// whichever the main component is.
double calculateBaseTotalEup(PricelistItem item, AnchorType anchor) {
  final kasurEup = anchor == AnchorType.kasur ? item.eupKasur : 0.0;
  final divanEup =
      (anchor == AnchorType.kasur || anchor == AnchorType.divan) ? item.eupDivan : 0.0;
  return kasurEup + divanEup + item.eupHeadboard + item.eupSorong;
}

/// The 8 discount tiers, in order, dropping any tier whose ceiling is `0`
/// (not configured for this item) while preserving the relative order of
/// the remaining tiers.
List<double> nonZeroDiscountCeilings(PricelistItem item) {
  return [
    item.disc1,
    item.disc2,
    item.disc3,
    item.disc4,
    item.disc5,
    item.disc6,
    item.disc7,
    item.disc8,
  ].where((d) => d > 0).toList();
}

/// Applies each discount in [discounts] (in order) as a running multiply —
/// `price *= (1 - d)` — matching the legacy app's cascading-tier behavior.
double applyCascadingDiscounts(double basePrice, List<double> discounts) {
  var price = basePrice;
  for (final d in discounts) {
    price *= (1 - d);
  }
  return price;
}

/// Closed-form greedy reverse-calculation: for each tier ceiling (in order),
/// take the largest discount that reaches [target] without exceeding that
/// tier's ceiling, then move to the next tier with the new (discounted)
/// base. Stops as soon as a tier would need ~0 discount (target already
/// reached) or a ceiling is exhausted.
///
/// Guarded against `baseTotalEup <= 0`/`target <= 0`/empty [ceilings] —
/// returns `[]` rather than ever producing NaN or Infinity (division by a
/// non-positive base is never attempted).
List<double> computeDiscountsFromTarget({
  required double target,
  required double baseTotalEup,
  required List<double> ceilings,
}) {
  if (baseTotalEup <= 0 || target <= 0 || ceilings.isEmpty) return const [];

  final applied = <double>[];
  var base = baseTotalEup;
  for (final limit in ceilings) {
    if (base <= 0) break;
    var discount = 1 - (target / base);
    if (discount < 0) discount = 0;
    if (discount > limit) discount = limit;
    if (discount <= 1e-9) break;
    applied.add(discount);
    base *= (1 - discount);
  }
  return applied;
}

/// Result of [resolveFinalPrice] — plain immutable value class (trivially
/// comparable with `==`, no Freezed needed for something this small).
class PriceCalculationResult {
  const PriceCalculationResult({
    required this.baseTotalEup,
    required this.appliedDiscounts,
    required this.finalPrice,
    required this.isFloorApplied,
    required this.isMarkup,
    required this.floorPrice,
  });

  final double baseTotalEup;
  final List<double> appliedDiscounts;
  final double finalPrice;
  final bool isFloorApplied;
  final bool isMarkup;
  final double floorPrice;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PriceCalculationResult &&
        other.baseTotalEup == baseTotalEup &&
        _listEquals(other.appliedDiscounts, appliedDiscounts) &&
        other.finalPrice == finalPrice &&
        other.isFloorApplied == isFloorApplied &&
        other.isMarkup == isMarkup &&
        other.floorPrice == floorPrice;
  }

  @override
  int get hashCode => Object.hash(
    baseTotalEup,
    Object.hashAll(appliedDiscounts),
    finalPrice,
    isFloorApplied,
    isMarkup,
    floorPrice,
  );

  @override
  String toString() =>
      'PriceCalculationResult(baseTotalEup: $baseTotalEup, '
      'appliedDiscounts: $appliedDiscounts, finalPrice: $finalPrice, '
      'isFloorApplied: $isFloorApplied, isMarkup: $isMarkup, floorPrice: $floorPrice)';
}

bool _listEquals(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Single entry point for the configurator's price pipeline. Exactly one of
/// [manualDiscounts]/[targetPrice] is expected to be provided by callers; if
/// both are `null`, the result is simply the base price with no discount.
///
/// - `targetPrice` above `baseTotalEup` is a **markup** (`isMarkup = true`):
///   the final price is the target as-is, no discount applied.
/// - `targetPrice` at or below `baseTotalEup` reverse-calculates the tier
///   discounts needed to reach it ([computeDiscountsFromTarget]).
/// - `manualDiscounts` are cascaded directly, with no reverse-calculation.
///
/// **Floor enforcement always runs last**, regardless of which path was
/// taken above (this is the deliberate fix over the legacy app, which only
/// checked the floor on the target-price path — manual per-tier input could
/// silently land below the floor). If `item.bottomPriceAnalyst > 0` and the
/// computed `finalPrice` is strictly below it, the discounts are
/// recalculated from the floor itself and `isFloorApplied` is set.
PriceCalculationResult resolveFinalPrice({
  required PricelistItem item,
  required AnchorType anchor,
  List<double>? manualDiscounts,
  double? targetPrice,
}) {
  final baseTotalEup = calculateBaseTotalEup(item, anchor);
  final ceilings = nonZeroDiscountCeilings(item);

  var appliedDiscounts = <double>[];
  var finalPrice = baseTotalEup;
  var isMarkup = false;

  if (targetPrice != null) {
    if (targetPrice > baseTotalEup) {
      isMarkup = true;
      appliedDiscounts = const [];
      finalPrice = targetPrice;
    } else {
      appliedDiscounts = computeDiscountsFromTarget(
        target: targetPrice,
        baseTotalEup: baseTotalEup,
        ceilings: ceilings,
      );
      finalPrice = applyCascadingDiscounts(baseTotalEup, appliedDiscounts);
    }
  } else {
    appliedDiscounts = manualDiscounts ?? const [];
    finalPrice = applyCascadingDiscounts(baseTotalEup, appliedDiscounts);
  }

  var isFloorApplied = false;
  final floorPrice = item.bottomPriceAnalyst;
  if (floorPrice > 0 && finalPrice < floorPrice) {
    appliedDiscounts = computeDiscountsFromTarget(
      target: floorPrice,
      baseTotalEup: baseTotalEup,
      ceilings: ceilings,
    );
    finalPrice = applyCascadingDiscounts(baseTotalEup, appliedDiscounts);
    isFloorApplied = true;
    isMarkup = false;
  }

  return PriceCalculationResult(
    baseTotalEup: baseTotalEup,
    appliedDiscounts: appliedDiscounts,
    finalPrice: finalPrice,
    isFloorApplied: isFloorApplied,
    isMarkup: isMarkup,
    floorPrice: floorPrice,
  );
}
