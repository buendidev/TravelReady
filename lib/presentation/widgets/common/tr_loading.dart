import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../l10n/app_localizations.dart';

/// Indicador de carga estándar de TravelReady!
class TRLoading extends StatelessWidget {
  final Color? color;
  final double size;

  const TRLoading({
    super.key,
    this.color,
    this.size = 36,
  });

  /// Versión que ocupa toda la pantalla con fondo semitransparente.
  const TRLoading.overlay({super.key})
      : color = null,
        size = 36;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }
}

/// Pantalla de carga completa (para estados iniciales de BLoC)
class TRLoadingPage extends StatelessWidget {
  const TRLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: TRLoading(),
    );
  }
}

/// Widget de error con botón de reintento
class TRErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const TRErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.lg),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppLocalizations.of(context).retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
