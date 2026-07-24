import 'package:alita_pricelist/features/pricelist/data/models/master_data.dart';
import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';

/// Brands are filtered down to the ones belonging to [channel] via the
/// client-side `pl_channel_id` join documented in `tasks/plan.md` (there is
/// no "brands for this channel" endpoint). A `null` channel (nothing
/// selected yet) yields no brands — the UI shouldn't show a brand picker
/// before a channel is chosen.
List<Brand> brandsForChannel({required List<Brand> brands, required Channel? channel}) {
  if (channel == null) return const [];
  return brands.where((brand) => brand.plChannelId == channel.id).toList();
}

/// `filtered_pl` returns one row per size/variant of a mattress model
/// (`PricelistItem.name` is `"<kasur> <ukuran>"`, so it's different for
/// every size) — this collapses every row belonging to the same *model*
/// into a single representative for the grid, picking the lowest
/// *positive* price among its variants. Verified against the legacy app's
/// `groupProductsByVariantModel` (confirmed with the user, not assumed) —
/// grouping by the full `name` (including size) would produce one card per
/// size, defeating the point of grouping entirely.
///
/// The returned item's `name` is overwritten with the model group name
/// (e.g. `"Comforta Elite"`, not `"Comforta Elite 160x200"`) so the grid
/// card title reads as a model, not a specific size.
///
/// A price of `0` (or negative — treated the same, never expected but not
/// trusted either) is never preferred over a positive one, but a group
/// where *every* variant has a non-positive price still keeps one
/// representative rather than disappearing from the grid entirely.
List<PricelistItem> groupPricelistItemsByName(List<PricelistItem> items) {
  final grouped = <String, PricelistItem>{};
  for (final item in items) {
    final groupName = _modelGroupName(item);
    final existing = grouped[groupName];
    if (existing == null) {
      grouped[groupName] = item.copyWith(name: groupName);
      continue;
    }
    final itemIsCheaperAndPositive =
        item.price > 0 && (existing.price <= 0 || item.price < existing.price);
    if (itemIsCheaperAndPositive) {
      grouped[groupName] = item.copyWith(name: groupName);
    }
  }
  return grouped.values.toList();
}

/// The mattress model is normally `kasur` — but a row with no mattress
/// component at all (bare frame, headboard-only, accessory row, ...) has
/// `kasur` empty or literally `"Tanpa Kasur"` ("no mattress"), in which
/// case the next non-empty component becomes the group's identity instead.
String _modelGroupName(PricelistItem item) {
  for (final (value, placeholder) in [
    (item.kasur, 'tanpa kasur'),
    (item.divan, 'tanpa divan'),
    (item.headboard, 'tanpa headboard'),
    (item.sorong, 'tanpa sorong'),
  ]) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && trimmed.toLowerCase() != placeholder) {
      return trimmed;
    }
  }
  return item.name;
}
