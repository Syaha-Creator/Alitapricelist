import 'package:alita_pricelist/core/error/app_exception.dart';
import 'package:alita_pricelist/core/router/app_router.dart';
import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_browsing_provider.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_filter_provider.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_master_data_provider.dart';
import 'package:alita_pricelist/features/pricelist/logic/pricelist_search_sort.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

/// Home page (SPEC.md §5 point 2 — there is no separate dashboard): search
/// + sort + a cascading Area→Channel→Brand filter + a masonry product
/// grid, with a visible indicator when the grid is showing a stale local
/// cache instead of a live result.
class PricelistHomePage extends ConsumerWidget {
  const PricelistHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alita Pricelist'),
        actions: [
          IconButton(
            key: const Key('pricelist_sort_button'),
            icon: const Icon(Icons.sort),
            tooltip: 'Urutkan',
            onPressed: () => _showSortSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              key: const Key('pricelist_search_field'),
              decoration: const InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => ref.read(pricelistSearchQueryProvider.notifier).state = value,
            ),
          ),
          const _PricelistFilterPills(),
          const Divider(height: 1),
          const Expanded(child: _PricelistGridBody()),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final current = ref.watch(pricelistSortOptionProvider);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in PricelistSortOption.values)
                    ListTile(
                      key: Key('pricelist_sort_option_${option.name}'),
                      title: Text(option.label),
                      trailing: current == option ? const Icon(Icons.check) : null,
                      onTap: () {
                        ref.read(pricelistSortOptionProvider.notifier).state = option;
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _PricelistFilterPills extends ConsumerWidget {
  const _PricelistFilterPills();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(pricelistFilterProvider);
    final areasAsync = ref.watch(pricelistAreasProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          areasAsync.when(
            data: (areas) => _ChipRow(
              rowKey: 'pricelist_area_chips',
              options: areas.map((a) => a.name).where((name) => name.isNotEmpty).toSet().toList(),
              selected: filter.area,
              onSelected: (value) => ref.read(pricelistFilterProvider.notifier).selectArea(value),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
            error: (error, _) => Text(
              'Gagal memuat area: ${_appExceptionMessage(error)}',
              key: const Key('pricelist_area_error_text'),
            ),
          ),
          if (filter.area != null) ...[
            const SizedBox(height: 8),
            ref
                .watch(pricelistChannelsProvider)
                .when(
                  data: (channels) => _ChipRow(
                    rowKey: 'pricelist_channel_chips',
                    options: channels
                        .map((channel) => channel.channel)
                        .where((name) => name.isNotEmpty)
                        .toSet()
                        .toList(),
                    selected: filter.channel,
                    onSelected: (value) =>
                        ref.read(pricelistFilterProvider.notifier).selectChannel(value),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text(
                    'Gagal memuat channel: ${_appExceptionMessage(error)}',
                    key: const Key('pricelist_channel_error_text'),
                  ),
                ),
          ],
          if (filter.channel != null) ...[
            const SizedBox(height: 8),
            _ChipRow(
              rowKey: 'pricelist_brand_chips',
              options: ref
                  .watch(brandsForSelectedChannelProvider)
                  .map((brand) => brand.brand)
                  .where((name) => name.isNotEmpty)
                  .toSet()
                  .toList(),
              selected: filter.brand,
              onSelected: (value) => ref.read(pricelistFilterProvider.notifier).selectBrand(value),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.rowKey,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String rowKey;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      key: Key(rowKey),
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          return ChoiceChip(
            label: Text(option),
            selected: option == selected,
            onSelected: (_) => onSelected(option),
          );
        },
      ),
    );
  }
}

class _PricelistGridBody extends ConsumerWidget {
  const _PricelistGridBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(pricelistFilterProvider);
    if (filter.area == null || filter.channel == null || filter.brand == null) {
      return const Center(
        key: Key('pricelist_select_filter_prompt'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Pilih Area, Channel, dan Brand untuk melihat produk.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final snapshotAsync = ref.watch(filteredPricelistSnapshotProvider);

    return snapshotAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _appExceptionMessage(error),
            key: const Key('pricelist_error_text'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (snapshot) {
        final items = ref.watch(filteredSortedPricelistItemsProvider);
        return Column(
          children: [
            if (snapshot?.isFromStaleCache ?? false) const _StaleCacheBanner(),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      key: Key('pricelist_empty_text'),
                      child: Text('Tidak ada produk yang cocok.'),
                    )
                  : MasonryGridView.count(
                      key: const Key('pricelist_grid'),
                      padding: const EdgeInsets.all(12),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _PricelistCard(key: ValueKey(items[index].name), item: items[index]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _StaleCacheBanner extends StatelessWidget {
  const _StaleCacheBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('pricelist_stale_cache_banner'),
      width: double.infinity,
      color: Theme.of(context).colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: Theme.of(context).colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Menampilkan data dari cache lokal — koneksi bermasalah.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricelistCard extends StatelessWidget {
  const _PricelistCard({super.key, required this.item});

  final PricelistItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.configurator, extra: item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: item.imageUrl.startsWith('http')
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const _ImagePlaceholder(),
                    )
                  : const _ImagePlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(item.price),
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.bed_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 40,
      ),
    );
  }
}

/// `AppException.message` is already user-safe (SPEC.md §6 — the UI must
/// never render a raw exception); anything else falling through `.when`'s
/// `error` branch (which shouldn't happen, since repositories only ever
/// throw `AppException`) still gets a generic message instead of a raw
/// `toString()` dump.
String _appExceptionMessage(Object error) {
  return error is AppException ? error.message : 'Terjadi kesalahan yang tidak diketahui.';
}

String formatRupiah(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return 'Rp $buffer';
}
