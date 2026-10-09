import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Centred icon, title, message and optional actions for the non-deck states of
/// the feed (unavailable, error, empty, exhausted).
class FeedStatusMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final List<Widget> actions;

  const FeedStatusMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: AppColors.primary),
          const SizedBox(height: AppSizes.md),
          Text(title,
              style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: AppSizes.sm),
            Text(message!,
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
          for (final action in actions) ...[
            const SizedBox(height: AppSizes.md),
            action,
          ],
        ]),
      ),
    );
  }
}
