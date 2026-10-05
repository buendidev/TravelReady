import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../domain/entities/itinerary/itinerary_item.dart';
import '../../../domain/entities/trip.dart';
import '../../../injection/injection.dart';
import '../../bloc/itinerary/itinerary_bloc.dart';
import '../../widgets/common/tr_button.dart';
import '../../widgets/common/tr_loading.dart';
import '../../widgets/common/tr_text_field.dart';
import '../../../l10n/app_localizations.dart';

/// Returns the reordered ids while accounting for Flutter's pre-removal index.
List<String> reorderItineraryIds(
    List<String> ids, int oldIndex, int newIndex) {
  final reordered = List<String>.from(ids);
  if (oldIndex < 0 || oldIndex >= reordered.length) return reordered;
  final id = reordered.removeAt(oldIndex);
  final adjustedIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;
  reordered.insert(adjustedIndex.clamp(0, reordered.length).toInt(), id);
  return reordered;
}

/// Itinerario del viaje: entradas agrupadas por día, ordenadas por hora.
/// Offline-first (SQLite). Los textos van en español fijo porque los
/// ficheros l10n están fuera de la superficie permitida de este batch.
class ItineraryPage extends StatelessWidget {
  final Trip trip;
  const ItineraryPage({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ItineraryBloc>(
      create: (_) =>
          getIt<ItineraryBloc>()..add(ItineraryLoaded(tripId: trip.id)),
      child: _Content(trip: trip),
    );
  }
}

/// Etiqueta visible de [category] en el idioma activo.
///
/// Un `switch` sobre este enum cerrado hace que añadir una categoría rompa la
/// compilación en lugar de la pantalla, que es lo que pasaba con el mapa y su
/// `!` anteriores.
String itineraryCategoryLabel(
    AppLocalizations l10n, ItineraryCategory category) {
  switch (category) {
    case ItineraryCategory.sightseeing:
      return l10n.itineraryCategorySightseeing;
    case ItineraryCategory.food:
      return l10n.itineraryCategoryFood;
    case ItineraryCategory.transport:
      return l10n.transport;
    case ItineraryCategory.lodging:
      return l10n.itineraryCategoryLodging;
    case ItineraryCategory.activity:
      return l10n.itineraryCategoryActivity;
    case ItineraryCategory.other:
      return l10n.itineraryCategoryOther;
  }
}

class _Content extends StatelessWidget {
  final Trip trip;
  const _Content({required this.trip});

  String _fmtMinutes(BuildContext context, int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context);

  @override
  Widget build(BuildContext context) {
    final dayFmt = DateFormat.MMMEd(
        Localizations.localeOf(context).languageCode);

    return Scaffold(
      appBar: AppBar(
          title: Text(AppLocalizations.of(context)
              .itineraryTitleWithTrip(trip.name))),
      body: SafeArea(
        child: BlocBuilder<ItineraryBloc, ItineraryState>(
          builder: (context, state) {
            if (state is ItineraryLoading || state is ItineraryInitial) {
              return const TRLoading();
            }
            if (state is ItineraryError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48),
                      const SizedBox(height: AppSizes.md),
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: AppSizes.lg),
                      TRButton(
                        label: AppLocalizations.of(context).retry,
                        onPressed: () => context.read<ItineraryBloc>().add(
                            ItineraryLoaded(tripId: trip.id)),
                      ),
                    ],
                  ),
                ),
              );
            }
            final items = (state as ItineraryReady).items;
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.event_note_rounded,
                            size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: AppSizes.lg),
                      Text(AppLocalizations.of(context).itineraryEmptyTitle,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        AppLocalizations.of(context).itineraryEmptyBody,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSizes.xl),
                      TRButton(
                        label: AppLocalizations.of(context).itineraryAddPlan,
                        onPressed: () => _showEditor(context),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Agrupar por día (ya vienen ordenados por el datasource).
            final byDay = <DateTime, List<ItineraryItem>>{};
            for (final i in items) {
              byDay.putIfAbsent(i.day, () => []).add(i);
            }
            final days = byDay.keys.toList();

            return ListView.builder(
              padding: const EdgeInsets.all(AppSizes.screenPaddingH),
              itemCount: days.length,
              itemBuilder: (_, di) {
                final day = days[di];
                final dayItems = byDay[day]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.sm),
                      child: Text(dayFmt.format(day),
                          style:
                              Theme.of(context).textTheme.titleMedium),
                    ),
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorderItem: (oldI, newI) {
                        final ids = reorderItineraryIds(
                          dayItems.map((i) => i.id).toList(),
                          oldI,
                          newI,
                        );
                        context.read<ItineraryBloc>().add(
                            ItineraryItemsReordered(
                                tripId: trip.id, orderedIds: ids));
                      },
                      children: [
                        for (var i = 0; i < dayItems.length; i++)
                          ReorderableDragStartListener(
                            key: ValueKey(dayItems[i].id),
                            index: i,
                            child: _ItemCard(
                              item: dayItems[i],
                              fmt: _fmtMinutes,
                              categoryLabel:
                                  itineraryCategoryLabel(
                                      AppLocalizations.of(context),
                                      dayItems[i].category),
                              onTap: () =>
                                  _showEditor(context, item: dayItems[i]),
                              onDelete: () =>
                                  context.read<ItineraryBloc>().add(
                                      ItineraryItemDeleted(
                                          itemId: dayItems[i].id)),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(context),
        backgroundColor: AppColors.primary,
        tooltip: AppLocalizations.of(context).itineraryAddPlan,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showEditor(BuildContext context, {ItineraryItem? item}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<ItineraryBloc>(),
        child: _ItemEditorSheet(
          trip: trip,
          item: item,
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final ItineraryItem item;
  final String Function(BuildContext, int) fmt;
  final String categoryLabel;
  final VoidCallback onTap, onDelete;

  const _ItemCard({
    required this.item,
    required this.fmt,
    required this.categoryLabel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = item.endMinutes != null
        ? '${fmt(context, item.startMinutes)} – ${fmt(context, item.endMinutes!)}'
        : fmt(context, item.startMinutes);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: AppSizes.shadowBlur,
                offset: const Offset(0, AppSizes.shadowOffset),
              ),
            ],
          ),
          child: Row(children: [
            SizedBox(
              width: 56,
              child: Text(time,
                  style: Theme.of(context).textTheme.labelMedium),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(categoryLabel,
                        style: Theme.of(context).textTheme.bodySmall),
                    if (item.place?.websiteUri != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => launchUrl(
                            Uri.parse(item.place!.websiteUri!),
                            mode: LaunchMode.externalApplication),
                        child: const Icon(Icons.open_in_new_rounded,
                            size: 14, color: AppColors.primary),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 20),
              tooltip:
                  AppLocalizations.of(context).itineraryDeletePlan,
              onPressed: onDelete,
            ),
            const Icon(Icons.drag_indicator_rounded, size: 20),
          ]),
        ),
      ),
    );
  }
}

/// Sheet de creación/edición de una entrada de itinerario.
class _ItemEditorSheet extends StatefulWidget {
  final Trip trip;
  final ItineraryItem? item;

  const _ItemEditorSheet({
    required this.trip,
    this.item,
  });

  @override
  State<_ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<_ItemEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _day;
  late int _startMinutes;
  int? _endMinutes;
  late ItineraryCategory _category;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _titleCtrl = TextEditingController(text: i?.title ?? '');
    _notesCtrl = TextEditingController(text: i?.notes ?? '');
    _day = i?.day ?? widget.trip.startDate;
    _startMinutes = i?.startMinutes ?? 600;
    _endMinutes = i?.endMinutes;
    _category = i?.category ?? ItineraryCategory.sightseeing;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: widget.trip.startDate,
      lastDate: widget.trip.endDate,
    );
    if (picked != null) setState(() => _day = picked);
  }

  Future<void> _pickTime(bool isEnd) async {
    final current = isEnd ? (_endMinutes ?? _startMinutes) : _startMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    final minutes = picked.hour * 60 + picked.minute;
    setState(() {
      if (isEnd) {
        _endMinutes = minutes;
      } else {
        _startMinutes = minutes;
      }
    });
  }

  void _save() {
    final bloc = context.read<ItineraryBloc>();
    final item = widget.item;
    if (item == null) {
      bloc.add(ItineraryItemAdded(
        tripId: widget.trip.id,
        day: _day,
        startMinutes: _startMinutes,
        endMinutes: _endMinutes,
        title: _titleCtrl.text,
        category: _category,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text,
      ));
    } else {
      bloc.add(ItineraryItemUpdated(
          item: item.copyWith(
        day: _day,
        startMinutes: _startMinutes,
        endMinutes: _endMinutes,
        title: _titleCtrl.text,
        category: _category,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text,
      )));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dayFmt = DateFormat.yMMMd(
        Localizations.localeOf(context).languageCode);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.lg,
        right: AppSizes.lg,
        top: AppSizes.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                widget.item == null
                    ? AppLocalizations.of(context).itineraryNewPlan
                    : AppLocalizations.of(context).itineraryEditPlan,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSizes.md),
            TRTextField(
              label: AppLocalizations.of(context).itineraryFieldTitle,
              hint: AppLocalizations.of(context).itineraryFieldTitleHint,
              controller: _titleCtrl,
              autofocus: widget.item == null,
            ),
            const SizedBox(height: AppSizes.md),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: Text(dayFmt.format(_day)),
                  onPressed: _pickDay,
                ),
              ),
            ]),
            const SizedBox(height: AppSizes.sm),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(AppLocalizations.of(context).itineraryStartAt(
                      TimeOfDay(
                              hour: _startMinutes ~/ 60,
                              minute: _startMinutes % 60)
                          .format(context))),
                  onPressed: () => _pickTime(false),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(_endMinutes == null
                      ? AppLocalizations.of(context).itineraryEndOptional
                      : AppLocalizations.of(context).itineraryEndAt(
                          TimeOfDay(
                                  hour: _endMinutes! ~/ 60,
                                  minute: _endMinutes! % 60)
                              .format(context))),
                  onPressed: () => _pickTime(true),
                ),
              ),
            ]),
            const SizedBox(height: AppSizes.md),
            Wrap(
              spacing: AppSizes.sm,
              children: [
                for (final c in ItineraryCategory.values)
                  ChoiceChip(
                    label: Text(itineraryCategoryLabel(
                        AppLocalizations.of(context), c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            TRTextField(
              label: AppLocalizations.of(context).itineraryFieldNotes,
              hint: AppLocalizations.of(context).itineraryFieldNotesHint,
              controller: _notesCtrl,
            ),
            const SizedBox(height: AppSizes.lg),
            SizedBox(
              width: double.infinity,
              child: TRButton(
                label: widget.item == null
                    ? AppLocalizations.of(context).itineraryAdd
                    : AppLocalizations.of(context).save,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
