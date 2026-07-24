import 'package:alita_pricelist/features/pricelist/data/models/master_data.dart';
import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('brandsForChannel', () {
    final brands = [
      const Brand(id: 1, brand: 'Comforta', plChannelId: 223),
      const Brand(id: 2, brand: 'Simmons', plChannelId: 223),
      const Brand(id: 3, brand: 'Spring Air', plChannelId: 300),
    ];

    test('returns only brands whose plChannelId matches the given channel', () {
      const channel = Channel(id: 223, channel: 'Direct');
      final result = brandsForChannel(brands: brands, channel: channel);
      expect(result.map((b) => b.brand), ['Comforta', 'Simmons']);
    });

    test('returns an empty list when channel is null (nothing selected yet)', () {
      expect(brandsForChannel(brands: brands, channel: null), isEmpty);
    });

    test('returns an empty list when no brand matches the channel', () {
      const channel = Channel(id: 999, channel: 'Unknown');
      expect(brandsForChannel(brands: brands, channel: channel), isEmpty);
    });
  });

  group('groupPricelistItemsByName', () {
    test('collapses multiple size (ukuran) variants of the same kasur into one card', () {
      final items = [
        const PricelistItem(
          id: '1',
          name: 'Comforta Elite 160x200',
          kasur: 'Comforta Elite',
          price: 5000000,
        ),
        const PricelistItem(
          id: '2',
          name: 'Comforta Elite 180x200',
          kasur: 'Comforta Elite',
          price: 4500000,
        ),
        const PricelistItem(
          id: '3',
          name: 'Comforta Elite 200x200',
          kasur: 'Comforta Elite',
          price: 6000000,
        ),
      ];

      final grouped = groupPricelistItemsByName(items);

      expect(grouped, hasLength(1));
      expect(grouped.first.name, 'Comforta Elite');
      expect(grouped.first.price, 4500000.0);
    });

    test('keeps distinct kasur models as separate cards', () {
      final items = [
        const PricelistItem(
          id: '1',
          name: 'Comforta Elite 160x200',
          kasur: 'Comforta Elite',
          price: 5000000,
        ),
        const PricelistItem(
          id: '2',
          name: 'Simmons Beautyrest 160x200',
          kasur: 'Simmons Beautyrest',
          price: 8000000,
        ),
      ];

      final grouped = groupPricelistItemsByName(items);

      expect(grouped.map((i) => i.name), containsAll(['Comforta Elite', 'Simmons Beautyrest']));
    });

    test('ignores zero/non-positive prices when picking the lowest price', () {
      final items = [
        const PricelistItem(id: '1', name: 'A', kasur: 'Comforta Elite', price: 0),
        const PricelistItem(id: '2', name: 'B', kasur: 'Comforta Elite', price: 4500000),
      ];

      final grouped = groupPricelistItemsByName(items);

      expect(grouped, hasLength(1));
      expect(grouped.first.price, 4500000.0);
    });

    test('never drops a group even when every variant has a non-positive price', () {
      final items = [
        const PricelistItem(id: '1', name: 'A', kasur: 'Comforta Elite', price: 0),
        const PricelistItem(id: '2', name: 'B', kasur: 'Comforta Elite', price: 0),
      ];

      final grouped = groupPricelistItemsByName(items);

      expect(grouped, hasLength(1));
      expect(grouped.first.price, 0.0);
    });

    test('falls back to divan/headboard/sorong when kasur is empty or "Tanpa Kasur"', () {
      final noMattress = groupPricelistItemsByName([
        const PricelistItem(
          id: '1',
          name: 'X',
          kasur: 'Tanpa Kasur',
          divan: 'Divan Deluxe',
          price: 1000000,
        ),
      ]);
      expect(noMattress.single.name, 'Divan Deluxe');

      final headboardOnly = groupPricelistItemsByName([
        const PricelistItem(
          id: '2',
          name: 'Y',
          kasur: '',
          divan: 'Tanpa Divan',
          headboard: 'Headboard Classic',
          price: 500000,
        ),
      ]);
      expect(headboardOnly.single.name, 'Headboard Classic');
    });

    test('falls back to the row name itself when every component is empty/placeholder', () {
      final result = groupPricelistItemsByName([
        const PricelistItem(id: '1', name: 'Produk Tanpa Nama', price: 100),
      ]);
      expect(result.single.name, 'Produk Tanpa Nama');
    });

    test('returns an empty list for an empty input without throwing', () {
      expect(groupPricelistItemsByName(const []), isEmpty);
    });
  });
}
