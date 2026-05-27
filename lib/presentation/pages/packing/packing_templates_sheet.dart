import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../domain/entities/packing_item.dart';
import '../../../l10n/app_localizations.dart';

class TemplateData {
  final String emoji, name;
  final List<({String name, PackingCategory cat})> items;
  const TemplateData(this.emoji, this.name, this.items);
}

/// Artículos indispensables para cualquier viaje
List<({String name, PackingCategory cat})> getEssentials(AppLocalizations l10n) => [
  (name: l10n.essentialPassport,       cat: PackingCategory.documents),
  (name: l10n.essentialBankCard,       cat: PackingCategory.documents),
  (name: l10n.essentialTravelInsurance, cat: PackingCategory.documents),
  (name: l10n.essentialPrintedReservations, cat: PackingCategory.documents),
  (name: l10n.essentialToiletryBag,    cat: PackingCategory.hygiene),
  (name: l10n.essentialToothbrush,     cat: PackingCategory.hygiene),
  (name: l10n.essentialDeodorant,      cat: PackingCategory.hygiene),
  (name: l10n.essentialPhoneCharger,   cat: PackingCategory.electronics),
  (name: l10n.essentialRegularMedication, cat: PackingCategory.medicine),
  (name: l10n.essentialUnderwear,      cat: PackingCategory.clothing),
  (name: l10n.essentialExtraSocks,     cat: PackingCategory.clothing),
  (name: l10n.essentialHeadphones,     cat: PackingCategory.electronics),
  (name: l10n.essentialWaterBottle,    cat: PackingCategory.accessories),
  (name: l10n.essentialTravelSnacks,  cat: PackingCategory.food),
];

List<TemplateData> getTemplates(AppLocalizations l10n) => [
  TemplateData('🏖️', l10n.templateBeach, [
    (name: l10n.itemSwimsuit,         cat: PackingCategory.clothing),
    (name: l10n.itemSunscreen,        cat: PackingCategory.hygiene),
    (name: l10n.itemSunglasses,       cat: PackingCategory.accessories),
    (name: l10n.itemFlipFlops,        cat: PackingCategory.clothing),
    (name: l10n.itemBeachTowel,       cat: PackingCategory.accessories),
    (name: l10n.itemHat,              cat: PackingCategory.accessories),
    (name: l10n.essentialWaterBottle, cat: PackingCategory.accessories),
  ]),
  TemplateData('⛰️', l10n.templateMountain, [
    (name: l10n.itemHikingBoots,   cat: PackingCategory.sports),
    (name: l10n.itemRainJacket,    cat: PackingCategory.clothing),
    (name: l10n.itemThermalClothing,cat: PackingCategory.clothing),
    (name: l10n.itemBackpack20to30L,cat: PackingCategory.sports),
    (name: l10n.itemTrekkingPoles, cat: PackingCategory.sports),
    (name: l10n.itemHeadlamp,      cat: PackingCategory.accessories),
    (name: l10n.itemFirstAidKit,   cat: PackingCategory.medicine),
  ]),
  TemplateData('🏙️', l10n.templateCity, [
    (name: l10n.itemComfortableSneakers, cat: PackingCategory.clothing),
    (name: l10n.itemUrbanBackpack,        cat: PackingCategory.accessories),
    (name: l10n.itemPowerBank,            cat: PackingCategory.electronics),
    (name: l10n.essentialPhoneCharger,    cat: PackingCategory.electronics),
    (name: l10n.itemCompactUmbrella,      cat: PackingCategory.accessories),
    (name: l10n.itemTravelGuide,         cat: PackingCategory.documents),
  ]),
  TemplateData('💼', l10n.templateBusiness, [
    (name: l10n.itemLaptopCharger,  cat: PackingCategory.electronics),
    (name: l10n.itemFormalWear,      cat: PackingCategory.clothing),
    (name: l10n.itemBusinessCards,  cat: PackingCategory.documents),
    (name: l10n.itemPlugAdapter,    cat: PackingCategory.electronics),
    (name: l10n.itemAncHeadphones,  cat: PackingCategory.electronics),
  ]),
  TemplateData('🎒', l10n.templateWeekend, [
    (name: l10n.itemClothes2to3Days, cat: PackingCategory.clothing),
    (name: l10n.itemBasicToiletryBag, cat: PackingCategory.hygiene),
    (name: l10n.essentialPhoneCharger,cat: PackingCategory.electronics),
    (name: l10n.essentialHeadphones, cat: PackingCategory.electronics),
    (name: l10n.essentialTravelSnacks,cat: PackingCategory.food),
  ]),
  TemplateData('✈️', l10n.templateLongFlight, [
    (name: l10n.itemTravelPillow,      cat: PackingCategory.accessories),
    (name: l10n.itemSleepMask,          cat: PackingCategory.accessories),
    (name: l10n.itemEarplugs,           cat: PackingCategory.accessories),
    (name: l10n.itemLiquidsBag100ml,    cat: PackingCategory.hygiene),
    (name: l10n.itemWarmClothing,       cat: PackingCategory.clothing),
    (name: l10n.essentialHeadphones,   cat: PackingCategory.electronics),
    (name: l10n.essentialRegularMedication, cat: PackingCategory.medicine),
  ]),
];

/// Sheet reutilizable de plantillas y artículos esenciales.
/// Se puede usar tanto desde la lista de maletas como desde el detalle de una maleta.
class PackingTemplatesSheet extends StatefulWidget {
  final void Function(TemplateData) onSelectTemplate;
  final void Function(List<({String name, PackingCategory cat})>) onAddEssentials;
  const PackingTemplatesSheet({
    required this.onSelectTemplate,
    required this.onAddEssentials,
  });

  @override
  State<PackingTemplatesSheet> createState() => _PackingTemplatesSheetState();
}

class _PackingTemplatesSheetState extends State<PackingTemplatesSheet> {
  int? _expanded;
  final Set<int> _selectedEssentials = {};
  bool _showEssentials = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final essentials = getEssentials(l10n);
    final templates = getTemplates(l10n);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scroll) => Column(children: [
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.symmetric(vertical: AppSizes.md),
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingH),
          child: Row(children: [
            Text(l10n.templates, style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            Text(l10n.templatesAvailable(templates.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight)),
          ]),
        ),
        const SizedBox(height: AppSizes.sm),

        // ── Artículos esenciales ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingH),
          child: InkWell(
            onTap: () => setState(() => _showEssentials = !_showEssentials),
            borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Text('🎒', style: TextStyle(fontSize: 20)),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context).essentialsTitle,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.primary)),
                      Text(AppLocalizations.of(context).essentialsSubtitle,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(_showEssentials
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary),
              ]),
            ),
          ),
        ),

        if (_showEssentials) ...([
          const SizedBox(height: AppSizes.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingH),
            child: Wrap(
              spacing: AppSizes.xs,
              runSpacing: AppSizes.xs,
              children: List.generate(essentials.length, (i) {
                final e = essentials[i];
                final selected = _selectedEssentials.contains(i);
                return FilterChip(
                  label: Text(e.name, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  checkmarkColor: AppColors.primary,
                  onSelected: (_) => setState(() {
                    selected
                        ? _selectedEssentials.remove(i)
                        : _selectedEssentials.add(i);
                  }),
                );
              }),
            ),
          ),
          if (_selectedEssentials.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPaddingH, AppSizes.sm,
                  AppSizes.screenPaddingH, 0),
              child: ElevatedButton.icon(
                onPressed: () {
                  final sel = _selectedEssentials
                      .map((i) => essentials[i])
                      .toList();
                  Navigator.pop(context);
                  widget.onAddEssentials(sel);
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(AppLocalizations.of(context).addEssentials(_selectedEssentials.length)),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44)),
              ),
            ),
          const SizedBox(height: AppSizes.md),
        ]),

        const Divider(height: 1),
        const SizedBox(height: AppSizes.sm),

        // ── Lista de plantillas ───────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPaddingH, 0,
                AppSizes.screenPaddingH, AppSizes.xl),
            itemCount: templates.length,
            itemBuilder: (ctx, i) {
              final t = templates[i];
              final isOpen = _expanded == i;
              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                elevation: isOpen ? 2 : 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    side: BorderSide(
                        color: isOpen
                            ? AppColors.primary.withOpacity(0.3)
                            : Colors.transparent)),
                child: Column(children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    onTap: () => setState(
                        () => _expanded = isOpen ? null : i),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.md),
                      child: Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(t.emoji,
                                style: const TextStyle(fontSize: 24))),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name,
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 2),
                            Text(AppLocalizations.of(context).templateItemsCount(t.items.length),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondaryLight)),
                          ],
                        )),
                        Icon(isOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primary),
                      ]),
                    ),
                  ),
                  if (isOpen) ...([
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizes.md, AppSizes.sm, AppSizes.md, 0),
                      child: Wrap(
                        spacing: AppSizes.xs,
                        runSpacing: AppSizes.xs,
                        children: t.items.map((item) => Chip(
                          label: Text(item.name,
                              style: const TextStyle(fontSize: 12)),
                          avatar: Text(item.cat.emoji,
                              style: const TextStyle(fontSize: 12)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        )).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.md),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onSelectTemplate(t);
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(AppLocalizations.of(context).useTemplate),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44)),
                      ),
                    ),
                  ]),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}
