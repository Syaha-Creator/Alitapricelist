import 'package:alita_pricelist/features/configurator/logic/item_lookup_grouping.dart';
import 'package:alita_pricelist/features/configurator/logic/price_calculator.dart';
import 'package:alita_pricelist/features/configurator/logic/variant_resolver.dart';
import 'package:alita_pricelist/features/pricelist/data/models/item_lookup_entry.dart';
import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_anchor.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_browsing_provider.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod wiring for the configurator (SPEC.md §8 Step 4). Manual
/// (non-generated) providers — same convention as
/// `pricelist_repository_provider.dart`/`bootstrap_provider.dart`.

/// How the user is currently driving the price: either dialing in a
/// per-tier discount manually, or typing the final price they want and
/// letting [computeDiscountsFromTarget] reverse-calculate the tiers.
enum ConfiguratorInputMode { manualTiers, targetPrice }

/// Sibling rows (same `kasur`) for the tapped [PricelistItem], sourced from
/// the raw (ungrouped) snapshot already fetched by Step 3 — no new network
/// call. Family-keyed by the tapped item itself so each configurator
/// session gets its own sibling pool without leaking state across items.
final configuratorSiblingsProvider = Provider.family<List<PricelistItem>, PricelistItem>((
  ref,
  tappedItem,
) {
  final rawPool = ref.watch(filteredPricelistSnapshotProvider).valueOrNull?.items ?? const [];
  return findVariantSiblings(tappedItem, rawPool);
});

/// The user's currently selected `ukuran` (size) within the configurator
/// session, `null` until they pick one explicitly (defaulting behavior is
/// handled by [resolveActiveVariant] itself, not here).
final configuratorSelectedUkuranProvider = StateProvider<String?>((ref) => null);

/// The single active [PricelistItem] variant, resolved from
/// [configuratorSiblingsProvider] + [configuratorSelectedUkuranProvider].
/// Family-keyed by the tapped item so it stays consistent with the sibling
/// pool above.
final configuratorActiveVariantProvider = Provider.family<PricelistItem, PricelistItem>((
  ref,
  tappedItem,
) {
  final siblings = ref.watch(configuratorSiblingsProvider(tappedItem));
  final selected = ref.watch(configuratorSelectedUkuranProvider) ?? tappedItem.ukuran;
  return resolveActiveVariant(siblings: siblings, selectedUkuran: selected);
});

/// Fetches `pl_lookup_item_nums` once per configurator session, following
/// the same `result.when(success: ..., failure: (error) => throw error)`
/// idiom as `filteredPricelistSnapshotProvider` so a failure surfaces as a
/// normal `AsyncValue.error` — the UI treats this as supplementary/
/// non-critical (see `configurator_page.dart`), not a blocker.
final configuratorItemLookupsProvider = FutureProvider<List<ItemLookupEntry>>((ref) async {
  final result = await ref.watch(pricelistRepositoryProvider).getItemLookups();
  return result.when(success: (entries) => entries, failure: (error) => throw error);
});

/// [configuratorItemLookupsProvider]'s data, grouped by component role
/// (`kasur`/`divan`/`headboard`/`sorong`) via [groupItemLookupsByTipe].
/// `null` (not an empty map) while loading/errored, so callers can tell
/// "not ready yet" apart from "ready, but genuinely nothing grouped".
final configuratorGroupedLookupsProvider = Provider<Map<String, List<ItemLookupEntry>>?>((ref) {
  final entries = ref.watch(configuratorItemLookupsProvider).valueOrNull;
  if (entries == null) return null;
  return groupItemLookupsByTipe(entries);
});

/// Manual per-tier discount fractions chosen by the user, one entry per
/// active/non-zero tier (see `nonZeroDiscountCeilings`). Starts empty — no
/// discount, `finalPrice` starts at `baseTotalEup`.
final configuratorManualDiscountsProvider = StateProvider<List<double>>((ref) => const []);

/// Optional target-final-price input, `null` when the user hasn't typed one
/// (or has cleared it) — treated as "no discount" by
/// [configuratorPriceResultProvider], never as a stale/garbage value.
final configuratorTargetPriceProvider = StateProvider<double?>((ref) => null);

/// Which of [configuratorManualDiscountsProvider]/[configuratorTargetPriceProvider]
/// currently drives [configuratorPriceResultProvider].
final configuratorInputModeProvider = StateProvider<ConfiguratorInputMode>(
  (ref) => ConfiguratorInputMode.manualTiers,
);

/// The calculation result for the active variant, family-keyed by the
/// tapped item (so it stays scoped to a single configurator session).
///
/// Anchor is always [AnchorType.kasur] for this step's scope (per the
/// plan); [resolveAnchor] is still consulted defensively so a stray
/// non-kasur item reaching this page (should never happen given routing)
/// degrades to its own real anchor rather than silently mis-pricing it.
final configuratorPriceResultProvider = Provider.family<PriceCalculationResult, PricelistItem>((
  ref,
  tappedItem,
) {
  final activeItem = ref.watch(configuratorActiveVariantProvider(tappedItem));
  final anchor = isComponentPresent(activeItem.kasur)
      ? AnchorType.kasur
      : resolveAnchor(activeItem);
  final mode = ref.watch(configuratorInputModeProvider);

  final List<double>? manualDiscounts;
  final double? targetPrice;
  switch (mode) {
    case ConfiguratorInputMode.manualTiers:
      manualDiscounts = ref.watch(configuratorManualDiscountsProvider);
      targetPrice = null;
    case ConfiguratorInputMode.targetPrice:
      manualDiscounts = const [];
      targetPrice = ref.watch(configuratorTargetPriceProvider);
  }

  return resolveFinalPrice(
    item: activeItem,
    anchor: anchor,
    manualDiscounts: manualDiscounts,
    targetPrice: targetPrice,
  );
});
