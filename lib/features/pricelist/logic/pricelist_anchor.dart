import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';

/// The "anchor" component of a product — the one that determines the
/// product's model identity (see [resolveAnchor]) and, in the configurator
/// (SPEC.md §8 Step 4), which EUP fields feed into the price base. Shared
/// between `pricelist_grouping.dart` (Step 3) and
/// `configurator/logic/price_calculator.dart` (Step 4) so the "which
/// component is present" logic lives in exactly one place.
enum AnchorType { kasur, divan, headboard, sorong }

/// A component field counts as "present" when it has a non-empty value that
/// isn't a "tanpa X" ("no X") placeholder (e.g. `"Tanpa Kasur"`,
/// `"tanpa divan"`) — case/whitespace insensitive.
bool isComponentPresent(String field) {
  final trimmed = field.trim().toLowerCase();
  return trimmed.isNotEmpty && !trimmed.startsWith('tanpa');
}

/// Resolves which component is the product's anchor, in priority order
/// kasur > divan > headboard > sorong. Falls back to `sorong` when none of
/// the four are present — callers that need a "no anchor at all" signal
/// should check [isComponentPresent] on the individual fields themselves.
AnchorType resolveAnchor(PricelistItem item) {
  if (isComponentPresent(item.kasur)) return AnchorType.kasur;
  if (isComponentPresent(item.divan)) return AnchorType.divan;
  if (isComponentPresent(item.headboard)) return AnchorType.headboard;
  return AnchorType.sorong;
}
