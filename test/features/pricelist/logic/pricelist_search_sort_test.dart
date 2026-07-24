import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_search_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final items = [
    const PricelistItem(id: '1', name: 'Comforta Elite', price: 5000000),
    const PricelistItem(id: '2', name: 'Simmons Beautyrest', price: 8000000),
    const PricelistItem(id: '3', name: 'Airland Deluxe', price: 3000000),
  ];

  group('filterAndSortPricelistItems — search', () {
    test('an empty query returns every item', () {
      final result = filterAndSortPricelistItems(
        items: items,
        searchQuery: '',
        sortOption: PricelistSortOption.nameAsc,
      );
      expect(result, hasLength(3));
    });

    test('matches case-insensitively against the product name', () {
      final result = filterAndSortPricelistItems(
        items: items,
        searchQuery: 'comforta',
        sortOption: PricelistSortOption.nameAsc,
      );
      expect(result.map((i) => i.name), ['Comforta Elite']);
    });

    test('returns an empty list when nothing matches', () {
      final result = filterAndSortPricelistItems(
        items: items,
        searchQuery: 'nonexistent brand',
        sortOption: PricelistSortOption.nameAsc,
      );
      expect(result, isEmpty);
    });

    test('trims surrounding whitespace before matching', () {
      final result = filterAndSortPricelistItems(
        items: items,
        searchQuery: '  simmons  ',
        sortOption: PricelistSortOption.nameAsc,
      );
      expect(result.map((i) => i.name), ['Simmons Beautyrest']);
    });
  });

  group('filterAndSortPricelistItems — sort', () {
    test('nameAsc sorts alphabetically, case-insensitively', () {
      final result = filterAndSortPricelistItems(
        items: items,
        searchQuery: '',
        sortOption: PricelistSortOption.nameAsc,
      );
      expect(result.map((i) => i.name), ['Airland Deluxe', 'Comforta Elite', 'Simmons Beautyrest']);
    });

    test('priceAsc sorts from lowest to highest price', () {
      final result = filterAndSortPricelistItems(
        items: items,
        searchQuery: '',
        sortOption: PricelistSortOption.priceAsc,
      );
      expect(result.map((i) => i.price), [3000000.0, 5000000.0, 8000000.0]);
    });

    test('priceDesc sorts from highest to lowest price', () {
      final result = filterAndSortPricelistItems(
        items: items,
        searchQuery: '',
        sortOption: PricelistSortOption.priceDesc,
      );
      expect(result.map((i) => i.price), [8000000.0, 5000000.0, 3000000.0]);
    });

    test('does not mutate the input list', () {
      final original = List<PricelistItem>.from(items);
      filterAndSortPricelistItems(
        items: items,
        searchQuery: '',
        sortOption: PricelistSortOption.priceDesc,
      );
      expect(items, original);
    });
  });
}
