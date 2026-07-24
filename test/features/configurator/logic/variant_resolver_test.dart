import 'package:alita_pricelist/features/configurator/logic/variant_resolver.dart';
import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('findVariantSiblings', () {
    final allItems = [
      const PricelistItem(id: '1', name: 'Comforta Elite 160x200', kasur: 'Comforta Elite', ukuran: '160x200', price: 5000000),
      const PricelistItem(id: '2', name: 'Comforta Elite 180x200', kasur: 'Comforta Elite', ukuran: '180x200', price: 5500000),
      const PricelistItem(id: '3', name: 'Comforta Elite 200x200', kasur: 'Comforta Elite', ukuran: '200x200', price: 6000000),
      const PricelistItem(id: '4', name: 'Simmons Beautyrest 160x200', kasur: 'Simmons Beautyrest', ukuran: '160x200', price: 8000000),
    ];

    test('finds all sibling rows sharing the same kasur model', () {
      final result = findVariantSiblings(allItems[0], allItems);
      expect(result.map((i) => i.id), ['1', '2', '3']);
    });

    test('does not include rows of a different kasur model', () {
      final result = findVariantSiblings(allItems[0], allItems);
      expect(result.any((i) => i.id == '4'), isFalse);
    });

    test('matches kasur value trimmed', () {
      final items = [
        const PricelistItem(id: '1', kasur: '  Comforta Elite  ', ukuran: 'A'),
        const PricelistItem(id: '2', kasur: 'Comforta Elite', ukuran: 'B'),
      ];
      final result = findVariantSiblings(items[0], items);
      expect(result.map((i) => i.id), ['1', '2']);
    });

    test('falls back to [representative] when representative has no kasur present (out of scope)', () {
      const representative = PricelistItem(id: '5', kasur: 'Tanpa Kasur', divan: 'Divan Deluxe');
      final result = findVariantSiblings(representative, [representative, allItems[0]]);
      expect(result, [representative]);
    });

    test('empty allItems never throws, falls back to [representative]', () {
      final result = findVariantSiblings(allItems[0], const []);
      expect(result, [allItems[0]]);
    });

    test('representative not present in allItems falls back to [representative]', () {
      const representative = PricelistItem(id: '99', kasur: 'Unmatched Model');
      final result = findVariantSiblings(representative, allItems);
      expect(result, [representative]);
    });
  });

  group('distinctVariantSizes', () {
    test('returns distinct sizes sorted naturally (numeric-aware)', () {
      final siblings = [
        const PricelistItem(id: '1', kasur: 'A', ukuran: '200x200'),
        const PricelistItem(id: '2', kasur: 'A', ukuran: '90x200'),
        const PricelistItem(id: '3', kasur: 'A', ukuran: '160x200'),
        const PricelistItem(id: '4', kasur: 'A', ukuran: '160x200'),
      ];
      expect(distinctVariantSizes(siblings), ['90x200', '160x200', '200x200']);
    });

    test('drops empty/whitespace-only sizes', () {
      final siblings = [
        const PricelistItem(id: '1', kasur: 'A', ukuran: ''),
        const PricelistItem(id: '2', kasur: 'A', ukuran: '   '),
        const PricelistItem(id: '3', kasur: 'A', ukuran: '160x200'),
      ];
      expect(distinctVariantSizes(siblings), ['160x200']);
    });

    test('a single variant option (no real choice) still returns that one value', () {
      final siblings = [const PricelistItem(id: '1', kasur: 'A', ukuran: '160x200')];
      expect(distinctVariantSizes(siblings), ['160x200']);
    });

    test('empty sibling list returns empty list without throwing', () {
      expect(distinctVariantSizes(const []), isEmpty);
    });
  });

  group('resolveActiveVariant', () {
    final siblings = [
      const PricelistItem(id: '1', kasur: 'A', ukuran: '160x200'),
      const PricelistItem(id: '2', kasur: 'A', ukuran: '180x200'),
      const PricelistItem(id: '3', kasur: 'A', ukuran: '200x200'),
    ];

    test('resolves the sibling matching the selected size', () {
      final result = resolveActiveVariant(siblings: siblings, selectedUkuran: '180x200');
      expect(result.id, '2');
    });

    test('falls back to the first sibling when selection is null', () {
      final result = resolveActiveVariant(siblings: siblings, selectedUkuran: null);
      expect(result.id, '1');
    });

    test('falls back to the first sibling when selection matches no sibling', () {
      final result = resolveActiveVariant(siblings: siblings, selectedUkuran: '999x999');
      expect(result.id, '1');
    });

    test('falls back to the first sibling when selection is empty/whitespace', () {
      final result = resolveActiveVariant(siblings: siblings, selectedUkuran: '   ');
      expect(result.id, '1');
    });

    test('single-option sibling list (no real choice) resolves to that option', () {
      final single = [const PricelistItem(id: '1', kasur: 'A', ukuran: '160x200')];
      final result = resolveActiveVariant(siblings: single, selectedUkuran: 'anything');
      expect(result.id, '1');
    });

    test('duplicate ukuran values resolve deterministically to the first match', () {
      final duplicates = [
        const PricelistItem(id: '1', kasur: 'A', ukuran: '160x200'),
        const PricelistItem(id: '2', kasur: 'A', ukuran: '160x200'),
      ];
      final result = resolveActiveVariant(siblings: duplicates, selectedUkuran: '160x200');
      expect(result.id, '1');
    });

    test('empty sibling list never throws, returns a safe default PricelistItem', () {
      final result = resolveActiveVariant(siblings: const [], selectedUkuran: '160x200');
      expect(result, const PricelistItem());
    });
  });
}
