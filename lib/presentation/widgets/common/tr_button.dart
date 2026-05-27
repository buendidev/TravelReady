import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

/// Botón CTA principal de TravelReady!
/// Soporta estado de carga, variante outline e icono opcional.
class TRButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Widget? icon;
  final Size? size;

  const TRButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final minSize = size ?? const Size(double.infinity, AppSizes.buttonHeight);
    final child = isLoading ? _loader() : _label(context);

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(minimumSize: minSize),
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [icon!, const SizedBox(width: 8), child],
              )
            : child,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(minimumSize: minSize),
      child: icon != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [icon!, const SizedBox(width: 8), child],
            )
          : child,
    );
  }

  Widget _loader() => const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );

  Widget _label(BuildContext context) => Text(label);
}
