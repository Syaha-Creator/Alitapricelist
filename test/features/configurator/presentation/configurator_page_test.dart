import 'package:alita_pricelist/features/configurator/logic/configurator_provider.dart';
import 'package:alita_pricelist/features/configurator/presentation/configurator_page.dart';
import 'package:alita_pricelist/features/pricelist/data/models/item_lookup_entry.dart';
import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';
import 'package:alita_pricelist/features/pricelist/data/models/pricelist_snapshot.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_browsing_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// `eupKasur=3_500_000, eupDivan=1_750_000, eupHeadboard=1_155_000,
/// eupSorong=0` → `baseTotalEup=6_405_000` — the same numbers verified
/// against the legacy app's data in `price_calculator_test.dart`.
const _item160 = PricelistItem(
  id: '1',
  name: 'Comforta Elite 160x200',
  kasur: 'Comforta Elite',
  ukuran: '160x200',
  eupKasur: 3500000,
  eupDivan: 1750000,
  eupHeadboard: 1155000,
  disc1: 0.1,
  disc2: 0.2,
  bottomPriceAnalyst: 5000000,
);

const _item180 = PricelistItem(
  id: '2',
  name: 'Comforta Elite 180x200',
  kasur: 'Comforta Elite',
  ukuran: '180x200',
  eupKasur: 4000000,
  eupDivan: 2000000,
  eupHeadboard: 1200000,
  disc1: 0.1,
  disc2: 0.2,
  bottomPriceAnalyst: 5500000,
);

void main() {
  String finalPriceText(WidgetTester tester) {
    return tester.widget<Text>(find.byKey(const Key('configurator_final_price_text'))).data!;
  }

  Widget buildApp(PricelistItem tappedItem) {
    return ProviderScope(
      overrides: [
        filteredPricelistSnapshotProvider.overrideWith(
          (ref) async => PricelistSnapshot(
            items: [_item160, _item180],
            isFromStaleCache: false,
            fetchedAt: DateTime(2024),
          ),
        ),
        configuratorItemLookupsProvider.overrideWith((ref) async => const <ItemLookupEntry>[]),
      ],
      child: MaterialApp(home: ConfiguratorPage(item: tappedItem)),
    );
  }

  testWidgets('renders with the base price when no discount is applied', (tester) async {
    await tester.pumpWidget(buildApp(_item160));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('configurator_final_price_text')), findsOneWidget);
    expect(finalPriceText(tester), 'Rp 6.405.000');
  });

  testWidgets('selecting a size updates the active variant and price breakdown', (tester) async {
    await tester.pumpWidget(buildApp(_item160));
    await tester.pumpAndSettle();
    expect(finalPriceText(tester), 'Rp 6.405.000');

    await tester.tap(find.byKey(const Key('configurator_size_chip_180x200')));
    await tester.pumpAndSettle();

    // base = 4_000_000 + 2_000_000 + 1_200_000 = 7_200_000
    expect(finalPriceText(tester), 'Rp 7.200.000');
  });

  testWidgets('entering a manual discount updates the final price', (tester) async {
    await tester.pumpWidget(buildApp(_item160));
    await tester.pumpAndSettle();

    final sliderFinder = find.descendant(
      of: find.byKey(const Key('configurator_discount_slider_0')),
      matching: find.byType(Slider),
    );
    expect(sliderFinder, findsOneWidget);

    final slider = tester.widget<Slider>(sliderFinder);
    slider.onChanged!(0.1);
    await tester.pumpAndSettle();

    // base 6_405_000 * (1 - 0.1) = 5_764_500 — above the floor, so no
    // floor banner should appear.
    expect(finalPriceText(tester), 'Rp 5.764.500');
    expect(find.byKey(const Key('configurator_floor_banner')), findsNothing);
  });

  testWidgets('a target price below the floor clamps to it and shows the floor banner', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(_item160));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Harga Target'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('configurator_target_price_field')), '1000000');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('configurator_floor_banner')), findsOneWidget);
    expect(finalPriceText(tester), 'Rp 5.000.000');
    expect(find.byKey(const Key('configurator_markup_banner')), findsNothing);
  });

  testWidgets('a target price above the base shows the markup banner', (tester) async {
    await tester.pumpWidget(buildApp(_item160));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Harga Target'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('configurator_target_price_field')), '7000000');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('configurator_markup_banner')), findsOneWidget);
    expect(finalPriceText(tester), 'Rp 7.000.000');
    expect(find.byKey(const Key('configurator_floor_banner')), findsNothing);
  });
}
