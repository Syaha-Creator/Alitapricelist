import 'package:alita_pricelist/features/configurator/logic/price_calculator.dart';
import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_anchor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateBaseTotalEup', () {
    const item = PricelistItem(
      eupKasur: 3500000,
      eupDivan: 1750000,
      eupHeadboard: 1155000,
      eupSorong: 0,
    );

    test('sums all EUP fields when anchor is kasur', () {
      expect(calculateBaseTotalEup(item, AnchorType.kasur), 6405000);
    });

    test('masks kasur/divan EUP to 0 when anchor is headboard', () {
      expect(calculateBaseTotalEup(item, AnchorType.headboard), 1155000);
    });

    test('keeps divan EUP but masks kasur EUP when anchor is divan', () {
      expect(calculateBaseTotalEup(item, AnchorType.divan), 1750000 + 1155000);
    });

    test('masks both kasur and divan EUP when anchor is sorong', () {
      const withSorong = PricelistItem(
        eupKasur: 3500000,
        eupDivan: 1750000,
        eupHeadboard: 1155000,
        eupSorong: 200000,
      );
      expect(calculateBaseTotalEup(withSorong, AnchorType.sorong), 1155000 + 200000);
    });
  });

  group('nonZeroDiscountCeilings', () {
    test('drops zero-ceiling tiers but keeps positive ones in order', () {
      const item = PricelistItem(disc1: 0.1, disc2: 0, disc3: 0.2, disc4: 0);
      expect(nonZeroDiscountCeilings(item), [0.1, 0.2]);
    });

    test('returns an empty list when no tiers are configured', () {
      expect(nonZeroDiscountCeilings(const PricelistItem()), isEmpty);
    });
  });

  group('applyCascadingDiscounts', () {
    test('cascades multiple tiers as a running multiply', () {
      expect(applyCascadingDiscounts(100, [0.1, 0.2]), closeTo(72, 0.001));
    });

    test('a 0% discount is a no-op', () {
      expect(applyCascadingDiscounts(100, [0]), closeTo(100, 0.001));
    });

    test('an empty discount list is a no-op', () {
      expect(applyCascadingDiscounts(100, []), closeTo(100, 0.001));
    });

    test('all 8 tiers at their ceiling equals base * product(1 - ceiling_i)', () {
      const ceilings = [0.05, 0.05, 0.1, 0.1, 0.05, 0.05, 0.1, 0.1];
      const item = PricelistItem(
        disc1: 0.05,
        disc2: 0.05,
        disc3: 0.1,
        disc4: 0.1,
        disc5: 0.05,
        disc6: 0.05,
        disc7: 0.1,
        disc8: 0.1,
      );
      final actualCeilings = nonZeroDiscountCeilings(item);
      expect(actualCeilings, ceilings);

      var expected = 1000000.0;
      for (final c in ceilings) {
        expected *= (1 - c);
      }
      expect(applyCascadingDiscounts(1000000, actualCeilings), closeTo(expected, 0.001));
    });
  });

  group('computeDiscountsFromTarget', () {
    test('target exactly reachable by the first tier alone', () {
      final result = computeDiscountsFromTarget(
        target: 50,
        baseTotalEup: 100,
        ceilings: [0.5, 0.5],
      );
      expect(result, [0.5]);
    });

    test('target requires both tiers, tier1 taking its max ceiling first', () {
      final result = computeDiscountsFromTarget(
        target: 40,
        baseTotalEup: 100,
        ceilings: [0.5, 0.5],
      );
      expect(result.length, 2);
      expect(result[0], closeTo(0.5, 0.0001));
      expect(result[1], closeTo(0.2, 0.0001));
    });

    test('guard: baseTotalEup <= 0 returns an empty list, never NaN/Infinity', () {
      final result = computeDiscountsFromTarget(target: 100, baseTotalEup: 0, ceilings: [0.5]);
      expect(result, isEmpty);

      final negativeBase = computeDiscountsFromTarget(
        target: 100,
        baseTotalEup: -50,
        ceilings: [0.5],
      );
      expect(negativeBase, isEmpty);
    });

    test('guard: target <= 0 returns an empty list', () {
      expect(computeDiscountsFromTarget(target: 0, baseTotalEup: 100, ceilings: [0.5]), isEmpty);
      expect(computeDiscountsFromTarget(target: -1, baseTotalEup: 100, ceilings: [0.5]), isEmpty);
    });

    test('guard: empty ceilings returns an empty list', () {
      expect(computeDiscountsFromTarget(target: 50, baseTotalEup: 100, ceilings: []), isEmpty);
    });
  });

  group('resolveFinalPrice', () {
    const baseItem = PricelistItem(
      eupKasur: 3500000,
      eupDivan: 1750000,
      eupHeadboard: 1155000,
      eupSorong: 0,
      disc1: 0.5,
      disc2: 0.5,
      bottomPriceAnalyst: 2000000,
    );

    test('no discount and no target: finalPrice equals base', () {
      final result = resolveFinalPrice(item: baseItem, anchor: AnchorType.kasur);
      expect(result.baseTotalEup, 6405000);
      expect(result.finalPrice, closeTo(6405000, 0.001));
      expect(result.appliedDiscounts, isEmpty);
      expect(result.isFloorApplied, isFalse);
      expect(result.isMarkup, isFalse);
    });

    test('targetPrice exactly equal to bottomPriceAnalyst: boundary is NOT floor-applied', () {
      final result = resolveFinalPrice(
        item: baseItem,
        anchor: AnchorType.kasur,
        targetPrice: 2000000,
      );
      expect(result.finalPrice, closeTo(2000000, 0.001));
      expect(result.isFloorApplied, isFalse);
      expect(result.isMarkup, isFalse);
    });

    test('targetPrice below bottomPriceAnalyst is clamped up to the floor', () {
      // With ceilings [0.5, 0.5] the lowest reachable target-based price
      // from base 6,405,000 is 6,405,000 * 0.5 * 0.5 = 1,601,250, which is
      // below the 2,000,000 floor — so this must clamp.
      final result = resolveFinalPrice(
        item: baseItem,
        anchor: AnchorType.kasur,
        targetPrice: 1601250,
      );
      expect(result.isFloorApplied, isTrue);
      expect(result.finalPrice, closeTo(2000000, 0.001));
      expect(result.floorPrice, 2000000);
    });

    test(
      'manualDiscounts that push finalPrice below bottomPriceAnalyst are still detected '
      'and clamped (the exact gap that was a real bug in the old app)',
      () {
        // base=6,405,000 * (1-0.5) * (1-0.5) = 1,601,250 < floor 2,000,000.
        final result = resolveFinalPrice(
          item: baseItem,
          anchor: AnchorType.kasur,
          manualDiscounts: [0.5, 0.5],
        );
        expect(result.isFloorApplied, isTrue);
        expect(result.finalPrice, closeTo(2000000, 0.001));
      },
    );

    test('manualDiscounts that stay above the floor are left untouched', () {
      final result = resolveFinalPrice(
        item: baseItem,
        anchor: AnchorType.kasur,
        manualDiscounts: [0.1],
      );
      expect(result.isFloorApplied, isFalse);
      expect(result.finalPrice, closeTo(6405000 * 0.9, 0.001));
      expect(result.appliedDiscounts, [0.1]);
    });

    test('targetPrice above baseTotalEup is a markup: no discount, finalPrice == target', () {
      final result = resolveFinalPrice(
        item: baseItem,
        anchor: AnchorType.kasur,
        targetPrice: 7000000,
      );
      expect(result.isMarkup, isTrue);
      expect(result.finalPrice, 7000000);
      expect(result.appliedDiscounts, isEmpty);
      expect(result.isFloorApplied, isFalse);
    });

    test('anchor masking flows through resolveFinalPrice', () {
      final result = resolveFinalPrice(item: baseItem, anchor: AnchorType.headboard);
      expect(result.baseTotalEup, 1155000);
    });

    test(
      'guard: baseTotalEup <= 0 (malformed item, all-zero EUP) never crashes or produces '
      'NaN/Infinity',
      () {
        const malformed = PricelistItem(
          eupKasur: 0,
          eupDivan: 0,
          eupHeadboard: 0,
          eupSorong: 0,
          disc1: 0.5,
          bottomPriceAnalyst: 100,
        );

        final noInput = resolveFinalPrice(item: malformed, anchor: AnchorType.kasur);
        expect(noInput.baseTotalEup, 0);
        _expectFinite(noInput);

        final withTarget = resolveFinalPrice(
          item: malformed,
          anchor: AnchorType.kasur,
          targetPrice: 50,
        );
        _expectFinite(withTarget);

        final withManual = resolveFinalPrice(
          item: malformed,
          anchor: AnchorType.kasur,
          manualDiscounts: [0.5],
        );
        _expectFinite(withManual);
      },
    );
  });
}

void _expectFinite(PriceCalculationResult result) {
  expect(result.baseTotalEup.isFinite, isTrue);
  expect(result.finalPrice.isFinite, isTrue);
  expect(result.finalPrice.isNaN, isFalse);
  for (final d in result.appliedDiscounts) {
    expect(d.isFinite, isTrue);
  }
}
