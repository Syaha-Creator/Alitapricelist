# Todo: Pricelist Browsing (SPEC.md §8 Step 3)

See `tasks/plan.md` for full context, API contract, and confirmed design decisions.

## Phase 1: Models
- [ ] Task 1: `Area`/`Channel`/`Brand` models + `parseMasterDataEnvelope` + tests
- [ ] Task 2: `PricelistItem` model (full filtered_pl contract) + tests
- [ ] Task 3: `ItemLookupEntry`/`Accessory` models + tests

## Checkpoint 1
- [ ] All Phase 1 tests green, `flutter analyze` clean, commit

## Phase 2: Repository + cache
- [ ] Task 4: `PricelistRepository.getAreas/getChannels/getBrands` + tests
- [ ] Task 5: `PricelistCacheStore` (file JSON) + tests
- [ ] Task 6: `PricelistRepository.getFilteredPricelist` (network + cache fallback) + tests
- [ ] Task 7: `PricelistRepository.getItemLookups/getAccessories` + tests

## Checkpoint 2
- [ ] Repository + cache tests green (all fallback cases), `flutter analyze` clean, commit

## Phase 3: Filter/grouping/search/sort logic
- [ ] Task 8: `PricelistFilterNotifier` (cascading reset) + tests
- [ ] Task 9: `brandsForSelectedChannelProvider` + `groupedPricelistProvider` + tests
- [ ] Task 10: `searchQueryProvider`/`sortOptionProvider`/`filteredSortedPricelistProvider` + tests

## Checkpoint 3
- [ ] All logic tests green, `flutter analyze` clean, commit

## Phase 4: UI
- [ ] Task 11: `PricelistHomePage` (search, sort, cascading filter pills, masonry grid, stale-cache
      indicator) wired into `app_router.dart` replacing `PlaceholderHomePage` + widget tests

## Checkpoint 4 (final)
- [ ] Full test suite green, `flutter analyze` 0 issues
- [ ] `code-review-and-quality` pass
- [ ] Summary shown to user before Step 4
