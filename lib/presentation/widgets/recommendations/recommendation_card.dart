import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/places/place_result.dart';
import '../../../l10n/app_localizations.dart';
import '../discovery/place_card.dart';
import '../discovery/place_category_labels.dart';

/// One card of the swipe feed.
///
/// Same visual language as [PlaceCard] (primary gradient with the category
/// icon, since no provider photo is used), plus the category chip, the price
/// label and the address. Presentation only: it holds no gesture logic.
class RecommendationCard extends StatelessWidget {
  final PlaceResult place;

  const RecommendationCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(builder: (context, constraints) {
      final roomy = constraints.maxHeight >= 420;
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: AppSizes.shadowBlur,
              offset: const Offset(0, AppSizes.shadowOffset),
            ),
          ],
        ),
        child: Column(children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(PlaceCard.iconFor(place.category),
                  color: Colors.white, size: 88),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name,
                    style: theme.textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (place.address != null) ...[
                  const SizedBox(height: AppSizes.xs),
                  Row(children: [
                    const Icon(Icons.place_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(place.address!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
                const SizedBox(height: AppSizes.sm),
                Wrap(spacing: AppSizes.sm, runSpacing: AppSizes.xs, children: [
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(placeCategoryLabel(l10n, place.category)),
                  ),
                  if (place.priceLevelLabel != null)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(place.priceLevelLabel!),
                    ),
                ]),
                if (roomy && place.shortDescription != null) ...[
                  const SizedBox(height: AppSizes.sm),
                  Text(place.shortDescription!,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ]),
      );
    });
  }
}
