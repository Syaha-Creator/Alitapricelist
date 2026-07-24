import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_anchor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isComponentPresent', () {
    test('is true for a non-empty, non-placeholder value', () {
      expect(isComponentPresent('Comforta Elite'), isTrue);
    });

    test('is false for an empty string', () {
      expect(isComponentPresent(''), isFalse);
    });

    test('is false for a whitespace-only string', () {
      expect(isComponentPresent('   '), isFalse);
    });

    test('is false for a "tanpa X" placeholder, case/whitespace insensitive', () {
      expect(isComponentPresent('Tanpa Kasur'), isFalse);
      expect(isComponentPresent('  tanpa divan  '), isFalse);
      expect(isComponentPresent('TANPA HEADBOARD'), isFalse);
    });
  });

  group('resolveAnchor', () {
    test('resolves to kasur when present', () {
      const item = PricelistItem(kasur: 'Comforta Elite', divan: 'Divan Deluxe');
      expect(resolveAnchor(item), AnchorType.kasur);
    });

    test('resolves to divan when kasur is absent but divan is present', () {
      const item = PricelistItem(kasur: 'Tanpa Kasur', divan: 'Divan Deluxe');
      expect(resolveAnchor(item), AnchorType.divan);
    });

    test('resolves to headboard when kasur/divan are absent but headboard is present', () {
      const item = PricelistItem(
        kasur: '',
        divan: 'Tanpa Divan',
        headboard: 'Headboard Classic',
      );
      expect(resolveAnchor(item), AnchorType.headboard);
    });

    test('falls back to sorong when kasur/divan/headboard are all absent', () {
      const item = PricelistItem(
        kasur: 'Tanpa Kasur',
        divan: 'Tanpa Divan',
        headboard: 'Tanpa Headboard',
        sorong: 'Sorong Standard',
      );
      expect(resolveAnchor(item), AnchorType.sorong);
    });

    test('falls back to sorong when every component field is empty', () {
      const item = PricelistItem();
      expect(resolveAnchor(item), AnchorType.sorong);
    });
  });
}
