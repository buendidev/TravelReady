import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../domain/entities/packing_item.dart';
import '../../../injection/injection.dart';
import '../../bloc/packing/packing_bloc.dart';
import '../../widgets/common/tr_loading.dart';
import '../../widgets/common/tr_text_field.dart';
import 'packing_templates_sheet.dart';

class PackingDetailPage extends StatelessWidget {
  final String listId;
  final String tripId;
  const PackingDetailPage({
    super.key,
    required this.listId,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PackingBloc>(
      create: (_) => PackingBloc(repo: getIt())
        ..add(PackingListsLoaded(tripId: tripId)),
      child: _DetailContent(listId: listId, tripId: tripId),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final String listId, tripId;
  const _DetailContent({required this.listId, required this.tripId});

  /// Abre sheet de plantillas y añade items directamente a esta lista.
  void _showTemplates(BuildContext context) {
    final bloc = context.read<PackingBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusLg))),
      builder: (_) => PackingTemplatesSheet(
        onSelectTemplate: (t) {
          for (final item in t.items) {
            bloc.add(PackingItemAdded(
              listId:   listId,
              tripId:   tripId,
              name:     item.name,
              category: item.cat,
            ));
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).creatingTemplate(t.name)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ));
        },
        onAddEssentials: (items) {
          for (final item in items) {
            bloc.add(PackingItemAdded(
              listId:   listId,
              tripId:   tripId,
              name:     item.name,
              category: item.cat,
            ));
          }
          final state = bloc.state;
          final listName = state is PackingListsReady
              ? state.lists.where((l) => l.id == listId).firstOrNull?.name ?? listId
              : listId;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).essentialsAdded(items.length, listName)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ));
        },
      ),
    );
  }

  /// Captura el bloc ANTES de abrir el modal para evitar context stale.
  void _showAddItem(BuildContext context) {
    final bloc = context.read<PackingBloc>(); // captura aquí, fuera del builder

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusLg))),
      builder: (sheetCtx) => _AddItemSheet(
        bloc:   bloc,
        listId: listId,
        tripId: tripId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<PackingBloc, PackingState>(
          builder: (_, state) {
            if (state is PackingListsReady) {
              final list = state.lists.where((l) => l.id == listId).firstOrNull;
              return Text(list?.name ?? l10n.packingList);
            }
            return Text(l10n.packingList);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_add_outlined),
            tooltip: l10n.templates,
            onPressed: () => _showTemplates(context),
          ),
        ],
      ),
      body: BlocBuilder<PackingBloc, PackingState>(
        builder: (context, state) {
          if (state is PackingLoading) return const TRLoading();
          if (state is PackingError) {
            return TRErrorWidget(
              message: state.message,
              onRetry: () => context.read<PackingBloc>()
                  .add(PackingListsLoaded(tripId: tripId)),
            );
          }
          if (state is! PackingListsReady) return const TRLoading();

          final list = state.lists.where((l) => l.id == listId).firstOrNull;
          if (list == null) {
            return Center(child: Text(l10n.listNotFound));
          }

          if (list.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.checklist_rounded,
                      size: 64, color: AppColors.primary),
                  const SizedBox(height: AppSizes.md),
                  Text(l10n.emptyList,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSizes.sm),
                  Text(l10n.addItemsHint,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppSizes.xl),
                  ElevatedButton.icon(
                    onPressed: () => _showAddItem(context),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.addItem),
                  ),
                  const SizedBox(height: AppSizes.md),
                  OutlinedButton.icon(
                    onPressed: () => _showTemplates(context),
                    icon: const Icon(Icons.library_add_outlined),
                    label: Text(l10n.templates),
                  ),
                ]),
              ),
            );
          }

          final byCat = <PackingCategory, List<PackingItem>>{};
          for (final item in list.items) {
            byCat.putIfAbsent(item.category, () => []).add(item);
          }

          return CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.screenPaddingH),
                child: _ProgressHeader(list: list),
              ),
            ),
            for (final entry in byCat.entries) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.screenPaddingH, AppSizes.md,
                      AppSizes.screenPaddingH, AppSizes.sm),
                  child: Text(
                    '${entry.key.emoji}  ${entry.key.localizedLabel(l10n).toUpperCase()}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2, color: AppColors.primary),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPaddingH),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _ItemTile(
                      item: entry.value[i],
                      onToggle: () => context
                          .read<PackingBloc>()
                          .add(PackingItemToggled(entry.value[i])),
                      onDelete: () => context
                          .read<PackingBloc>()
                          .add(PackingItemDeleted(entry.value[i])),
                    ),
                    childCount: entry.value.length,
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.screenPaddingH),
                child: Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddItem(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.addItem),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showTemplates(context),
                      icon: const Icon(Icons.library_add_outlined, size: 18),
                      label: Text(l10n.templates),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xxxl)),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItem(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

// ── Sheet añadir artículo (widget propio — sin context stale) ─────────────────

class _AddItemSheet extends StatefulWidget {
  final PackingBloc bloc;
  final String listId, tripId;
  const _AddItemSheet({
    required this.bloc,
    required this.listId,
    required this.tripId,
  });
  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameCtrl = TextEditingController();
  PackingCategory _cat = PackingCategory.other;
  int _qty = 1;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) return;
    widget.bloc.add(PackingItemAdded(
      listId:   widget.listId,
      tripId:   widget.tripId,
      name:     _nameCtrl.text.trim(),
      category: _cat,
      quantity: _qty,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPaddingH,
        AppSizes.md,
        AppSizes.screenPaddingH,
        MediaQuery.of(context).viewInsets.bottom + AppSizes.xl,
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: AppSizes.md),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
            ),
          ),
          Text(l10n.addItem,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSizes.md),

          TRTextField(
            label: l10n.itemName,
            hint: l10n.listNameHint,
            controller: _nameCtrl,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSizes.md),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(l10n.categoryLabel,
                style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.xs,
            children: PackingCategory.values.map((c) => FilterChip(
              label: Text('${c.emoji} ${c.localizedLabel(l10n)}'),
              selected: c == _cat,
              onSelected: (_) => setState(() => _cat = c),
              selectedColor: AppColors.primary.withOpacity(0.15),
              checkmarkColor: AppColors.primary,
            )).toList(),
          ),

          const SizedBox(height: AppSizes.md),
          Row(children: [
            Text(l10n.quantityLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(width: AppSizes.md),
            IconButton(
              onPressed: () => setState(() => _qty = (_qty - 1).clamp(1, 99)),
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            Text('$_qty', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              onPressed: () => setState(() => _qty = (_qty + 1).clamp(1, 99)),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ]),

          const SizedBox(height: AppSizes.lg),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, AppSizes.buttonHeight)),
            child: Text(l10n.addItem),
          ),
        ]),
      ),
    );
  }
}

// ── ProgressHeader ────────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  final PackingList list;
  const _ProgressHeader({required this.list});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(
      color: AppColors.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
    ),
    child: Row(children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.itemsCountOf(list.packedItems, list.totalItems),
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: LinearProgressIndicator(
              value: list.totalItems == 0 ? 0 : list.packedItems / list.totalItems,
              minHeight: 8,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      )),
      const SizedBox(width: AppSizes.md),
      Text('${list.progress}%',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w700)),
    ]),
  );
  }
}

// ── ItemTile ──────────────────────────────────────────────────────────────────

class _ItemTile extends StatelessWidget {
  final PackingItem item;
  final VoidCallback onToggle, onDelete;
  const _ItemTile({required this.item, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md, vertical: 2),
          leading: GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: item.isPacked ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: item.isPacked ? AppColors.primary : Colors.grey.shade400,
                  width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.isPacked
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
          ),
          title: Text(
            item.quantity > 1 ? '${item.name} ×${item.quantity}' : item.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              decoration: item.isPacked ? TextDecoration.lineThrough : null,
              color: item.isPacked
                  ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                  : null,
            ),
          ),
          onTap: onToggle,
        ),
      ),
    );
  }
}
