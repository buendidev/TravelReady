import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/packing_item.dart';
import '../../../injection/injection.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/packing/packing_bloc.dart';
import '../../widgets/common/tr_button.dart';
import '../../widgets/common/tr_loading.dart';
import '../../widgets/common/tr_text_field.dart';
import 'packing_templates_sheet.dart';

// ── Page ──────────────────────────────────────────────────────────────────────

class PackingListsPage extends StatelessWidget {
  const PackingListsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId =
        authState is AuthAuthenticated ? authState.user.id : 'anon';

    return BlocProvider<PackingBloc>(
      create: (_) => PackingBloc(repo: getIt())
        ..add(PackingListsLoaded(tripId: userId)),
      child: _PackingContent(userId: userId),
    );
  }
}

class _PackingContent extends StatefulWidget {
  final String userId;
  const _PackingContent({required this.userId});
  @override
  State<_PackingContent> createState() => _PackingContentState();
}

class _PackingContentState extends State<_PackingContent> {
  /// Nombre de la lista recién creada desde plantilla, pendiente de llenar
  String? _pendingTemplateName;
  TemplateData? _pendingTemplate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<PackingBloc, PackingState>(
          // Cuando llega una lista nueva desde plantilla, añadir sus items
          listener: (context, state) {
            if (_pendingTemplate != null && state is PackingListsReady) {
              final lista = state.lists
                  .where((l) => l.name == _pendingTemplateName)
                  .firstOrNull;
              if (lista != null && lista.items.isEmpty) {
                final template = _pendingTemplate!;
                setState(() {
                  _pendingTemplate     = null;
                  _pendingTemplateName = null;
                });
                // Añade los items de la plantilla
                for (var i = 0; i < template.items.length; i++) {
                  context.read<PackingBloc>().add(PackingItemAdded(
                    listId:   lista.id,
                    tripId:   widget.userId,
                    name:     template.items[i].name,
                    category: template.items[i].cat,
                  ));
                }
              }
            }
          },
          builder: (context, state) => CustomScrollView(slivers: [
            SliverAppBar(
              title: Text(AppLocalizations.of(context).packingLists,
                  style: Theme.of(context).textTheme.headlineMedium),
              pinned: true,
              floating: true,
              actions: [
                if (_pendingTemplate != null)
                  const Padding(
                    padding: EdgeInsets.only(right: AppSizes.md),
                    child: Center(child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary))),
                  ),
              ],
            ),

            if (state is PackingLoading)
              const SliverFillRemaining(child: TRLoading())

            else if (state is PackingError ||
                (state is PackingListsReady && state.lists.isEmpty))
              SliverFillRemaining(
                child: Center(child: Padding(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  child: _EmptyState(
                    onNew:      () => _showNewList(context),
                    onTemplate: () => _showTemplates(context),
                  ),
                )),
              )

            else if (state is PackingListsReady)
              SliverPadding(
                padding: const EdgeInsets.all(AppSizes.screenPaddingH),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final list = state.lists[i];
                      return _ListCard(
                        list: list,
                        onTap: () => context.push(
                          '${AppRoutes.packingLists}/${list.id}',
                          extra: widget.userId,
                        ),
                        onDelete: () => context.read<PackingBloc>().add(
                            PackingListDeleted(
                                listId: list.id, tripId: widget.userId)),
                      );
                    },
                    childCount: state.lists.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xxxl)),
          ]),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_tmpl',
            onPressed: () => _showTemplates(context),
            backgroundColor: Colors.white,
            child: const Text('📋', style: TextStyle(fontSize: 18)),
            tooltip: 'Usar plantilla',
          ),
          const SizedBox(height: AppSizes.sm),
          FloatingActionButton(
            heroTag: 'fab_new',
            onPressed: () => _showNewList(context),
            backgroundColor: AppColors.primary,
            tooltip: 'Nueva maleta',
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showNewList(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l10n.newPackingList),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        content: TRTextField(
          label: l10n.nameLabel,
          hint: l10n.listNameHint,
          controller: ctrl,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            if (ctrl.text.trim().isEmpty) return;
            context.read<PackingBloc>().add(
                PackingListCreated(tripId: widget.userId, name: ctrl.text.trim()));
            Navigator.pop(d);
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d),
              child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              context.read<PackingBloc>().add(
                  PackingListCreated(tripId: widget.userId, name: ctrl.text.trim()));
              Navigator.pop(d);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 44)),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  void _showTemplates(BuildContext context) {
    final bloc = context.read<PackingBloc>();
    final currentState = bloc.state;
    showModalBottomSheet<void>(
      // Al navegador raíz: la barrera cubre toda la shell (barra inferior
      // incluida) y el sheet no queda retenido en la rama al cambiar de tab.
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusLg))),
      builder: (_) => PackingTemplatesSheet(
        onSelectTemplate: (t) {
          final name = '${t.emoji} ${t.name}';
          setState(() {
            _pendingTemplate     = TemplateData(t.emoji, t.name, t.items);
            _pendingTemplateName = name;
          });
          bloc.add(PackingListCreated(tripId: widget.userId, name: name));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).creatingTemplate(t.name)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ));
        },
        onAddEssentials: (items) {
          // Si hay una lista activa, añadir a la primera; sino crear una nueva
          if (currentState is PackingListsReady && currentState.lists.isNotEmpty) {
            final list = currentState.lists.first;
            for (final item in items) {
              bloc.add(PackingItemAdded(
                listId: list.id,
                tripId: widget.userId,
                name: item.name,
                category: item.cat,
              ));
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context).essentialsAdded(items.length, list.name)),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ));
          } else {
            final l10n = AppLocalizations.of(context);
            final essentialsName = '🎒 ${l10n.essentialsTitle}';
            setState(() {
              _pendingTemplateName = essentialsName;
              _pendingTemplate = TemplateData('🎒', l10n.essentialsTitle, items);
            });
            bloc.add(PackingListCreated(tripId: widget.userId, name: essentialsName));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context).creatingEssentialsList),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onNew, onTemplate;
  const _EmptyState({required this.onNew, required this.onTemplate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle),
        child: const Icon(Icons.luggage_rounded,
            size: 40, color: AppColors.primary),
      ),
      const SizedBox(height: AppSizes.lg),
      Text(l10n.emptyList,
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSizes.sm),
      Text(
        l10n.addItemsHint,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondaryLight),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSizes.xl),
      TRButton(label: l10n.newList, onPressed: onNew),
      const SizedBox(height: AppSizes.md),
      TRButton(
          label: l10n.templates,
          isOutlined: true,
          onPressed: onTemplate),
    ],
  );
  }
}

class _ListCard extends StatelessWidget {
  final PackingList list;
  final VoidCallback onTap, onDelete;
  const _ListCard(
      {required this.list, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: AppSizes.shadowBlur,
                offset: const Offset(0, AppSizes.shadowOffset))],
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.luggage_rounded,
                    color: AppColors.primary, size: 22)),
              const SizedBox(width: AppSizes.md),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(list.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(l10n.itemsCount(list.packedItems, list.totalItems),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              )),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 20),
                onPressed: () => _confirmDelete(context),
              ),
            ]),
            const SizedBox(height: AppSizes.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: list.totalItems == 0
                    ? 0 : list.packedItems / list.totalItems,
                minHeight: 6,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 6),
            Text(l10n.progressPercent(list.progress),
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: AppColors.primary)),
          ]),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePackingList),
        content: Text(l10n.deleteListConfirm(list.name)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () { Navigator.pop(ctx); onDelete(); },
            child: Text(l10n.delete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
