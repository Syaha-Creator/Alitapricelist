import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cascading Area → Channel → Brand selection. A Dart record (not Freezed —
/// nothing here needs anything beyond value equality) so tests can compare
/// states with plain `==`.
typedef PricelistFilterState = ({String? area, String? channel, String? brand});

const _initialPricelistFilterState = (area: null, channel: null, brand: null);

/// Manual (non-generated) Riverpod provider — see the note in
/// `bootstrap_provider.dart` for why `riverpod_generator` isn't used here.
final pricelistFilterProvider = NotifierProvider<PricelistFilterNotifier, PricelistFilterState>(
  PricelistFilterNotifier.new,
);

/// Single source of truth for the cascading filter, so the "changing a
/// higher level resets everything below it" guard lives in one place
/// instead of being reconstructed via `ref.listen` on 3 separate
/// `StateProvider`s (which is easy to get subtly wrong/inconsistent).
class PricelistFilterNotifier extends Notifier<PricelistFilterState> {
  @override
  PricelistFilterState build() => _initialPricelistFilterState;

  /// Changing the area invalidates any previously-selected channel/brand —
  /// they belonged to the *previous* area and must never carry over.
  void selectArea(String area) {
    state = (area: area, channel: null, brand: null);
  }

  /// Changing the channel invalidates any previously-selected brand (brands
  /// are filtered by channel — see `brandsForSelectedChannelProvider`).
  void selectChannel(String channel) {
    state = (area: state.area, channel: channel, brand: null);
  }

  void selectBrand(String brand) {
    state = (area: state.area, channel: state.channel, brand: brand);
  }

  void reset() {
    state = _initialPricelistFilterState;
  }
}
