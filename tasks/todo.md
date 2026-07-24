# Todo: Pricelist Browsing (SPEC.md §8 Step 3)

See `tasks/plan.md` for full context, API contract, and confirmed design decisions.

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
