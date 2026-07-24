import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PricelistItem.fromJson', () {
    test('parses a fully-populated row', () {
      final item = PricelistItem.fromJson(
        {
          'id': 501,
          'kasur': 'Comforta Elite',
          'ukuran': '160x200',
          'end_user_price': 5000000,
          'image_url': 'https://cdn.example.test/a.png',
          'series': 'Premium',
          'detail_list': 'Kasur premium dengan busa memori',
          'channel': 'Direct',
          'brand': 'Comforta',
          'program': 'Promo Juli',
          'divan': 'Divan A',
          'headboard': 'HB A',
          'sorong': 'Sorong A',
          'set': true,
          'pricelist': 4500000,
          'eup_kasur': 3000000,
          'eup_divan': 500000,
          'eup_headboard': 200000,
          'eup_sorong': 300000,
          'pl_kasur': 2800000,
          'pl_divan': 480000,
          'pl_headboard': 190000,
          'pl_sorong': 290000,
          'bonus_1': 'Bantal',
          'qty_bonus1': 2,
          'pl_bonus_1': 50000,
          'bottom_price_analyst': 4000000,
          'disc_1': 10,
        },
        fallbackChannel: 'FallbackChannel',
        fallbackBrand: 'FallbackBrand',
      );

      expect(item.id, '501');
      expect(item.name, 'Comforta Elite 160x200');
      expect(item.price, 5000000.0);
      expect(item.imageUrl, 'https://cdn.example.test/a.png');
      expect(item.category, 'Premium');
      expect(item.description, 'Kasur premium dengan busa memori');
      expect(item.channel, 'Direct');
      expect(item.brand, 'Comforta');
      expect(item.program, 'Promo Juli');
      expect(item.kasur, 'Comforta Elite');
      expect(item.ukuran, '160x200');
      expect(item.divan, 'Divan A');
      expect(item.headboard, 'HB A');
      expect(item.sorong, 'Sorong A');
      expect(item.isSet, isTrue);
      expect(item.pricelist, 4500000.0);
      expect(item.eupKasur, 3000000.0);
      expect(item.eupDivan, 500000.0);
      expect(item.eupHeadboard, 200000.0);
      expect(item.eupSorong, 300000.0);
      expect(item.plKasur, 2800000.0);
      expect(item.plDivan, 480000.0);
      expect(item.plHeadboard, 190000.0);
      expect(item.plSorong, 290000.0);
      expect(item.bonus1, 'Bantal');
      expect(item.qtyBonus1, 2);
      expect(item.plBonus1, 50000.0);
      expect(item.bottomPriceAnalyst, 4000000.0);
      expect(item.disc1, 0.1); // 10 > 1 -> divided by 100
    });

    test('name falls back to a placeholder when kasur/ukuran are both empty', () {
      final item = PricelistItem.fromJson(const {}, fallbackChannel: 'C', fallbackBrand: 'B');
      expect(item.name, 'Produk Tanpa Nama');
      expect(item.id, '');
    });

    test('channel/brand fall back to the request params when missing from the row', () {
      final item = PricelistItem.fromJson(
        const {},
        fallbackChannel: 'Direct',
        fallbackBrand: 'Comforta',
      );
      expect(item.channel, 'Direct');
      expect(item.brand, 'Comforta');
    });

    test('picks the first http(s) url among the known image key variants', () {
      final item = PricelistItem.fromJson(
        {
          'gambar': 'not-a-url',
          'foto': 'https://cdn.example.test/found.png',
          'thumbnail': 'https://cdn.example.test/ignored.png',
        },
        fallbackChannel: 'C',
        fallbackBrand: 'B',
      );
      expect(item.imageUrl, 'https://cdn.example.test/found.png');
    });

    test('falls back to a placeholder image when no key has a usable url', () {
      final item = PricelistItem.fromJson({'id': 42}, fallbackChannel: 'C', fallbackBrand: 'B');
      expect(item.imageUrl, contains('42'));
    });

    test('isSet is strictly true only when set == true', () {
      expect(
        PricelistItem.fromJson({'set': 'true'}, fallbackChannel: 'C', fallbackBrand: 'B').isSet,
        isFalse,
      );
      expect(
        PricelistItem.fromJson(const {}, fallbackChannel: 'C', fallbackBrand: 'B').isSet,
        isFalse,
      );
    });

    test('bonus/qtyBonus/plBonus default to null when absent (never throw)', () {
      final item = PricelistItem.fromJson(const {}, fallbackChannel: 'C', fallbackBrand: 'B');
      expect(item.bonus1, isNull);
      expect(item.qtyBonus1, isNull);
      expect(item.plBonus1, isNull);
    });

    test(
      'disc picks the first key with a positive value among disc_i/disc<i>/discount_i/max_disc_i',
      () {
        final item = PricelistItem.fromJson(
          {'discount_2': 5},
          fallbackChannel: 'C',
          fallbackBrand: 'B',
        );
        expect(item.disc2, 0.05);
      },
    );

    test('disc defaults to 0 when no matching key is positive', () {
      final item = PricelistItem.fromJson({'disc_3': 0}, fallbackChannel: 'C', fallbackBrand: 'B');
      expect(item.disc3, 0.0);
    });

    test('a value <= 1 is used as-is (already a fraction), not divided', () {
      final item = PricelistItem.fromJson(
        {'disc_1': 0.15},
        fallbackChannel: 'C',
        fallbackBrand: 'B',
      );
      expect(item.disc1, 0.15);
    });
  });

  group('parseFilteredPricelistEnvelope', () {
    test('accepts {"data": [...]}', () {
      final rows = parseFilteredPricelistEnvelope({
        'data': [
          {'id': 1},
        ],
      });
      expect(rows, [
        {'id': 1},
      ]);
    });

    test('accepts a bare list', () {
      final rows = parseFilteredPricelistEnvelope([
        {'id': 1},
      ]);
      expect(rows, [
        {'id': 1},
      ]);
    });

    test('returns an empty list for null or unrecognized shapes', () {
      expect(parseFilteredPricelistEnvelope(null), isEmpty);
      expect(parseFilteredPricelistEnvelope('garbage'), isEmpty);
    });
  });

  group('PricelistItem JSON round-trip (cache)', () {
    test('toJson then fromJsonCache reproduces every field', () {
      const item = PricelistItem(
        id: '1',
        name: 'Test',
        price: 100,
        imageUrl: 'https://x.test/a.png',
        category: 'Cat',
        description: 'Desc',
        channel: 'Direct',
        brand: 'Comforta',
        program: 'Promo',
        kasur: 'K',
        ukuran: 'U',
        divan: 'D',
        headboard: 'H',
        sorong: 'S',
        isSet: true,
        pricelist: 90,
        bonus1: 'Bantal',
        qtyBonus1: 2,
        plBonus1: 5,
        bottomPriceAnalyst: 80,
        disc1: 0.1,
      );

      final roundTripped = PricelistItem.fromJsonCache(item.toJson());
      expect(roundTripped, item);
    });
  });
}
