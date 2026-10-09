import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/places/places_gateway.dart';
import '../../../domain/entities/recommendations/applied_reaction.dart';
import '../../../domain/entities/recommendations/recommendation_filter.dart';
import '../../../domain/entities/trip.dart';
import '../../../injection/injection.dart';
import '../../../l10n/app_localizations.dart';
import '../../bloc/recommendations/recommendations_bloc.dart';
import '../../widgets/common/tr_button.dart';
import '../../widgets/common/tr_loading.dart';
import '../../widgets/recommendations/feed_status_message.dart';
import '../../widgets/recommendations/swipe_card_deck.dart';

/// Asks for confirmation and, if given, clears the dislikes.
///
/// Dislikes have no list in the UI by design, so this is the traveller's way
/// out of accidental swipes. Favorites are never touched.
Future<void> confirmAndResetFeed(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final bloc = context.read<RecommendationsBloc>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(l10n.feedResetTitle),
      content: Text(l10n.feedResetBody),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l10n.cancel)),
        TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.feedResetConfirm)),
      ],
    ),
  );
  if (confirmed == true) bloc.add(const FeedDislikesResetRequested());
}

/// The "Descubrir" content: location, filters, the provider label and the deck.
///
/// Reads availability and attribution from the [PlacesGateway] exactly like
/// DiscoveryPage. While the gateway is the demo one the cards are labelled as
/// sample data and no city is claimed: the typed-city field is only offered
/// when a real provider can honour it.
class RecommendationsFeedView extends StatefulWidget {
  final Trip trip;

  const RecommendationsFeedView({super.key, required this.trip});

  @override
  State<RecommendationsFeedView> createState() =>
      _RecommendationsFeedViewState();
}

class _RecommendationsFeedViewState extends State<RecommendationsFeedView> {
  late final TextEditingController _city;

  PlacesGateway get _gateway => getIt<PlacesGateway>();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<RecommendationsBloc>();
    // The bloc outlives a tab switch, so the field starts from the location in
    // effect rather than always from the trip destination.
    _city = TextEditingController(
        text: bloc.state.destinationHint ?? widget.trip.destination);
    bloc.add(FeedStarted(destination: widget.trip.destination));
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  String _filterText(AppLocalizations l10n, RecommendationFilter filter) =>
      switch (filter) {
        RecommendationFilter.all => l10n.feedFilterAll,
        RecommendationFilter.monuments => l10n.feedFilterMonuments,
        RecommendationFilter.restaurants => l10n.feedFilterRestaurants,
        RecommendationFilter.leisure => l10n.feedFilterLeisure,
      };

  void _onRevision(BuildContext context, RecommendationsState state) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();

    final notice = state.notice;
    if (notice != null) {
      messenger.showSnackBar(SnackBar(
        content: Text(switch (notice) {
          FeedNotice.reactionFailed => l10n.feedReactionFailed,
          FeedNotice.undoFailed => l10n.feedUndoFailed,
          FeedNotice.resetDone => l10n.feedResetDone,
          FeedNotice.resetFailed => l10n.feedResetFailed,
        }),
      ));
      return;
    }

    final applied = state.lastReaction;
    if (applied == null) return;
    final bloc = context.read<RecommendationsBloc>();
    messenger.showSnackBar(SnackBar(
      content: Text(applied.reaction == PlaceReaction.like
          ? l10n.feedLiked
          : l10n.feedDisliked),
      // Floats above the always-visible reaction buttons so it never covers
      // them. An action makes a SnackBar persistent by default; undo must be
      // short-lived.
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(AppSizes.md, 0, AppSizes.md, 84),
      persist: false,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: l10n.feedUndo,
        onPressed: () => bloc.add(const FeedUndoRequested()),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final availability = _gateway.availability;
    final bloc = context.read<RecommendationsBloc>();

    return BlocConsumer<RecommendationsBloc, RecommendationsState>(
      listenWhen: (previous, current) => previous.revision != current.revision,
      listener: _onRevision,
      builder: (context, state) {
        final showControls = state.status != FeedStatus.unavailable;
        return Column(children: [
          if (showControls && availability == PlacesAvailability.configured)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.screenPaddingH,
                  AppSizes.sm, AppSizes.screenPaddingH, 0),
              child: TextField(
                controller: _city,
                textInputAction: TextInputAction.search,
                onSubmitted: (text) => bloc.add(FeedLocationChanged(text)),
                decoration: InputDecoration(
                  labelText: l10n.feedCityLabel,
                  prefixIcon: const Icon(Icons.location_on_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded),
                    tooltip: l10n.search,
                    onPressed: () => bloc.add(FeedLocationChanged(_city.text)),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
                ),
              ),
            ),
          if (showControls)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPaddingH, vertical: AppSizes.sm),
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: AppSizes.sm,
                  children: [
                    for (final filter in RecommendationFilter.values)
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(_filterText(l10n, filter)),
                        selected: state.filter == filter,
                        onSelected: (_) => bloc.add(FeedFilterChanged(filter)),
                      ),
                  ],
                ),
              ),
            ),
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
                    _gateway.attributionText ?? l10n.discoveryDemoData,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ]),
            ),
          Expanded(child: _body(context, state, l10n)),
        ]);
      },
    );
  }

  Widget _body(
      BuildContext context, RecommendationsState state, AppLocalizations l10n) {
    final bloc = context.read<RecommendationsBloc>();
    switch (state.status) {
      case FeedStatus.initial:
      case FeedStatus.loading:
        return const TRLoading();
      case FeedStatus.unavailable:
        return FeedStatusMessage(
          icon: Icons.cloud_off_rounded,
          title: l10n.discoveryProviderUnavailableTitle,
          message: l10n.discoveryProviderUnavailableBody,
        );
      case FeedStatus.error:
        return FeedStatusMessage(
          icon: Icons.error_outline_rounded,
          title: l10n.feedErrorTitle,
          message: state.errorMessage,
          actions: [
            TRButton(
                label: l10n.retry,
                onPressed: () => bloc.add(const FeedRetried())),
          ],
        );
      case FeedStatus.empty:
        return FeedStatusMessage(
          icon: Icons.travel_explore_rounded,
          title: l10n.feedEmptyTitle,
          message: l10n.feedEmptyBody,
        );
      case FeedStatus.exhausted:
        return FeedStatusMessage(
          icon: Icons.done_all_rounded,
          title: l10n.feedExhaustedTitle,
          message: l10n.feedExhaustedBody,
          actions: [
            if (state.filter != RecommendationFilter.all)
              TRButton(
                label: l10n.feedShowAll,
                onPressed: () => bloc
                    .add(const FeedFilterChanged(RecommendationFilter.all)),
              ),
            TRButton(
              label: l10n.feedResetAction,
              isOutlined: true,
              onPressed: () => confirmAndResetFeed(context),
            ),
          ],
        );
      case FeedStatus.ready:
        return SwipeCardDeck(
          cards: state.cards,
          onReact: (card, reaction) => bloc
              .add(FeedCardReacted(key: card.key, reaction: reaction)),
        );
    }
  }
}
