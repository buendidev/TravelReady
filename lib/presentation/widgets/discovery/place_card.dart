import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/places/place_category.dart';
import '../../../core/services/places/place_result.dart';
import '../../../l10n/app_localizations.dart';
import 'place_category_labels.dart';

/// Tarjeta de lugar para el grid/lista de descubrimiento.
/// Imagen con fallback: sin `photoReference` útil se muestra un
/// degradado con el icono de la categoría (sin red ni claves).
class PlaceCard extends StatelessWidget {
  final PlaceResult place;
  final VoidCallback onTap;

  const PlaceCard({super.key, required this.place, required this.onTap});

  static IconData iconFor(PlaceCategory c) => switch (c) {
        PlaceCategory.monument => Icons.account_balance_rounded,
        PlaceCategory.museum => Icons.museum_rounded,
        PlaceCategory.food => Icons.restaurant_rounded,
        PlaceCategory.nature => Icons.park_rounded,
        PlaceCategory.nightlife => Icons.nightlife_rounded,
        PlaceCategory.shopping => Icons.shopping_bag_rounded,
        PlaceCategory.hotel => Icons.hotel_rounded,
        PlaceCategory.other => Icons.place_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
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
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(AppSizes.radiusLg)),
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(iconFor(place.category),
                  color: Colors.white, size: 34),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(place.address ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(placeCategoryLabel(AppLocalizations.of(context), place.category),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: AppColors.primary)),
                    if (place.priceLevelLabel != null) ...[
                      const SizedBox(width: 8),
                      Text(place.priceLevelLabel!,
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ]),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: AppSizes.sm),
              child: Icon(Icons.chevron_right_rounded),
            ),
          ]),
        ),
      ),
    );
  }
}
