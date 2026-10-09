import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../domain/entities/trip.dart';
import '../../../injection/injection.dart';
import '../../../l10n/app_localizations.dart';
import '../../bloc/itinerary/itinerary_bloc.dart';
import '../../bloc/recommendations/favorites_bloc.dart';
import '../../bloc/recommendations/recommendations_bloc.dart';
import 'favorites_view.dart';
import 'recommendations_feed_view.dart';

enum RecommendationsTab { discover, favorites }

/// Swipe feed of recommended places for a trip (right likes, left dislikes) and
/// the traveller's favorites, as a `Descubrir | Favoritos` control.
///
/// Reached from a trip: adding a favorite to the itinerary needs a trip.
class RecommendationsPage extends StatefulWidget {
  final Trip trip;
  final RecommendationsTab initialTab;

  const RecommendationsPage({
    super.key,
    required this.trip,
    this.initialTab = RecommendationsTab.discover,
  });

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  late RecommendationsTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<RecommendationsBloc>(
            create: (_) => getIt<RecommendationsBloc>()),
        // One subscription for the whole page: the tab can be switched back and
        // forth without stacking streams.
        BlocProvider<FavoritesBloc>(
            create: (_) => getIt<FavoritesBloc>()..add(const FavoritesStarted())),
        // The details sheet reached from a favorite adds to the itinerary.
        BlocProvider<ItineraryBloc>(create: (_) => getIt<ItineraryBloc>()),
      ],
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(l10n.recommendationsTitle),
            actions: [
              if (_tab == RecommendationsTab.discover)
                PopupMenuButton<String>(
                  onSelected: (_) => confirmAndResetFeed(context),
                  itemBuilder: (_) => [
                    PopupMenuItem<String>(
                      value: 'reset',
                      child: Text(l10n.feedResetAction),
                    ),
                  ],
                ),
            ],
          ),
          body: SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.screenPaddingH,
                    AppSizes.sm, AppSizes.screenPaddingH, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<RecommendationsTab>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: RecommendationsTab.discover,
                        icon: const Icon(Icons.swipe_rounded),
                        label: Text(l10n.recommendationsTabDiscover),
                      ),
                      ButtonSegment(
                        value: RecommendationsTab.favorites,
                        icon: const Icon(Icons.favorite_rounded),
                        label: Text(l10n.recommendationsTabFavorites),
                      ),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (selection) =>
                        setState(() => _tab = selection.first),
                  ),
                ),
              ),
              Expanded(
                child: switch (_tab) {
                  RecommendationsTab.discover =>
                    RecommendationsFeedView(trip: widget.trip),
                  RecommendationsTab.favorites =>
                    FavoritesView(trip: widget.trip),
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
