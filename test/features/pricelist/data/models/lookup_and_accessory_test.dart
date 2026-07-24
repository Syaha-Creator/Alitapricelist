import 'package:alita_pricelist/features/pricelist/data/models/accessory.dart';
import 'package:alita_pricelist/features/pricelist/data/models/item_lookup_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ItemLookupEntry.fromJson', () {
    test('parses a fully-populated row', () {
      final entry = ItemLookupEntry.fromJson({
        'tipe': 'Kasur',
        'ukuran': '160x200',
        'item_num': 'KSR-001',
        'jenis_kain': 'Katun',
        'warna_kain': 'Putih',
      });
      expect(entry.tipe, 'Kasur');
      expect(entry.ukuran, '160x200');
      expect(entry.itemNum, 'KSR-001');
      expect(entry.jenisKain, 'Katun');
      expect(entry.warnaKain, 'Putih');
    });

    test('defaults required fields to empty string and optional fields to null', () {
      final entry = ItemLookupEntry.fromJson(const {});
      expect(entry.tipe, '');
      expect(entry.ukuran, '');
      expect(entry.itemNum, '');
      expect(entry.jenisKain, isNull);
      expect(entry.warnaKain, isNull);
    });
  });

  group('parseLookupOrAccessoryEnvelope', () {
    test('returns the result list when status is success', () {
      final rows = parseLookupOrAccessoryEnvelope({
        'status': 'success',
        'result': [
          {'tipe': 'Kasur'},
        ],
      });
      expect(rows, [
        {'tipe': 'Kasur'},
      ]);
    });

    test('falls back to data when result is absent', () {
      final rows = parseLookupOrAccessoryEnvelope({
        'status': 'success',
        'data': [
          {'tipe': 'Kasur'},
        ],
      });
      expect(rows, [
        {'tipe': 'Kasur'},
      ]);
    });

    test('returns an empty list when status is not success', () {
      final rows = parseLookupOrAccessoryEnvelope({
        'status': 'error',
        'result': [
          {'tipe': 'Kasur'},
        ],
      });
      expect(rows, isEmpty);
    });

    test('returns an empty list for null/garbage input', () {
      expect(parseLookupOrAccessoryEnvelope(null), isEmpty);
      expect(parseLookupOrAccessoryEnvelope('garbage'), isEmpty);
    });
  });

  group('Accessory.fromJson', () {
    test('parses a fully-populated row', () {
      final accessory = Accessory.fromJson({
        'tipe': 'Bantal',
        'item_num': 'ACC-001',
        'ukuran': '40x60',
        'pricelist': 150000,
      });
      expect(accessory.tipe, 'Bantal');
      expect(accessory.itemNum, 'ACC-001');
      expect(accessory.ukuran, '40x60');
      expect(accessory.pricelist, 150000.0);
    });

    test('defaults to empty string/zero when fields are missing', () {
      final accessory = Accessory.fromJson(const {});
      expect(accessory.tipe, '');
      expect(accessory.itemNum, '');
      expect(accessory.ukuran, '');
      expect(accessory.pricelist, 0.0);
    });
  });
}
