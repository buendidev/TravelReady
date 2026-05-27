import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

// ── Vistas Premium ───────────────────────────────────────────────────────────

class MockPremiumView extends StatelessWidget {
  final bool yearly;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSubscribe;

  const MockPremiumView({
    required this.yearly,
    required this.onToggle,
    required this.onSubscribe,
  });

  static const _features = [
    (Icons.all_inclusive_rounded,        'Listas de equipaje ilimitadas'),
    (Icons.auto_awesome_rounded,         'Generación automática con IA'),
    (Icons.wifi_off_rounded,             'Mapas y clima sin conexión'),
    (Icons.block_rounded,                'Sin anuncios'),
    (Icons.cloud_sync_rounded,           'Sincronización en la nube'),
    (Icons.support_agent_rounded,        'Soporte prioritario 24/7'),
  ];

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingH),
        child: Column(children: [
          const SizedBox(height: AppSizes.md),
          const Icon(Icons.workspace_premium_rounded,
              size: 72, color: Color(0xFFD4A017)),
          const SizedBox(height: AppSizes.md),

          Text(AppStrings.goPremium,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28, fontWeight: FontWeight.w700,
                color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.sm),

          Text('Lleva tu planificación al siguiente nivel',
              style: TextStyle(fontSize: 15,
                  color: Colors.white.withOpacity(0.7)),
              textAlign: TextAlign.center),

          const SizedBox(height: AppSizes.xl),

          _Toggle(yearly: yearly, onToggle: onToggle),

          const SizedBox(height: AppSizes.xl),

          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(
                text: yearly ? '89,99 €' : '9,99 €',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 48, fontWeight: FontWeight.w700,
                  color: Colors.white),
              ),
              TextSpan(
                text: yearly ? '/año' : '/mes',
                style: TextStyle(fontSize: 18,
                    color: Colors.white.withOpacity(0.6)),
              ),
            ]),
          ),
          if (yearly)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Ahorra un 25% vs mensual',
                  style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFFD4A017).withOpacity(0.9),
                      fontWeight: FontWeight.w500)),
            ),

          const SizedBox(height: AppSizes.xl),
          _ComparisonTable(),
          const SizedBox(height: AppSizes.xl),
          ..._features.map((f) => _FeatureRow(icon: f.$1, label: f.$2)),
          const SizedBox(height: AppSizes.xl),

          ElevatedButton(
            onPressed: onSubscribe,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A017),
              minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: Text('Empezar prueba gratuita 7 días',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Colors.white)),
          ),
          const SizedBox(height: AppSizes.sm),
          Text('Cancela cuando quieras. Sin compromiso.',
              style: TextStyle(fontSize: 12,
                  color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: AppSizes.xl),

          Text(
            '${yearly ? '89,99 €' : '9,99 €'} / '
            '${yearly ? 'año' : 'mes'} · '
            'Se renueva automáticamente · Cancela en cualquier momento',
            style: TextStyle(fontSize: 10,
                color: Colors.white.withOpacity(0.35)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xl),
        ]),
      ),
    );
  }
}

class RevenueCatPremiumView extends StatelessWidget {
  final bool yearly;
  final ValueChanged<bool> onToggle;
  final VoidCallback onSubscribe;
  final VoidCallback onRestore;
  final Package? monthlyPackage;
  final Package? yearlyPackage;

  const RevenueCatPremiumView({
    required this.yearly,
    required this.onToggle,
    required this.onSubscribe,
    required this.onRestore,
    this.monthlyPackage,
    this.yearlyPackage,
  });

  static const _features = [
    (Icons.all_inclusive_rounded,        'Listas de equipaje ilimitadas'),
    (Icons.auto_awesome_rounded,         'Generación automática con IA'),
    (Icons.wifi_off_rounded,             'Mapas y clima sin conexión'),
    (Icons.block_rounded,                'Sin anuncios'),
    (Icons.cloud_sync_rounded,           'Sincronización en la nube'),
    (Icons.support_agent_rounded,        'Soporte prioritario 24/7'),
  ];

  String _getPrice(bool yearly) {
    final pkg = yearly ? yearlyPackage : monthlyPackage;
    if (pkg != null) return pkg.storeProduct.priceString;
    return yearly ? '89,99 €' : '9,99 €';
  }

  String _getPeriod(bool yearly) {
    final pkg = yearly ? yearlyPackage : monthlyPackage;
    if (pkg != null) {
      return pkg.packageType == PackageType.annual ? '/año' : '/mes';
    }
    return yearly ? '/año' : '/mes';
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingH),
        child: Column(children: [
          const SizedBox(height: AppSizes.md),
          const Icon(Icons.workspace_premium_rounded,
              size: 72, color: Color(0xFFD4A017)),
          const SizedBox(height: AppSizes.md),

          Text(AppStrings.goPremium,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28, fontWeight: FontWeight.w700,
                color: Colors.white),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.sm),

          Text('Lleva tu planificación al siguiente nivel',
              style: TextStyle(fontSize: 15,
                  color: Colors.white.withOpacity(0.7)),
              textAlign: TextAlign.center),

          const SizedBox(height: AppSizes.xl),

          _Toggle(yearly: yearly, onToggle: onToggle),

          const SizedBox(height: AppSizes.xl),

          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(
                text: _getPrice(yearly),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 48, fontWeight: FontWeight.w700,
                  color: Colors.white),
              ),
              TextSpan(
                text: _getPeriod(yearly),
                style: TextStyle(fontSize: 18,
                    color: Colors.white.withOpacity(0.6)),
              ),
            ]),
          ),
          if (yearly)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Ahorra un 25% vs mensual',
                  style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFFD4A017).withOpacity(0.9),
                      fontWeight: FontWeight.w500)),
            ),

          const SizedBox(height: AppSizes.xl),
          _ComparisonTable(),
          const SizedBox(height: AppSizes.xl),
          ..._features.map((f) => _FeatureRow(icon: f.$1, label: f.$2)),
          const SizedBox(height: AppSizes.xl),

          ElevatedButton(
            onPressed: onSubscribe,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A017),
              minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: Text('Suscribirse ahora',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Colors.white)),
          ),
          const SizedBox(height: AppSizes.sm),

          TextButton(
            onPressed: onRestore,
            child: Text('Restaurar compras',
                style: TextStyle(fontSize: 14,
                    color: Colors.white.withOpacity(0.6))),
          ),

          const SizedBox(height: AppSizes.lg),

          Text(
            '${_getPrice(yearly)} / '
            '${_getPeriod(yearly).replaceAll('/', '')} · '
            'Se renueva automáticamente · Cancela en cualquier momento',
            style: TextStyle(fontSize: 10,
                color: Colors.white.withOpacity(0.35)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xl),
        ]),
      ),
    );
  }
}

class PremiumActiveView extends StatelessWidget {
  final VoidCallback onRestore;

  const PremiumActiveView({required this.onRestore});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPaddingH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.workspace_premium_rounded,
                size: 80, color: Color(0xFFD4A017)),
            const SizedBox(height: AppSizes.lg),
            Text('¡Ya eres Premium!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: Colors.white),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.md),
            Text('Disfruta de todas las funciones exclusivas',
                style: TextStyle(fontSize: 16,
                    color: Colors.white.withOpacity(0.7)),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.xl),
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
                border: Border.all(color: const Color(0xFFD4A017).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 40),
                  const SizedBox(height: AppSizes.md),
                  const Text('Suscripción activa',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: AppSizes.sm),
                  Text('Tienes acceso ilimitado a todas las funciones',
                      style: TextStyle(fontSize: 14,
                          color: Colors.white.withOpacity(0.6)),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            TextButton(
              onPressed: onRestore,
              child: Text('Restaurar compras',
                  style: TextStyle(fontSize: 14,
                      color: Colors.white.withOpacity(0.6))),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets internos compartidos ──────────────────────────────────────────────

class _Toggle extends StatelessWidget {
  final bool yearly;
  final ValueChanged<bool> onToggle;
  const _Toggle({required this.yearly, required this.onToggle});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
    ),
    child: Row(children: [
      Expanded(child: _Pill(
        label: 'Mensual', selected: !yearly,
        onTap: () => onToggle(false))),
      Expanded(child: _Pill(
        label: 'Anual  🏷️ -25%', selected: yearly,
        onTap: () => onToggle(true))),
    ]),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: selected ? AppColors.backgroundDark : Colors.white54)),
    ),
  );
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primaryLight, size: 18),
      ),
      const SizedBox(width: AppSizes.md),
      Text(label, style: const TextStyle(fontSize: 15, color: Colors.white)),
    ]),
  );
}

class _ComparisonTable extends StatelessWidget {
  static const _rows = [
    ('Listas de equipaje', false, true),
    ('Hasta 3 listas', true, false),
    ('Listas ilimitadas', false, true),
    ('Generación IA básica', true, true),
    ('Generación IA avanzada', false, true),
    ('Sincronización cloud', false, true),
    ('Mapas sin conexión', false, true),
    ('Soporte prioritario', false, true),
    ('Sin anuncios', false, true),
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(AppSizes.radiusDefault),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    ),
    child: Column(children: [
      Row(children: [
        Expanded(
          flex: 2,
          child: Text('',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
        ),
        Expanded(
          child: Text('FREE',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
        ),
        Expanded(
          child: Text('PREMIUM',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: const Color(0xFFD4A017), letterSpacing: 1)),
        ),
      ]),
      Divider(color: Colors.white.withOpacity(0.1), height: AppSizes.lg),
      ..._rows.map((r) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
            flex: 2,
            child: Text(r.$1,
                style: const TextStyle(fontSize: 14, color: Colors.white)),
          ),
          Expanded(
            child: Center(
              child: r.$2
                  ? const Icon(Icons.check_rounded, color: Colors.white54, size: 18)
                  : const Icon(Icons.close_rounded, color: Colors.white24, size: 18),
            ),
          ),
          Expanded(
            child: Center(
              child: r.$3
                  ? const Icon(Icons.check_rounded, color: Color(0xFFD4A017), size: 18)
                  : const Icon(Icons.close_rounded, color: Colors.white24, size: 18),
            ),
          ),
        ]),
      )),
    ]),
  );
}
