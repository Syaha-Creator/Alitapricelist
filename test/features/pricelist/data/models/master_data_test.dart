import 'package:alita_pricelist/features/pricelist/data/models/master_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Area.fromJson', () {
    test('reads name', () {
      expect(Area.fromJson({'name': 'Nasional'}).name, 'Nasional');
    });

    test('falls back to area key when name is missing', () {
      expect(Area.fromJson({'area': 'Jawa Barat'}).name, 'Jawa Barat');
    });

    test('defaults to empty string when both keys are missing', () {
      expect(Area.fromJson(const {}).name, '');
    });
  });

  group('Channel.fromJson', () {
    test('reads id and channel name', () {
      final channel = Channel.fromJson({'id': 223, 'channel': 'Direct'});
      expect(channel.id, 223);
      expect(channel.channel, 'Direct');
    });

    test('parses a string id', () {
      expect(Channel.fromJson({'id': '223', 'channel': 'Direct'}).id, 223);
    });

    test('defaults id to 0 and channel to empty string when missing', () {
      final channel = Channel.fromJson(const {});
      expect(channel.id, 0);
      expect(channel.channel, '');
    });
  });

  group('Brand.fromJson', () {
    test('reads id, brand name, and pl_channel_id', () {
      final brand = Brand.fromJson({'id': 622, 'brand': 'Comforta', 'pl_channel_id': 223});
      expect(brand.id, 622);
      expect(brand.brand, 'Comforta');
      expect(brand.plChannelId, 223);
    });

    test('defaults everything when fields are missing', () {
      final brand = Brand.fromJson(const {});
      expect(brand.id, 0);
      expect(brand.brand, '');
      expect(brand.plChannelId, 0);
    });
  });

  group('parseMasterDataEnvelope', () {
    test('accepts a bare list', () {
      final result = parseMasterDataEnvelope([
        {'name': 'A'},
      ], listKey: 'pl_areas');
      expect(result, [
        {'name': 'A'},
      ]);
    });

    test('accepts {"data": [...]}', () {
      final result = parseMasterDataEnvelope({
        'data': [
          {'name': 'A'},
        ],
      }, listKey: 'pl_areas');
      expect(result, [
        {'name': 'A'},
      ]);
    });

    test('accepts {"<listKey>": [...]}', () {
      final result = parseMasterDataEnvelope({
        'pl_areas': [
          {'name': 'A'},
        ],
      }, listKey: 'pl_areas');
      expect(result, [
        {'name': 'A'},
      ]);
    });

    test('accepts a nested {"result": {"data": [...]}}', () {
      final result = parseMasterDataEnvelope({
        'result': {
          'data': [
            {'name': 'A'},
          ],
        },
      }, listKey: 'pl_areas');
      expect(result, [
        {'name': 'A'},
      ]);
    });

    test('accepts a nested {"result": [...]}', () {
      final result = parseMasterDataEnvelope({
        'result': [
          {'name': 'A'},
        ],
      }, listKey: 'pl_areas');
      expect(result, [
        {'name': 'A'},
      ]);
    });

    test('drops entries that are not maps instead of throwing', () {
      final result = parseMasterDataEnvelope([
        {'name': 'A'},
        'not a map',
        42,
      ], listKey: 'pl_areas');
      expect(result, [
        {'name': 'A'},
      ]);
    });

    test('returns an empty list for null, unrecognized shapes, or garbage', () {
      expect(parseMasterDataEnvelope(null, listKey: 'pl_areas'), isEmpty);
      expect(parseMasterDataEnvelope('garbage', listKey: 'pl_areas'), isEmpty);
      expect(parseMasterDataEnvelope({'unexpected': 'shape'}, listKey: 'pl_areas'), isEmpty);
    });
  });
}
