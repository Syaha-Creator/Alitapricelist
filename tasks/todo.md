# Todo: Pricelist Browsing (SPEC.md §8 Step 3)

See git history for `tasks/plan.md`'s Step 3 content (superseded by Step 4 below, but preserved
in git history) for full context, API contract, and confirmed design decisions.

## Phase 1: Models
- [x] Task 1: `Area`/`Channel`/`Brand` models + `parseMasterDataEnvelope` + tests
- [x] Task 2: `PricelistItem` model (full filtered_pl contract) + tests
- [x] Task 3: `ItemLookupEntry`/`Accessory` models + tests

## Checkpoint 1
- [x] All Phase 1 tests green (37 tests), `flutter analyze` clean, commit (`48d0075`)

## Phase 2: Repository + cache
- [x] Task 4: `PricelistRepository.getAreas/getChannels/getBrands` + tests
- [x] Task 5: `PricelistCacheStore` (file JSON) + tests
- [x] Task 6: `PricelistRepository.getFilteredPricelist` (network + cache fallback) + tests
- [x] Task 7: `PricelistRepository.getItemLookups/getAccessories` + tests

## Checkpoint 2
- [x] Repository + cache tests green (all fallback cases, 111 total), `flutter analyze` clean, commit

## Phase 3: Filter/grouping/search/sort logic
- [x] Task 8: `PricelistFilterNotifier` (cascading reset) + tests
- [x] Task 9: `brandsForSelectedChannelProvider` + `groupPricelistItemsByName` + tests
      (found and fixed a grouping-key bug via TDD: must group by `kasur`, not the full
      `name` which includes `ukuran` — see plan.md decisions)
- [x] Task 10: `searchQueryProvider`/`sortOptionProvider`/`filteredSortedPricelistItemsProvider` + tests

## Checkpoint 3
- [x] All logic tests green (141 total project-wide), `flutter analyze` clean, commit

## Phase 4: UI
- [x] Task 11: `PricelistHomePage` (search, sort, cascading filter pills, masonry grid, stale-cache
      indicator) wired into `app_router.dart` replacing `PlaceholderHomePage` + widget tests
      (found and worked around a widget-test gotcha: `getFilteredPricelist`'s on-disk cache
      touches real `dart:io` File I/O, which `tester.pump()`'s virtual clock can't drive and
      which turns a plain `pumpAndSettle()` into an infinite hang behind the loading spinner's
      repeating animation — fixed by bridging to the real event loop with `tester.runAsync()`
      around the tap + a real delay for exactly the steps that reach that code path)

## Checkpoint 4 (final)
- [x] Full test suite green (146 tests project-wide), `flutter analyze` 0 issues
- [ ] `code-review-and-quality` pass
- [ ] Summary shown to user before Step 4

# Todo: Configurator (SPEC.md §5.3 Step 4)

See `tasks/plan.md` for full context: formula contract (with worked numeric examples), the 4
confirmed user decisions (variant scope simplified/kasur-anchor-only, item lookup included now,
floor always enforced on both input paths, markup-above-base supported), and architecture
decisions.

## Phase 1: Formula contract + pure calculation module
- [x] Task `spec`: Formula contract (rumus + contoh angka) written to `tasks/plan.md`
- [x] Task `calc-module`: `price_calculator.dart` (`calculateBaseTotalEup`,
      `nonZeroDiscountCeilings`, `applyCascadingDiscounts`, `computeDiscountsFromTarget`,
      `resolveFinalPrice`, `PriceCalculationResult`) + dedup refactor: extracted
      `pricelist_anchor.dart` (`AnchorType`, `isComponentPresent`, `resolveAnchor`) shared with
      `pricelist_grouping.dart`'s `_modelGroupName` (Step 3 behavior unchanged, its tests pass
      unmodified)
- [x] Task `calc-tests`: Exhaustive pure tests for all formula contract cases, including the two
      new edge cases per user decision (manual-tier discount below floor still detected/clamped;
      target-above-base markup honored) plus the `baseTotalEup <= 0` NaN/Infinity guard

## Checkpoint 1 (this iteration)
- [x] `price_calculator_test.dart` (23 tests) + `pricelist_anchor_test.dart` (9 tests) green,
      plus `pricelist_grouping_test.dart` (11 tests) still green unmodified, `flutter analyze`
      clean on all touched files, commit

## Phase 2: Variant resolution + item lookup (owned by a sibling agent, parallel work)
- [ ] Task `variant-resolver`: `variant_resolver.dart` (simplified, anchor kasur, from raw sibling
      `filteredPricelistSnapshotProvider`) + tests
- [ ] Task `item-lookup`: `item_lookup_grouping.dart` + wiring to
      `PricelistRepository.getItemLookups()` + tests

## Phase 3: UI + wiring
- [x] Task `configurator-ui`: `ConfiguratorPage` (variant picker, kain/warna picker, price
      breakdown, manual/target discount input, floor/markup indicators)
- [x] Task `wiring`: Wire tap on grid card (`PricelistHomePage`) → `ConfiguratorPage` via router

## Checkpoint 2 (final)
- [ ] Task `review`: `code-review-and-quality` pass + summary shown to user before Step 5
      (Favorites/Cart)
