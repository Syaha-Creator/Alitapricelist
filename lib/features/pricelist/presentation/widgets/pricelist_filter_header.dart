import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/filter_pill.dart';
import '../../logic/pricelist_browsing_provider.dart';
import '../../logic/pricelist_filter_provider.dart';
import '../../logic/pricelist_master_data_provider.dart';

/// Area → Channel → Brand filter row, one dropdown-style [FilterPill] per
/// level that opens a bottom-sheet picker on tap — same visual treatment as
/// the legacy app's `FilterHeaderWidget` + `SelectionBottomSheet` ("direct
/// mode" only; the legacy app's "indirect"/toko-picker mode is out of scope
/// for this rewrite, confirmed with the user).
class PricelistFilterHeader extends ConsumerWidget {
  const PricelistFilterHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(pricelistFilterProvider);
    final areasAsync = ref.watch(pricelistAreasProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            areasAsync.when(
              data: (areas) {
                final names = areas.map((a) => a.name).where((name) => name.isNotEmpty).toSet().toList();
                if (names.isEmpty) return const SizedBox.shrink();
                return _FilterPillTrigger(
                  pillKey: const Key('pricelist_area_pill'),
                  listKey: 'pricelist_area_chips',
                  icon: Icons.location_on,
                  placeholder: 'Area',
                  sheetTitle: 'Pilih Area',
                  options: names,
                  selected: filter.area,
                  onSelected: (value) => ref.read(pricelistFilterProvider.notifier).selectArea(value),
                );
              },
              loading: () => const SizedBox(width: 120, child: LinearProgressIndicator()),
              error: (error, _) => Text(
                'Gagal memuat area: ${_appExceptionMessage(error)}',
                key: const Key('pricelist_area_error_text'),
              ),
            ),
            if (filter.area != null) ...[
              const SizedBox(width: 8),
              ref
                  .watch(pricelistChannelsProvider)
                  .when(
                    data: (channels) {
                      final names = channels
                          .map((channel) => channel.channel)
                          .where((name) => name.isNotEmpty)
                          .toSet()
                          .toList();
                      if (names.isEmpty) return const SizedBox.shrink();
                      return _FilterPillTrigger(
                        pillKey: const Key('pricelist_channel_pill'),
                        listKey: 'pricelist_channel_chips',
                        icon: Icons.storefront,
                        placeholder: 'Channel',
                        sheetTitle: 'Pilih Channel',
                        options: names,
                        selected: filter.channel,
                        onSelected: (value) =>
                            ref.read(pricelistFilterProvider.notifier).selectChannel(value),
                      );
                    },
                    loading: () => const SizedBox(width: 120, child: LinearProgressIndicator()),
                    error: (error, _) => Text(
                      'Gagal memuat channel: ${_appExceptionMessage(error)}',
                      key: const Key('pricelist_channel_error_text'),
                    ),
                  ),
            ],
            if (filter.channel != null) ...[
              const SizedBox(width: 8),
              Builder(
                builder: (context) {
                  final names = ref
                      .watch(brandsForSelectedChannelProvider)
                      .map((brand) => brand.brand)
                      .where((name) => name.isNotEmpty)
                      .toSet()
                      .toList();
                  if (names.isEmpty) return const SizedBox.shrink();
                  return _FilterPillTrigger(
                    pillKey: const Key('pricelist_brand_pill'),
                    listKey: 'pricelist_brand_chips',
                    icon: Icons.sell_outlined,
                    placeholder: 'Brand',
                    sheetTitle: 'Pilih Brand',
                    options: names,
                    selected: filter.brand,
                    onSelected: (value) => ref.read(pricelistFilterProvider.notifier).selectBrand(value),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One [FilterPill] that, when tapped, opens a [_SelectionSheet] listing
/// [options]; the list itself is keyed with [listKey] so widget tests can
/// find/tap individual option rows once the sheet is open (mirroring the
/// old `pricelist_area_chips`/`pricelist_channel_chips`/`pricelist_brand_chips`
/// key names, now on the sheet's list instead of inline chips).
class _FilterPillTrigger extends StatelessWidget {
  const _FilterPillTrigger({
    required this.pillKey,
    required this.listKey,
    required this.icon,
    required this.placeholder,
    required this.sheetTitle,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final Key pillKey;
  final String listKey;
  final IconData icon;
  final String placeholder;
  final String sheetTitle;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterPill(
      key: pillKey,
      icon: icon,
      text: selected ?? placeholder,
      isActive: selected != null,
      onTap: () => _showSheet(context),
    );
  }

  Future<void> _showSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _SelectionSheet(
        listKey: listKey,
        title: sheetTitle,
        options: options,
        selected: selected,
        onSelected: (value) {
          onSelected(value);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}

class _SelectionSheet extends StatelessWidget {
  const _SelectionSheet({
    required this.listKey,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String listKey;
  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Flexible(
            child: ListView(
              key: Key(listKey),
              shrinkWrap: true,
              children: [
                for (final option in options)
                  ListTile(
                    title: Text(option),
                    trailing: option == selected
                        ? const Icon(Icons.check, color: AppColors.accent)
                        : null,
                    onTap: () => onSelected(option),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _appExceptionMessage(Object error) {
  return error is AppException ? error.message : 'Terjadi kesalahan yang tidak diketahui.';
}
