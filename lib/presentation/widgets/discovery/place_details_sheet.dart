import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/places/place_category.dart';
import '../../../core/services/places/place_result.dart';
import '../../../domain/entities/itinerary/itinerary_item.dart';
import '../../../domain/entities/trip.dart';
import '../../../l10n/app_localizations.dart';
import '../../bloc/itinerary/itinerary_bloc.dart';
import '../common/tr_button.dart';
import 'place_card.dart';

/// Abre la hoja de detalle de [place]. Si hay [trip] ofrece "Añadir al
/// itinerario", que apila la hoja de día/hora sobre la de detalle.
///
/// Requiere un [ItineraryBloc] en el árbol de [context] cuando [trip] no es
/// null. La confirmación de "añadido" solo llega tras
/// [ItineraryMutationSucceeded]; ante un error la hoja queda abierta.
Future<void> showPlaceDetailsSheet(
  BuildContext context, {
  required PlaceResult place,
  Trip? trip,
}) {
  return showModalBottomSheet<void>(
    // Al navegador raíz: la barrera cubre toda la shell (barra inferior
    // incluida) y el sheet no queda retenido en la rama al cambiar de tab.
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    builder: (_) => _PlaceDetailsSheet(
      place: place,
      trip: trip,
      onAddToItinerary:
          trip == null ? null : () => _showAddToItinerary(context, place, trip),
    ),
  );
}

void _showAddToItinerary(BuildContext context, PlaceResult place, Trip trip) {
  // Sin pop previo: la hoja se apila sobre la de detalles y al
  // guardar se vuelve a ella (evita carreras pop+push).
  showModalBottomSheet<void>(
    // Al navegador raíz: la barrera cubre toda la shell (barra inferior
    // incluida) y el sheet no queda retenido en la rama al cambiar de tab.
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<ItineraryBloc>(),
      child: _AddToItinerarySheet(place: place, trip: trip),
    ),
  );
}

// ── Hoja de detalle del lugar ────────────────────────────────────────────────

class _PlaceDetailsSheet extends StatelessWidget {
  final PlaceResult place;
  final Trip? trip;
  final VoidCallback? onAddToItinerary;

  const _PlaceDetailsSheet({
    required this.place,
    this.trip,
    this.onAddToItinerary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(PlaceCard.iconFor(place.category), color: AppColors.primary),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(place.name,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ]),
          const SizedBox(height: AppSizes.sm),
          if (place.address != null) _row(Icons.place_rounded, place.address!),
          if (place.openingHoursText != null)
            _row(
                Icons.schedule_rounded,
                AppLocalizations.of(context)
                    .discoveryHoursIndicative(place.openingHoursText!)),
          if (place.priceLevelLabel != null)
            _row(
                Icons.euro_rounded,
                AppLocalizations.of(context)
                    .discoveryPriceIndicative(place.priceLevelLabel!)),
          if (place.shortDescription != null) ...[
            const SizedBox(height: AppSizes.sm),
            Text(place.shortDescription!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSizes.lg),
          Row(children: [
            if (place.websiteUri != null)
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label:
                      Text(AppLocalizations.of(context).discoveryOfficialSite),
                  onPressed: () => launchUrl(
                    Uri.parse(place.websiteUri!),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            if (place.websiteUri != null && onAddToItinerary != null)
              const SizedBox(width: AppSizes.sm),
            if (onAddToItinerary != null)
              Expanded(
                child: TRButton(
                  label: AppLocalizations.of(context).discoveryAddToItinerary,
                  onPressed: onAddToItinerary!,
                ),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: AppSizes.sm),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(text)),
        ]),
      );
}

// ── Hoja "añadir al itinerario" (día + hora) ─────────────────────────────────

class _AddToItinerarySheet extends StatefulWidget {
  final PlaceResult place;
  final Trip trip;

  const _AddToItinerarySheet({required this.place, required this.trip});

  @override
  State<_AddToItinerarySheet> createState() => _AddToItinerarySheetState();
}

class _AddToItinerarySheetState extends State<_AddToItinerarySheet> {
  late DateTime _day = widget.trip.startDate;
  int _startMinutes = 600;
  bool _saving = false;

  ItineraryCategory _categoryOf(PlaceCategory c) => switch (c) {
        PlaceCategory.food => ItineraryCategory.food,
        PlaceCategory.hotel => ItineraryCategory.lodging,
        PlaceCategory.monument ||
        PlaceCategory.museum =>
          ItineraryCategory.sightseeing,
        PlaceCategory.nightlife ||
        PlaceCategory.nature =>
          ItineraryCategory.activity,
        _ => ItineraryCategory.other,
      };

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: _startMinutes ~/ 60, minute: _startMinutes % 60),
    );
    if (picked != null) {
      setState(() => _startMinutes = picked.hour * 60 + picked.minute);
    }
  }

  void _save() {
    setState(() => _saving = true);
    context.read<ItineraryBloc>().add(ItineraryItemAdded(
          tripId: widget.trip.id,
          day: _day,
          startMinutes: _startMinutes,
          title: widget.place.name,
          category: _categoryOf(widget.place.category),
          place: widget.place.toSnapshot(),
        ));
  }

  void _handleMutationState(BuildContext context, ItineraryState state) {
    if (!_saving) return;
    if (state is ItineraryMutationSucceeded) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context).discoveryAddedToItinerary)));
    } else if (state is ItineraryError) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      widget.trip.durationDays,
      (i) => widget.trip.startDate.add(Duration(days: i)),
    );
    final dayFmt =
        DateFormat.MMMEd(Localizations.localeOf(context).languageCode);

    return BlocListener<ItineraryBloc, ItineraryState>(
      listener: _handleMutationState,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                AppLocalizations.of(context)
                    .discoveryAddPlaceWithName(widget.place.name),
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSizes.md),
            Text(AppLocalizations.of(context).discoveryDayLabel,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSizes.sm),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final d in days)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSizes.sm),
                      child: ChoiceChip(
                        label: Text(dayFmt.format(d)),
                        selected: _day == d,
                        onSelected: (_) => setState(() => _day = d),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),
            OutlinedButton.icon(
              icon: const Icon(Icons.schedule_rounded, size: 18),
              label: Text(AppLocalizations.of(context).discoveryTimeLabel(
                  TimeOfDay(
                          hour: _startMinutes ~/ 60,
                          minute: _startMinutes % 60)
                      .format(context))),
              onPressed: _pickTime,
            ),
            const SizedBox(height: AppSizes.lg),
            SizedBox(
              width: double.infinity,
              child: TRButton(
                label: _saving
                    ? AppLocalizations.of(context).saving
                    : AppLocalizations.of(context).itineraryAdd,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
