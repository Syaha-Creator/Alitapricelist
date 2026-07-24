import 'package:alita_pricelist/features/pricelist/logic/pricelist_filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  test('starts with nothing selected', () {
    final state = container.read(pricelistFilterProvider);
    expect(state.area, isNull);
    expect(state.channel, isNull);
    expect(state.brand, isNull);
  });

  test('selectArea sets the area and leaves channel/brand null', () {
    container.read(pricelistFilterProvider.notifier).selectArea('Nasional');

    final state = container.read(pricelistFilterProvider);
    expect(state.area, 'Nasional');
    expect(state.channel, isNull);
    expect(state.brand, isNull);
  });

  test('selectChannel sets the channel and leaves brand null, keeps area', () {
    final notifier = container.read(pricelistFilterProvider.notifier);
    notifier.selectArea('Nasional');
    notifier.selectChannel('Direct');

    final state = container.read(pricelistFilterProvider);
    expect(state.area, 'Nasional');
    expect(state.channel, 'Direct');
    expect(state.brand, isNull);
  });

  test('selectBrand sets the brand and keeps area/channel', () {
    final notifier = container.read(pricelistFilterProvider.notifier);
    notifier.selectArea('Nasional');
    notifier.selectChannel('Direct');
    notifier.selectBrand('Comforta');

    final state = container.read(pricelistFilterProvider);
    expect(state.area, 'Nasional');
    expect(state.channel, 'Direct');
    expect(state.brand, 'Comforta');
  });

  test('changing area after channel+brand were already selected resets both channel and brand '
      '(the exact guard requested: no leftover channel/brand from a previous area)', () {
    final notifier = container.read(pricelistFilterProvider.notifier);
    notifier.selectArea('Nasional');
    notifier.selectChannel('Direct');
    notifier.selectBrand('Comforta');

    notifier.selectArea('Jawa Barat');

    final state = container.read(pricelistFilterProvider);
    expect(state.area, 'Jawa Barat');
    expect(state.channel, isNull);
    expect(state.brand, isNull);
  });

  test('changing channel after brand was already selected resets brand, keeps area', () {
    final notifier = container.read(pricelistFilterProvider.notifier);
    notifier.selectArea('Nasional');
    notifier.selectChannel('Direct');
    notifier.selectBrand('Comforta');

    notifier.selectChannel('Indirect');

    final state = container.read(pricelistFilterProvider);
    expect(state.area, 'Nasional');
    expect(state.channel, 'Indirect');
    expect(state.brand, isNull);
  });

  test('reset() clears everything back to the initial state', () {
    final notifier = container.read(pricelistFilterProvider.notifier);
    notifier.selectArea('Nasional');
    notifier.selectChannel('Direct');
    notifier.selectBrand('Comforta');

    notifier.reset();

    final state = container.read(pricelistFilterProvider);
    expect(state.area, isNull);
    expect(state.channel, isNull);
    expect(state.brand, isNull);
  });
}
