import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/places/place_category.dart';
import '../../../core/services/places/place_result.dart';
import '../../../core/services/places/places_gateway.dart';
import '../../../domain/entities/itinerary/itinerary_item.dart';
import '../../../domain/entities/trip.dart';
import '../../../injection/injection.dart';
import '../../bloc/itinerary/itinerary_bloc.dart';
import '../../widgets/common/tr_button.dart';
import '../../widgets/common/tr_loading.dart';
import '../../widgets/discovery/place_card.dart';

/// Descubrimiento visual de destinos — provider-neutral.
///
/// Lee el [PlacesGateway] de getIt. Si el proveedor está en modo demo
/// los resultados se etiquetan como datos de ejemplo; si está sin
/// configurar se muestra el estado `unavailable`. Nunca simula
/// resultados en vivo.
class DiscoveryPage extends StatelessWidget {
  /// Viaje destino del flujo "añadir al itinerario". Null deshabilita
  /// ese botón en el detalle del lugar.
  final Trip? trip;
  const DiscoveryPage({super.key, this.trip});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ItineraryBloc>(
      create: (_) => getIt<ItineraryBloc>(),
      child: _DiscoveryContent(trip: trip),
    );
  }
}

class _DiscoveryContent extends StatefulWidget {
  final Trip? trip;
  const _DiscoveryContent({this.trip});

  @override
  State<_DiscoveryContent> createState() => _DiscoveryContentState();
}

class _DiscoveryContentState extends State<_DiscoveryContent> {
  final _searchCtrl = TextEditingController();
  PlaceCategory? _category;
  bool _loading = false;
  List<PlaceResult> _results = [];
  String? _error;
  bool _searched = false;

  PlacesGateway get _gateway => getIt<PlacesGateway>();

  @override
  void initState() {
    super.initState();
    if (_gateway.availability == PlacesAvailability.unavailable) return;
    _runSearch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final either = await _gateway.search(
      query: _searchCtrl.text,
      category: _category,
      destinationHint: widget.trip?.destination,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _searched = true;
      either.fold(
        (f) => _error = f.message,
        (items) => _results = items,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final availability = _gateway.availability;
    return Scaffold(
      appBar: AppBar(title: const Text('Descubrir')),
      body: SafeArea(
        child: Column(children: [
          // ── Búsqueda ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSizes.screenPaddingH),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _runSearch(),
              decoration: InputDecoration(
                hintText: 'Buscar lugares, museos, restaurantes…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  tooltip: 'Buscar',
                  onPressed: _runSearch,
                ),
                border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusLg)),
              ),
            ),
          ),

          // ── Chips de categoría ───────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPaddingH),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSizes.sm),
                  child: ChoiceChip(
                    label: const Text('Todo'),
                    selected: _category == null,
                    onSelected: (_) {
                      setState(() => _category = null);
                      _runSearch();
                    },
                  ),
                ),
                for (final e in placeCategoryLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSizes.sm),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: _category == e.key,
                      onSelected: (sel) {
                        setState(() =>
                            _category = sel ? e.key : null);
                        _runSearch();
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // ── Etiqueta demo ────────────────────────────────────────
          if (availability == PlacesAvailability.demo ||
              _gateway.attributionText != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPaddingH),
              child: Row(children: [
                const Icon(Icons.science_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _gateway.attributionText ??
                        'Datos de ejemplo — sin proveedor configurado',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ]),
            ),
          const SizedBox(height: AppSizes.sm),

          // ── Resultados / estados ─────────────────────────────────
          Expanded(child: _buildBody(availability)),
        ]),
      ),
    );
  }

  Widget _buildBody(PlacesAvailability availability) {
    if (availability == PlacesAvailability.unavailable) {
      return const _Centered(
        icon: Icons.cloud_off_rounded,
        title: 'Proveedor no disponible',
        message:
            'La búsqueda de lugares requiere configurar un proveedor '
            '(Maps/Places). Mientras tanto puedes añadir planes '
            'manualmente al itinerario.',
      );
    }
    if (_loading) return const TRLoading();
    if (_error != null) {
      return _Centered(
        icon: Icons.error_outline_rounded,
        title: 'Error al buscar',
        message: _error!,
        action: TRButton(label: 'Reintentar', onPressed: _runSearch),
      );
    }
    if (_results.isEmpty) {
      return _Centered(
        icon: Icons.travel_explore_rounded,
        title: _searched ? 'Sin resultados' : 'Explora tu destino',
        message: _searched
            ? 'Prueba con otra búsqueda o categoría.'
            : 'Busca museos, restaurantes o rincones del destino.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.screenPaddingH),
      itemCount: _results.length,
      itemBuilder: (_, i) => PlaceCard(
        place: _results[i],
        onTap: () => _showDetails(_results[i]),
      ),
    );
  }

  void _showDetails(PlaceResult place) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PlaceDetailsSheet(
        place: place,
        trip: widget.trip,
        onAddToItinerary: widget.trip == null
            ? null
            : () => _showAddToItinerary(place),
      ),
    );
  }

  void _showAddToItinerary(PlaceResult place) {
    // Sin pop previo: la hoja se apila sobre la de detalles y al
    // guardar se vuelve a ella (evita carreras pop+push).
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ItineraryBloc>(),
        child: _AddToItinerarySheet(
          place: place,
          trip: widget.trip!,
        ),
      ),
    );
  }
}

// ── Estados centrados ────────────────────────────────────────────────────────

class _Centered extends StatelessWidget {
  final IconData icon;
  final String title, message;
  final Widget? action;
  const _Centered({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: AppSizes.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSizes.sm),
            Text(message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppSizes.lg),
              action!,
            ],
          ]),
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
            Icon(PlaceCard.iconFor(place.category),
                color: AppColors.primary),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(place.name,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ]),
          const SizedBox(height: AppSizes.sm),
          if (place.address != null)
            _row(Icons.place_rounded, place.address!),
          if (place.openingHoursText != null)
            _row(Icons.schedule_rounded,
                'Horario (indicativo): ${place.openingHoursText!}'),
          if (place.priceLevelLabel != null)
            _row(Icons.euro_rounded,
                'Precio orientativo: ${place.priceLevelLabel!}'),
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
                  label: const Text('Sitio web oficial'),
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
                  label: 'Añadir al itinerario',
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Añadido al itinerario')));
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
    final dayFmt = DateFormat('EEE d',
        Localizations.localeOf(context).languageCode);

    return BlocListener<ItineraryBloc, ItineraryState>(
      listener: _handleMutationState,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Añadir "${widget.place.name}"',
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSizes.md),
          Text('Día', style: Theme.of(context).textTheme.labelLarge),
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
            label: Text(
                'Hora · ${TimeOfDay(hour: _startMinutes ~/ 60, minute: _startMinutes % 60).format(context)}'),
            onPressed: _pickTime,
          ),
          const SizedBox(height: AppSizes.lg),
            SizedBox(
              width: double.infinity,
              child: TRButton(
                label: _saving ? 'Guardando…' : 'Añadir',
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
