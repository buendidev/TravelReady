import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/revenuecat_service.dart';
import '../../bloc/premium/premium_bloc.dart';
import '../../widgets/common/tr_loading.dart';
import 'premium_widgets.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PremiumBloc()..add(const PremiumLoadOfferings()),
      child: const _PremiumView(),
    );
  }
}

class _PremiumView extends StatefulWidget {
  const _PremiumView();
  @override State<_PremiumView> createState() => _PremiumViewState();
}

class _PremiumViewState extends State<_PremiumView> {
  bool _yearly = true;

  void _onToggle(bool yearly) => setState(() => _yearly = yearly);

  void _onSubscribe() {
    if (_yearly) {
      context.read<PremiumBloc>().add(const PremiumPurchaseYearly());
    } else {
      context.read<PremiumBloc>().add(const PremiumPurchaseMonthly());
    }
  }

  void _onRestore() {
    context.read<PremiumBloc>().add(const PremiumRestorePurchases());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundDark,
              AppColors.primaryDark,
              AppColors.backgroundDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: AppSizes.sm),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                _PremiumBadge(),
              ]),
            ),

            // Content con BLoC
            BlocConsumer<PremiumBloc, PremiumState>(
              listener: (context, state) {
                if (state is PremiumPurchased) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('¡Suscripción completada! 🎉'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.of(context).pop(true);
                } else if (state is PremiumRestored) {
                  if (state.wasRestored) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Compras restauradas correctamente'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    Navigator.of(context).pop(true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se encontraron compras para restaurar'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  }
                } else if (state is PremiumError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is PremiumLoading) {
                  return const Expanded(
                    child: Center(child: TRLoading(color: Colors.white)),
                  );
                }

                final offerings = state is PremiumOfferingsLoaded ? state : null;
                final isPremium = offerings?.isPremium ?? false;

                // Ya es premium
                if (isPremium) {
                  return PremiumActiveView(onRestore: _onRestore);
                }

                // Sin RevenueCat configurado - modo mock
                if (!RevenueCatService.isConfigured) {
                  return MockPremiumView(
                    yearly: _yearly,
                    onToggle: _onToggle,
                    onSubscribe: _onSubscribe,
                  );
                }

                // Con RevenueCat configurado
                return RevenueCatPremiumView(
                  yearly: _yearly,
                  onToggle: _onToggle,
                  onSubscribe: _onSubscribe,
                  onRestore: _onRestore,
                  monthlyPackage: offerings?.monthlyPackage,
                  yearlyPackage: offerings?.yearlyPackage,
                );
              },
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Widget simple ─────────────────────────────────────────────────────────────

class _PremiumBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
    ),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.workspace_premium_rounded,
          color: Color(0xFFD4A017), size: 16),
      SizedBox(width: 4),
      Text('PREMIUM',
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: Color(0xFFD4A017), letterSpacing: 1.2)),
    ]),
  );
}

