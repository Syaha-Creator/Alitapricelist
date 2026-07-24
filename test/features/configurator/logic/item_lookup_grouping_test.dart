import 'package:alita_pricelist/features/configurator/logic/item_lookup_grouping.dart';
import 'package:alita_pricelist/features/pricelist/data/models/item_lookup_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('groupItemLookupsByTipe', () {
    final entries = [
      const ItemLookupEntry(tipe: 'kasur', ukuran: '160x200', itemNum: 'K1', jenisKain: 'Katun'),
      const ItemLookupEntry(tipe: 'kasur', ukuran: '180x200', itemNum: 'K2', jenisKain: 'Sutra'),
      const ItemLookupEntry(tipe: 'Kasur', ukuran: '200x200', itemNum: 'K3', jenisKain: 'Linen'),
      const ItemLookupEntry(tipe: 'divan', ukuran: '160x200', itemNum: 'D1', jenisKain: 'Suede'),
    ];

    test('groups entries by tipe, case/whitespace insensitive', () {
      final grouped = groupItemLookupsByTipe(entries);
      expect(grouped.keys, containsAll(['kasur', 'divan']));
      expect(grouped['kasur'], hasLength(3));
      expect(grouped['divan'], hasLength(1));
    });

    test('drops entries with an empty/blank tipe', () {
      final grouped = groupItemLookupsByTipe([
        const ItemLookupEntry(tipe: '', ukuran: '160x200', itemNum: 'X1'),
        const ItemLookupEntry(tipe: '   ', ukuran: '160x200', itemNum: 'X2'),
        ...entries,
      ]);
      expect(grouped.values.expand((v) => v).any((e) => e.itemNum == 'X1'), isFalse);
      expect(grouped.values.expand((v) => v).any((e) => e.itemNum == 'X2'), isFalse);
    });

    test('empty input returns empty map without throwing', () {
      expect(groupItemLookupsByTipe(const []), isEmpty);
    });
  });

  group('lookupsFor', () {
    final entries = [
      const ItemLookupEntry(tipe: 'kasur', ukuran: '160x200', itemNum: 'K1', jenisKain: 'Katun'),
      const ItemLookupEntry(tipe: 'kasur', ukuran: '180x200', itemNum: 'K2', jenisKain: 'Sutra'),
      const ItemLookupEntry(tipe: 'kasur', ukuran: '160x200', itemNum: 'K3', jenisKain: 'Linen'),
      const ItemLookupEntry(tipe: 'divan', ukuran: '160x200', itemNum: 'D1', jenisKain: 'Suede'),
    ];
    final grouped = groupItemLookupsByTipe(entries);

    test('finds entries matching component name and size', () {
      final result = lookupsFor(componentName: 'kasur', ukuran: '160x200', grouped: grouped);
      expect(result.map((e) => e.itemNum), containsAll(['K1', 'K3']));
      expect(result.any((e) => e.itemNum == 'K2'), isFalse);
    });

    test('component name lookup is case/whitespace insensitive', () {
      final result = lookupsFor(componentName: '  Kasur  ', ukuran: '160x200', grouped: grouped);
      expect(result.map((e) => e.itemNum), containsAll(['K1', 'K3']));
    });

    test('blank size returns every entry for that component, unfiltered by size', () {
      final result = lookupsFor(componentName: 'kasur', ukuran: '', grouped: grouped);
      expect(result, hasLength(3));
    });

    test('no entries for that component returns empty list, not null/throw', () {
      final result = lookupsFor(componentName: 'headboard', ukuran: '160x200', grouped: grouped);
      expect(result, isEmpty);
    });

    test('component exists but no entry matches the requested size returns empty list', () {
      final result = lookupsFor(componentName: 'kasur', ukuran: '999x999', grouped: grouped);
      expect(result, isEmpty);
    });

    test('empty grouped map never throws, returns empty list', () {
      final result = lookupsFor(componentName: 'kasur', ukuran: '160x200', grouped: const {});
      expect(result, isEmpty);
    });
  });
}
