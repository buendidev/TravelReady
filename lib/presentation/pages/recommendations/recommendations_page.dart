import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/trip.dart';
import '../../../injection/injection.dart';
import '../../../l10n/app_localizations.dart';
import '../../bloc/recommendations/recommendations_bloc.dart';
import 'recommendations_feed_view.dart';

/// Swipe feed of recommended places for a trip: right likes, left dislikes.
///
/// Reached from a trip because adding a favorite to the itinerary needs a trip.
class RecommendationsPage extends StatelessWidget {
  final Trip trip;

  const RecommendationsPage({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecommendationsBloc>(
      create: (_) => getIt<RecommendationsBloc>(),
      child: _RecommendationsScaffold(trip: trip),
    );
  }
}

class _RecommendationsScaffold extends StatelessWidget {
  final Trip trip;

  const _RecommendationsScaffold({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recommendationsTitle),
        actions: [
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
      body: SafeArea(child: RecommendationsFeedView(trip: trip)),
    );
  }
}
