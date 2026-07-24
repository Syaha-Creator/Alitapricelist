import 'dart:io';

import 'package:alita_pricelist/features/pricelist/data/local/pricelist_cache_store.dart';
import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late PricelistCacheStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pricelist_cache_test_');
    store = PricelistCacheStore(directory: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  const item = PricelistItem(
    id: '1',
    name: 'Comforta Elite 160x200',
    price: 5000000,
    channel: 'Direct',
    brand: 'Comforta',
    kasur: 'Comforta Elite',
    ukuran: '160x200',
  );

  test('keyFor is stable and distinct per area/channel/brand combination', () {
    final keyA = store.keyFor(area: 'Nasional', channel: 'Direct', brand: 'Comforta');
    final keyASameCaseTrim = store.keyFor(area: ' nasional ', channel: 'DIRECT', brand: 'comforta');
    final keyB = store.keyFor(area: 'Nasional', channel: 'Direct', brand: 'Simmons');

    expect(keyA, keyASameCaseTrim);
    expect(keyA, isNot(keyB));
  });

  test('save then load round-trips the item list', () async {
    final key = store.keyFor(area: 'Nasional', channel: 'Direct', brand: 'Comforta');

    final saveResult = await store.save(key, [item]);
    expect(saveResult.isSuccess, isTrue);

    final snapshot = await store.load(key);
    expect(snapshot, isNotNull);
    expect(snapshot!.items, [item]);
  });

  test('load returns null when there is no cache for that key', () async {
    final snapshot = await store.load('never_saved');
    expect(snapshot, isNull);
  });

  test('load returns null (not a throw) when the cache file is corrupt', () async {
    final key = store.keyFor(area: 'Nasional', channel: 'Direct', brand: 'Comforta');
    final file = File('${tempDir.path}/pl_cache_$key.json');
    await file.create(recursive: true);
    await file.writeAsString('not valid json {{{');

    final snapshot = await store.load(key);
    expect(snapshot, isNull);
  });

  test('cachedAt reflects when the snapshot was saved', () async {
    final key = store.keyFor(area: 'Nasional', channel: 'Direct', brand: 'Comforta');
    final before = DateTime.now();

    await store.save(key, [item]);
    final snapshot = await store.load(key);

    expect(snapshot!.cachedAt.isBefore(before.add(const Duration(seconds: 5))), isTrue);
    expect(snapshot.cachedAt.isAfter(before.subtract(const Duration(seconds: 5))), isTrue);
  });
}
