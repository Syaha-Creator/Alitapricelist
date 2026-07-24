import 'package:alita_pricelist/features/configurator/logic/configurator_provider.dart';
import 'package:alita_pricelist/features/configurator/logic/item_lookup_grouping.dart';
import 'package:alita_pricelist/features/configurator/logic/price_calculator.dart';
import 'package:alita_pricelist/features/configurator/logic/variant_resolver.dart';
import 'package:alita_pricelist/features/pricelist/data/models/pricelist_item.dart';
import 'package:alita_pricelist/features/pricelist/presentation/pricelist_home_page.dart' show formatRupiah;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configurator/detail page (SPEC.md §5.3 / §8 Step 4) — reached by tapping
/// a product card on [PricelistHomePage]. All calculation stays behind the
/// providers in `configurator_provider.dart`; this page only reads
/// `ref.watch(...)` and renders (SPEC.md §6 — no calc logic in the widget
/// layer).
class ConfiguratorPage extends ConsumerWidget {
  const ConfiguratorPage({super.key, required this.item});

  final PricelistItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siblings = ref.watch(configuratorSiblingsProvider(item));
    final sizes = distinctVariantSizes(siblings);
    final activeItem = ref.watch(configuratorActiveVariantProvider(item));
    final result = ref.watch(configuratorPriceResultProvider(item));

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductHeader(item: activeItem),
            const SizedBox(height: 16),
            if (sizes.length > 1) ...[
              _SizePicker(sizes: sizes, activeUkuran: activeItem.ukuran),
              const SizedBox(height: 16),
            ],
            _PriceBreakdownCard(item: activeItem, result: result),
            const SizedBox(height: 16),
            _ModeToggle(),
            const SizedBox(height: 16),
            _InputSection(item: item, activeItem: activeItem),
            const SizedBox(height: 16),
            if (result.isFloorApplied) const _FloorBanner(),
            if (result.isMarkup) const _MarkupBanner(),
            const SizedBox(height: 16),
            _KainWarnaSection(item: item, activeItem: activeItem),
          ],
        ),
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.item});

  final PricelistItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 88,
            height: 88,
            child: item.imageUrl.startsWith('http')
                ? Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _imagePlaceholder(context),
                  )
                : _imagePlaceholder(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (item.ukuran.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Ukuran: ${item.ukuran}'),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.bed_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

class _SizePicker extends ConsumerWidget {
  const _SizePicker({required this.sizes, required this.activeUkuran});

  final List<String> sizes;
  final String activeUkuran;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Ukuran', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final size in sizes)
              ChoiceChip(
                key: Key('configurator_size_chip_$size'),
                label: Text(size),
                selected: size == activeUkuran,
                onSelected: (_) => ref.read(configuratorSelectedUkuranProvider.notifier).state = size,
              ),
          ],
        ),
      ],
    );
  }
}

class _PriceBreakdownCard extends StatelessWidget {
  const _PriceBreakdownCard({required this.item, required this.result});

  final PricelistItem item;
  final PriceCalculationResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rincian Harga', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _row(context, 'Harga Dasar (EUP)', formatRupiah(result.baseTotalEup)),
            for (var i = 0; i < result.appliedDiscounts.length; i++)
              _row(context, 'Diskon tier ${i + 1}', '${(result.appliedDiscounts[i] * 100).toStringAsFixed(1)}%'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Harga Akhir', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  formatRupiah(result.finalPrice),
                  key: const Key('configurator_final_price_text'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }
}

class _ModeToggle extends ConsumerWidget {
  const _ModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(configuratorInputModeProvider);
    return SegmentedButton<ConfiguratorInputMode>(
      key: const Key('configurator_mode_toggle'),
      segments: const [
        ButtonSegment(value: ConfiguratorInputMode.manualTiers, label: Text('Diskon Manual')),
        ButtonSegment(value: ConfiguratorInputMode.targetPrice, label: Text('Harga Target')),
      ],
      selected: {mode},
      onSelectionChanged: (selection) =>
          ref.read(configuratorInputModeProvider.notifier).state = selection.first,
    );
  }
}

class _InputSection extends ConsumerWidget {
  const _InputSection({required this.item, required this.activeItem});

  final PricelistItem item;
  final PricelistItem activeItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(configuratorInputModeProvider);
    if (mode == ConfiguratorInputMode.manualTiers) {
      return _ManualTiersInput(item: item, activeItem: activeItem);
    }
    return _TargetPriceInput(item: item);
  }
}

class _ManualTiersInput extends ConsumerWidget {
  const _ManualTiersInput({required this.item, required this.activeItem});

  final PricelistItem item;
  final PricelistItem activeItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ceilings = nonZeroDiscountCeilings(activeItem);
    if (ceilings.isEmpty) return const SizedBox.shrink();

    final discounts = ref.watch(configuratorManualDiscountsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Diskon per Tier', style: Theme.of(context).textTheme.titleSmall),
        for (var i = 0; i < ceilings.length; i++)
          _TierSlider(
            key: Key('configurator_discount_slider_$i'),
            index: i,
            ceiling: ceilings[i],
            value: i < discounts.length ? discounts[i].clamp(0, ceilings[i]) : 0.0,
            onChanged: (value) {
              final updated = List<double>.of(discounts);
              while (updated.length <= i) {
                updated.add(0);
              }
              updated[i] = value.clamp(0, ceilings[i]);
              ref.read(configuratorManualDiscountsProvider.notifier).state = updated;
            },
          ),
      ],
    );
  }
}

class _TierSlider extends StatelessWidget {
  const _TierSlider({
    super.key,
    required this.index,
    required this.ceiling,
    required this.value,
    required this.onChanged,
  });

  final int index;
  final double ceiling;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 64, child: Text('Tier ${index + 1}')),
        Expanded(
          child: Slider(
            value: value.clamp(0, ceiling),
            min: 0,
            max: ceiling,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 56, child: Text('${(value * 100).toStringAsFixed(1)}%')),
      ],
    );
  }
}

class _TargetPriceInput extends ConsumerStatefulWidget {
  const _TargetPriceInput({required this.item});

  final PricelistItem item;

  @override
  ConsumerState<_TargetPriceInput> createState() => _TargetPriceInputState();
}

class _TargetPriceInputState extends ConsumerState<_TargetPriceInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Harga Target', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          key: const Key('configurator_target_price_field'),
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Masukkan harga akhir yang diinginkan',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) {
            final parsed = double.tryParse(value.trim());
            ref.read(configuratorTargetPriceProvider.notifier).state = parsed;
          },
        ),
      ],
    );
  }
}

class _FloorBanner extends StatelessWidget {
  const _FloorBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('configurator_floor_banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Harga disesuaikan ke batas minimum (floor price).',
              style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkupBanner extends StatelessWidget {
  const _MarkupBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('configurator_markup_banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: Theme.of(context).colorScheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Harga di atas harga dasar (markup).',
              style: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _KainWarnaSection extends ConsumerWidget {
  const _KainWarnaSection({required this.item, required this.activeItem});

  final PricelistItem item;
  final PricelistItem activeItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(configuratorGroupedLookupsProvider);
    if (grouped == null) return const SizedBox.shrink();

    final lookups = lookupsFor(componentName: 'kasur', ukuran: activeItem.ukuran, grouped: grouped);
    if (lookups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilihan Kain/Warna', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final lookup in lookups)
              Chip(label: Text(_lookupLabel(lookup.jenisKain, lookup.warnaKain))),
          ],
        ),
      ],
    );
  }

  String _lookupLabel(String? jenisKain, String? warnaKain) {
    final parts = [
      if (jenisKain != null && jenisKain.isNotEmpty) jenisKain,
      if (warnaKain != null && warnaKain.isNotEmpty) warnaKain,
    ];
    return parts.isEmpty ? '-' : parts.join(' - ');
  }
}