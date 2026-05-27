import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/packing_item.dart';
import '../../../domain/entities/trip.dart';
import '../../../injection/injection.dart';
import '../../bloc/packing/packing_bloc.dart';
import '../../widgets/common/tr_button.dart';
import '../../widgets/common/tr_loading.dart';
import '../../widgets/common/tr_text_field.dart';

class TripDetailPage extends StatelessWidget {
  final Trip trip;
  const TripDetailPage({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PackingBloc>(
      create: (_) => PackingBloc(repo: getIt())
        ..add(PackingListsLoaded(tripId: trip.id)),
      child: _Content(trip: trip),
    );
  }
}

class _Content extends StatefulWidget {
  final Trip trip;
  const _Content({required this.trip});
  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  /// true mientras esperamos que el stream devuelva la lista recién creada
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = DateFormat('dd MMM yyyy', Localizations.localeOf(context).languageCode);

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<PackingBloc, PackingState>(
          builder: (context, state) => CustomScrollView(slivers: [
            // AppBar
            SliverAppBar(
              title: Text(widget.trip.name,
                  style: Theme.of(context).textTheme.headlineMedium),
              pinned: true,
              floating: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _showNewList(context),
                ),
              ],
            ),

            // Tarjeta del viaje
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.screenPaddingH),
                child: _TripCard(trip: widget.trip, fmt: fmt),
              ),
            ),

            // Título sección
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPaddingH),
                child: Text(l10n.packingListsForTrip,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSizes.sm)),

            // Contenido
            if (state is PackingLoading)
              const SliverFillRemaining(child: TRLoading())
            else if (state is PackingError)
              SliverFillRemaining(
                child: Center(child: Padding(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  child: _Empty(
                    onNew: () => _showNewList(context),
                  ),
                )),
              )
            else if (state is PackingListsReady && state.lists.isEmpty)
              SliverFillRemaining(
                child: Center(child: Padding(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  child: _Empty(
                    onNew: () => _showNewList(context),
                  ),
                )),
              )
            else if (state is PackingListsReady)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPaddingH),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final list = state.lists[i];
                      return _ListCard(
                        list: list,
                        onTap: () => context.push(
                          '${AppRoutes.packingLists}/${list.id}',
                          extra: widget.trip.id,
                        ),
                        onDelete: () => context.read<PackingBloc>().add(
                            PackingListDeleted(
                                listId: list.id, tripId: widget.trip.id)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewList(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showNewList(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l10n.newList),
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
            _createList(context, ctrl.text.trim());
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
              _createList(context, ctrl.text.trim());
              Navigator.pop(d);
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 44)),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  void _createList(BuildContext context, String name) {
    context.read<PackingBloc>().add(
        PackingListCreated(tripId: widget.trip.id, name: name));
  }

}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Trip trip;
  final DateFormat fmt;
  const _TripCard({required this.trip, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isActive = trip.startDate.isBefore(DateTime.now()) &&
        trip.endDate.isAfter(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: AppSizes.shadowBlur,
            offset: const Offset(0, AppSizes.shadowOffset))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(trip.destination,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w600, fontSize: 16),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text(l10n.inProgress,
                  style: TextStyle(color: Colors.white, fontSize: 10,
                      fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            ),
        ]),
        const SizedBox(height: AppSizes.sm),
        Text(
          '${fmt.format(trip.startDate)}  →  ${fmt.format(trip.endDate)}  ·  ${trip.durationDays} días',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        if (trip.transport.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(children: trip.transport
              .map((t) => Text(_tIcon(t), style: const TextStyle(fontSize: 16)))
              .toList()),
        ],
      ]),
    );
  }

  String _tIcon(TransportType t) => switch (t) {
    TransportType.plane => '✈️ ',
    TransportType.train => '🚄 ',
    TransportType.bus   => '🚌 ',
    TransportType.car   => '🚗 ',
    TransportType.ship  => '🚢 ',
    TransportType.other => '🚀 ',
  };
}

class _ListCard extends StatelessWidget {
  final PackingList list;
  final VoidCallback onTap, onDelete;
  const _ListCard({required this.list, required this.onTap, required this.onDelete});

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
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: AppSizes.shadowBlur,
                offset: const Offset(0, AppSizes.shadowOffset))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
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
                onPressed: onDelete),
            ]),
            const SizedBox(height: AppSizes.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              child: LinearProgressIndicator(
                value: list.totalItems == 0
                    ? 0 : list.packedItems / list.totalItems,
                minHeight: 6,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
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
}

class _Empty extends StatelessWidget {
  final VoidCallback onNew;
  const _Empty({required this.onNew});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle),
        child: const Icon(Icons.luggage_rounded,
            size: 40, color: AppColors.primary)),
      const SizedBox(height: AppSizes.lg),
      Text(l10n.noListsYet,
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSizes.sm),
      Text(l10n.createListHint,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryLight),
          textAlign: TextAlign.center),
      const SizedBox(height: AppSizes.xl),
      TRButton(label: l10n.newList, onPressed: onNew),
    ],
  );
  }
}
