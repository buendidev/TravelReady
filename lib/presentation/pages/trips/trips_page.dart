import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/trip.dart';
import '../../../injection/injection.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/trips/trips_bloc.dart';
import '../../widgets/common/tr_button.dart';
import '../../widgets/common/tr_loading.dart';
import '../../widgets/common/tr_text_field.dart';

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    final userId = auth is AuthAuthenticated ? auth.user.id : '';
    return BlocProvider<TripsBloc>(
      create: (_) => TripsBloc(
        createTripUseCase: getIt(),
        repo: getIt(),
      )..add(TripsLoaded(userId: userId)),
      child: _TripsContent(userId: userId),
    );
  }
}

class _TripsContent extends StatefulWidget {
  final String userId;
  const _TripsContent({required this.userId});
  @override
  State<_TripsContent> createState() => _TripsContentState();
}

class _TripsContentState extends State<_TripsContent> {
  String _search = '';
  TripFilter _filter = TripFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<TripsBloc, TripsState>(
          builder: (context, state) {
            final all = state is TripsReady ? state.trips : <Trip>[];
            final filtered = _applyFilter(all);

            return CustomScrollView(slivers: [
              // ── AppBar ─────────────────────────────────────────────
              SliverAppBar(
                title: Text(AppLocalizations.of(context).myTripsTitle,
                    style: Theme.of(context).textTheme.headlineMedium),
                pinned: true,
                floating: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    tooltip: AppLocalizations.of(context).newTrip,
                    onPressed: () => _showSheet(context),
                  ),
                ],
              ),

              // ── Buscador + filtros ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.screenPaddingH,
                      AppSizes.sm, AppSizes.screenPaddingH, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Searchbar
                      TextField(
                        onChanged: (v) => setState(() => _search = v.trim()),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).searchTripHint,
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      // Filtro chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children: TripFilter.values
                                .map(
                                  (f) => Padding(
                                    padding: const EdgeInsets.only(
                                        right: AppSizes.sm),
                                    child: ChoiceChip(
                                      label: Text(f
                                          .label(AppLocalizations.of(context))),
                                      selected: _filter == f,
                                      selectedColor: AppColors.primary
                                          .withValues(alpha: 0.15),
                                      checkmarkColor: AppColors.primary,
                                      onSelected: (_) =>
                                          setState(() => _filter = f),
                                    ),
                                  ),
                                )
                                .toList()),
                      ),
                      const SizedBox(height: AppSizes.sm),
                    ],
                  ),
                ),
              ),

              // ── Contenido ─────────────────────────────────────────
              if (state is TripsLoading)
                const SliverFillRemaining(child: TRLoading())
              else if (state is TripsError)
                SliverFillRemaining(
                  child: TRErrorWidget(
                    message: state.message,
                    onRetry: () => context
                        .read<TripsBloc>()
                        .add(TripsLoaded(userId: widget.userId)),
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                      child: Padding(
                    padding: const EdgeInsets.all(AppSizes.xl),
                    child: all.isEmpty
                        ? _EmptyAll(onNew: () => _showSheet(context))
                        : _EmptyFiltered(
                            onClear: () => setState(() {
                              _search = '';
                              _filter = TripFilter.all;
                            }),
                          ),
                  )),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.screenPaddingH),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final trip = filtered[i];
                        return _TripCard(
                          trip: trip,
                          onTap: () => context.push(
                            AppRoutes.tripDetailPath(trip.id),
                            extra: trip,
                          ),
                          onDelete: () => context.read<TripsBloc>().add(
                              TripDeleted(
                                  tripId: trip.id, userId: widget.userId)),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xxxl)),
            ]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSheet(context),
        tooltip: AppLocalizations.of(context).newTrip,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  List<Trip> _applyFilter(List<Trip> trips) {
    final now = DateTime.now();
    List<Trip> result = trips;

    switch (_filter) {
      case TripFilter.upcoming:
        result = trips.where((t) => t.startDate.isAfter(now)).toList();
        break;
      case TripFilter.active:
        result = trips
            .where((t) => t.startDate.isBefore(now) && t.endDate.isAfter(now))
            .toList();
        break;
      case TripFilter.past:
        result = trips.where((t) => t.endDate.isBefore(now)).toList();
        break;
      case TripFilter.all:
        break;
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result
          .where((t) =>
              t.name.toLowerCase().contains(q) ||
              t.destination.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg))),
      builder: (_) => BlocProvider.value(
        value: context.read<TripsBloc>(),
        child: _NewTripSheet(userId: widget.userId),
      ),
    );
  }
}

// ── Enum filtro ───────────────────────────────────────────────────────────────

enum TripFilter {
  all,
  upcoming,
  active,
  past;

  String label(AppLocalizations l10n) => switch (this) {
        TripFilter.all => l10n.tripFilterAll,
        TripFilter.upcoming => l10n.tripFilterUpcoming,
        TripFilter.active => l10n.tripFilterActive,
        TripFilter.past => l10n.tripFilterPast,
      };
}

// ── Sheet nuevo viaje ─────────────────────────────────────────────────────────

class _NewTripSheet extends StatefulWidget {
  final String userId;
  const _NewTripSheet({required this.userId});
  @override
  State<_NewTripSheet> createState() => _NewTripSheetState();
}

class _NewTripSheetState extends State<_NewTripSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  DateTime _start = DateTime.now().add(const Duration(days: 7));
  DateTime _end = DateTime.now().add(const Duration(days: 14));
  TripType _type = TripType.city;
  final _transport = <TransportType>{};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end.isBefore(_start)) {
          _end = _start.add(const Duration(days: 1));
        }
      } else {
        if (picked.isAfter(_start)) _end = picked;
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<TripsBloc>().add(TripCreated(
          userId: widget.userId,
          name: _nameCtrl.text.trim(),
          destination: _destCtrl.text.trim(),
          startDate: _start,
          endDate: _end,
          tripType: _type,
          transport: _transport.toList(),
        ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final fmt =
        DateFormat('dd MMM yyyy', Localizations.localeOf(context).languageCode);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSizes.screenPaddingH,
          AppSizes.md,
          AppSizes.screenPaddingH,
          MediaQuery.of(context).viewInsets.bottom + AppSizes.xl),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                  child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSizes.md),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
              )),

              Text(AppLocalizations.of(context).newTrip,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSizes.md),

              TRTextField(
                label: AppLocalizations.of(context).tripName,
                hint: AppLocalizations.of(context).tripNameHint,
                controller: _nameCtrl,
                autofocus: true,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppLocalizations.of(context).requiredField
                    : null,
              ),
              const SizedBox(height: AppSizes.md),

              TRTextField(
                label: AppLocalizations.of(context).destination,
                hint: AppLocalizations.of(context).destinationHint,
                controller: _destCtrl,
                textInputAction: TextInputAction.done,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppLocalizations.of(context).requiredField
                    : null,
              ),
              const SizedBox(height: AppSizes.md),

              // Fechas
              Row(children: [
                Expanded(
                    child: _DateBtn(
                        label: AppLocalizations.of(context).departureDate,
                        value: fmt.format(_start),
                        onTap: () => _pickDate(true))),
                const SizedBox(width: AppSizes.md),
                Expanded(
                    child: _DateBtn(
                        label: AppLocalizations.of(context).returnDate,
                        value: fmt.format(_end),
                        onTap: () => _pickDate(false))),
              ]),

              const SizedBox(height: AppSizes.xs),
              Text(
                '${_end.difference(_start).inDays + 1} días',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSizes.md),

              // Tipo
              Text(AppLocalizations.of(context).tripTypeLabel,
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.xs,
                children: TripType.values
                    .map((t) => ChoiceChip(
                          label: Text(_typeLabel(t)),
                          selected: t == _type,
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primary,
                          onSelected: (_) => setState(() => _type = t),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSizes.md),

              // Transporte
              Text(AppLocalizations.of(context).transportLabel,
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.xs,
                children: TransportType.values
                    .map((t) => FilterChip(
                          label: Text(_transportLabel(t)),
                          selected: _transport.contains(t),
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primary,
                          onSelected: (v) => setState(() {
                            if (v)
                              _transport.add(t);
                            else
                              _transport.remove(t);
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSizes.xl),

              TRButton(
                  label: AppLocalizations.of(context).createTripLabel,
                  onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(TripType t) => switch (t) {
        TripType.beach => '🏖️ Playa',
        TripType.mountain => '⛰️ Montaña',
        TripType.city => '🏙️ Ciudad',
        TripType.business => '💼 Negocios',
        TripType.adventure => '🧗 Aventura',
        TripType.other => '✈️ Otro',
      };

  String _transportLabel(TransportType t) => switch (t) {
        TransportType.plane => '✈️ Avión',
        TransportType.train => '🚄 Tren',
        TransportType.bus => '🚌 Bus',
        TransportType.car => '🚗 Coche',
        TransportType.ship => '🚢 Barco',
        TransportType.other => '🚀 Otro',
      };
}

class _DateBtn extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _DateBtn(
      {required this.label, required this.value, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceElevatedDark
              : AppColors.surfaceElevatedLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ── Trip Card ─────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap, onDelete;
  const _TripCard(
      {required this.trip, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fmt =
        DateFormat('dd MMM', Localizations.localeOf(context).languageCode);
    final now = DateTime.now();
    final isActive = trip.startDate.isBefore(now) && trip.endDate.isAfter(now);
    final isPast = trip.endDate.isBefore(now);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: isActive
                ? Border.all(
                    color: AppColors.success.withValues(alpha: 0.4), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: AppSizes.shadowBlur,
                  offset: const Offset(0, AppSizes.shadowOffset))
            ],
          ),
          child: Row(children: [
            // Icono
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isPast
                    ? Colors.grey.withValues(alpha: 0.12)
                    : isActive
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isActive
                    ? Icons.flight_rounded
                    : isPast
                        ? Icons.flight_land_rounded
                        : Icons.flight_takeoff_rounded,
                color: isPast
                    ? Colors.grey
                    : isActive
                        ? AppColors.success
                        : AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(trip.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color: isPast
                                      ? AppColors.textSecondaryLight
                                      : null),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  if (isActive) _badge('EN CURSO', AppColors.success),
                  if (isPast) _badge('PASADO', Colors.grey),
                ]),
                const SizedBox(height: 3),
                Text(trip.destination,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  '${fmt.format(trip.startDate)} → ${fmt.format(trip.endDate)} · ${trip.durationDays} días',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.primary),
                ),
              ],
            )),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 20),
              tooltip: AppLocalizations.of(context).deleteTrip,
              onPressed: () => _confirmDelete(context),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
        child: Text(text,
            style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      );

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTripTitle),
        content: Text(l10n.deleteTripConfirm(trip.name)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: Text(l10n.delete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Empty states ──────────────────────────────────────────────────────────────

class _EmptyAll extends StatelessWidget {
  final VoidCallback onNew;
  const _EmptyAll({required this.onNew});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.flight_takeoff_rounded,
                size: 40, color: AppColors.primary)),
        const SizedBox(height: AppSizes.lg),
        Text(l10n.noTripsPlanned,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSizes.sm),
        Text(AppLocalizations.of(context).noTripsHintSub,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondaryLight),
            textAlign: TextAlign.center),
        const SizedBox(height: AppSizes.xl),
        TRButton(label: '✈️  ${l10n.newTrip}', onPressed: onNew),
      ],
    );
  }
}

class _EmptyFiltered extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyFiltered({required this.onClear});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.search_off_rounded,
            size: 56, color: AppColors.textSecondaryLight),
        const SizedBox(height: AppSizes.md),
        Text(l10n.noResults, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSizes.sm),
        Text(l10n.tryAnotherFilter,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSizes.lg),
        TextButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.clear_rounded),
          label: Text(l10n.clearFilters),
        ),
      ],
    );
  }
}
