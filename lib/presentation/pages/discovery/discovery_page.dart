import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/places/place_category.dart';
import '../../../core/services/places/place_result.dart';
import '../../../core/services/places/places_gateway.dart';
import '../../../domain/entities/trip.dart';
import '../../../injection/injection.dart';
import '../../bloc/itinerary/itinerary_bloc.dart';
import '../../widgets/common/tr_button.dart';
import '../../widgets/common/tr_loading.dart';
import '../../widgets/discovery/place_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/discovery/place_category_labels.dart';
import '../../widgets/discovery/place_details_sheet.dart';

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
      appBar: AppBar(title: Text(AppLocalizations.of(context).discoveryTitle)),
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
                hintText: AppLocalizations.of(context).discoverySearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded),
                  tooltip: AppLocalizations.of(context).search,
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
                    label: Text(
                        AppLocalizations.of(context).discoveryAllCategories),
                    selected: _category == null,
                    onSelected: (_) {
                      setState(() => _category = null);
                      _runSearch();
                    },
                  ),
                ),
                for (final c in PlaceCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSizes.sm),
                    child: ChoiceChip(
                      label: Text(placeCategoryLabel(
                          AppLocalizations.of(context), c)),
                      selected: _category == c,
                      onSelected: (sel) {
                        setState(() => _category = sel ? c : null);
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
                        AppLocalizations.of(context).discoveryDemoData,
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
      return _Centered(
        icon: Icons.cloud_off_rounded,
        title: AppLocalizations.of(context).discoveryProviderUnavailableTitle,
        message: AppLocalizations.of(context).discoveryProviderUnavailableBody,
      );
    }
    if (_loading) return const TRLoading();
    if (_error != null) {
      return _Centered(
        icon: Icons.error_outline_rounded,
        title: AppLocalizations.of(context).discoverySearchErrorTitle,
        message: _error!,
        action:
            TRButton(label: AppLocalizations.of(context).retry, onPressed: _runSearch),
      );
    }
    if (_results.isEmpty) {
      return _Centered(
        icon: Icons.travel_explore_rounded,
        title: _searched
            ? AppLocalizations.of(context).discoveryNoResultsTitle
            : AppLocalizations.of(context).discoveryExploreTitle,
        message: _searched
            ? AppLocalizations.of(context).discoveryNoResultsBody
            : AppLocalizations.of(context).discoveryExploreBody,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.screenPaddingH),
      itemCount: _results.length,
      itemBuilder: (_, i) => PlaceCard(
        place: _results[i],
        onTap: () =>
            showPlaceDetailsSheet(context, place: _results[i], trip: widget.trip),
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
