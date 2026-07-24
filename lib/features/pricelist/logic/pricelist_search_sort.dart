import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';

/// Deliberately narrower than the legacy app's `SortOption` (which also had
/// a `newest` option that was really a no-op — there is no real "when was
/// this added" timestamp on a pricelist row to sort by).
enum PricelistSortOption {
  nameAsc('Nama (A-Z)'),
  priceAsc('Harga: Rendah ke Tinggi'),
  priceDesc('Harga: Tinggi ke Rendah');

  const PricelistSortOption(this.label);

  final String label;
}

/// Search matches the product name only — not `description`, which is
/// frequently just a boilerplate placeholder (see `PricelistItem.fromJson`)
/// and would produce confusing false matches (confirmed with the user).
List<PricelistItem> filterAndSortPricelistItems({
  required List<PricelistItem> items,
  required String searchQuery,
  required PricelistSortOption sortOption,
}) {
  final query = searchQuery.trim().toLowerCase();
  final filtered = query.isEmpty
      ? List<PricelistItem>.from(items)
      : items.where((item) => item.name.toLowerCase().contains(query)).toList();

  switch (sortOption) {
    case PricelistSortOption.nameAsc:
      filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    case PricelistSortOption.priceAsc:
      filtered.sort((a, b) => a.price.compareTo(b.price));
    case PricelistSortOption.priceDesc:
      filtered.sort((a, b) => b.price.compareTo(a.price));
  }
  return filtered;
}
