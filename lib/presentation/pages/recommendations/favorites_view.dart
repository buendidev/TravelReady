import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../domain/entities/trip.dart';
import '../../../l10n/app_localizations.dart';
import '../../bloc/recommendations/favorites_bloc.dart';
import '../../widgets/common/tr_button.dart';
import '../../widgets/common/tr_loading.dart';
import '../../widgets/discovery/place_card.dart';
import '../../widgets/discovery/place_details_sheet.dart';
import '../../widgets/recommendations/feed_status_message.dart';

/// The "Favoritos" tab: liked places, newest first, with the same card visuals
/// as discovery.
///
/// Opening one shows the existing details sheet, so "Sitio web oficial" and
/// "Añadir al itinerario" come with it. Removing a favorite only deletes it; it
/// is not a dislike, so the place can appear in the feed again.
class FavoritesView extends StatelessWidget {
  final Trip trip;

  const FavoritesView({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<FavoritesBloc, FavoritesState>(
      listenWhen: (previous, current) =>
          previous is FavoritesReady &&
          current is FavoritesReady &&
          (current.favorites.length < previous.favorites.length ||
              (current.removeFailed && current.revision != previous.revision)),
      listener: (context, state) {
        final ready = state as FavoritesReady;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(ready.removeFailed
                ? l10n.favoritesRemoveFailed
                : l10n.favoritesRemoved),
          ));
      },
      builder: (context, state) => switch (state) {
        FavoritesInitial() || FavoritesLoading() => const TRLoading(),
        FavoritesError(:final message) => FeedStatusMessage(
            icon: Icons.error_outline_rounded,
            title: l10n.favoritesErrorTitle,
            message: message,
            actions: [
              TRButton(
                label: l10n.retry,
                onPressed: () =>
                    context.read<FavoritesBloc>().add(const FavoritesStarted()),
              ),
            ],
          ),
        FavoritesReady(:final favorites) when favorites.isEmpty =>
          FeedStatusMessage(
            icon: Icons.favorite_border_rounded,
            title: l10n.favoritesEmptyTitle,
            message: l10n.favoritesEmptyBody,
          ),
        FavoritesReady(:final favorites) => ListView.builder(
            padding: const EdgeInsets.all(AppSizes.screenPaddingH),
            itemCount: favorites.length,
            itemBuilder: (context, i) {
              final favorite = favorites[i];
              final place = favorite.toPlaceResult();
              return PlaceCard(
                place: place,
                onTap: () => showPlaceDetailsSheet(context,
                    place: place, trip: trip),
                trailing: _RemoveButton(
                  label: l10n.favoritesRemove,
                  onPressed: () => context
                      .read<FavoritesBloc>()
                      .add(FavoriteRemoved(favorite.key)),
                ),
              );
            },
          ),
      },
    );
  }
}

/// "Quitar de favoritos" as a single accessibility node (label, button role and
/// tap action together); the tooltip stays for sighted long-press users.
class _RemoveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _RemoveButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        onTap: onPressed,
        excludeSemantics: true,
        child: IconButton(
          tooltip: label,
          icon: const Icon(Icons.favorite_rounded, color: AppColors.primary),
          onPressed: onPressed,
        ),
      );
}
