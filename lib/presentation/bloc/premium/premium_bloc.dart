import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/services/revenuecat_service.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../injection/injection.dart';
import '../../../core/utils/app_log.dart';

part 'premium_event.dart';
part 'premium_state.dart';

/// BLoC para manejar el estado de suscripción Premium.
/// 
/// Se comunica con RevenueCatService para:
/// - Cargar ofertas de suscripción
/// - Realizar compras
/// - Restaurar compras previas
/// - Verificar estado de suscripción
/// 
/// También actualiza el plan del usuario en Firestore mediante AuthRepository.
class PremiumBloc extends Bloc<PremiumEvent, PremiumState> {
  final AuthRepository? _authRepo;

  PremiumBloc({AuthRepository? authRepo})
      : _authRepo = authRepo ?? getIt<AuthRepository>(),
        super(const PremiumInitial()) {
    on<PremiumLoadOfferings>(_onLoadOfferings);
    on<PremiumPurchaseMonthly>(_onPurchaseMonthly);
    on<PremiumPurchaseYearly>(_onPurchaseYearly);
    on<PremiumRestorePurchases>(_onRestorePurchases);
    on<PremiumCheckStatus>(_onCheckStatus);
  }

  Future<void> _onLoadOfferings(
    PremiumLoadOfferings event,
    Emitter<PremiumState> emit,
  ) async {
    emit(const PremiumLoading());
    
    try {
      if (!RevenueCatService.isConfigured) {
        emit(const PremiumError('RevenueCat no está configurado'));
        return;
      }

      final isPremium = await RevenueCatService.isPremium();
      final monthly = await RevenueCatService.getMonthlyPackage();
      final yearly = await RevenueCatService.getYearlyPackage();

      emit(PremiumOfferingsLoaded(
        monthlyPackage: monthly,
        yearlyPackage: yearly,
        isPremium: isPremium,
      ));
    } catch (e) {
      emit(PremiumError('Error cargando ofertas: $e'));
    }
  }

  Future<void> _onPurchaseMonthly(
    PremiumPurchaseMonthly event,
    Emitter<PremiumState> emit,
  ) async {
    emit(const PremiumLoading());
    
    try {
      final package = await RevenueCatService.getMonthlyPackage();
      if (package == null) {
        emit(const PremiumError('Paquete mensual no disponible'));
        return;
      }

      await RevenueCatService.purchasePackage(package);
      
      // Actualizar plan del usuario en Firestore
      await _updateUserPlan(isYearly: false);
      
      emit(const PremiumPurchased(isYearly: false));
    } catch (e) {
      // El usuario canceló o hubo error
      if (e.toString().contains('cancel')) {
        emit(const PremiumError('Compra cancelada'));
      } else {
        emit(PremiumError('Error en la compra: $e'));
      }
    }
  }

  Future<void> _onPurchaseYearly(
    PremiumPurchaseYearly event,
    Emitter<PremiumState> emit,
  ) async {
    emit(const PremiumLoading());
    
    try {
      final package = await RevenueCatService.getYearlyPackage();
      if (package == null) {
        emit(const PremiumError('Paquete anual no disponible'));
        return;
      }

      await RevenueCatService.purchasePackage(package);
      
      // Actualizar plan del usuario en Firestore
      await _updateUserPlan(isYearly: true);
      
      emit(const PremiumPurchased(isYearly: true));
    } catch (e) {
      if (e.toString().contains('cancel')) {
        emit(const PremiumError('Compra cancelada'));
      } else {
        emit(PremiumError('Error en la compra: $e'));
      }
    }
  }

  Future<void> _onRestorePurchases(
    PremiumRestorePurchases event,
    Emitter<PremiumState> emit,
  ) async {
    emit(const PremiumLoading());
    
    try {
      final customerInfo = await RevenueCatService.restorePurchases();
      final hasActive = customerInfo.entitlements.active.isNotEmpty;
      emit(PremiumRestored(wasRestored: hasActive));
    } catch (e) {
      emit(PremiumError('Error restaurando compras: $e'));
    }
  }

  Future<void> _onCheckStatus(
    PremiumCheckStatus event,
    Emitter<PremiumState> emit,
  ) async {
    try {
      final isPremium = await RevenueCatService.isPremium();
      if (state is PremiumOfferingsLoaded) {
        final current = state as PremiumOfferingsLoaded;
        emit(PremiumOfferingsLoaded(
          monthlyPackage: current.monthlyPackage,
          yearlyPackage: current.yearlyPackage,
          isPremium: isPremium,
        ));
      }
    } catch (e) {
      // No emitimos error para no interrumpir la UI
    }
  }

  /// Actualiza el plan del usuario en Firestore después de una compra.
  Future<void> _updateUserPlan({required bool isYearly}) async {
    try {
      final repo = _authRepo;
      if (repo == null) return;
      
      final userResult = await repo.getCurrentUser();
      final user = userResult.getRight().toNullable();
      
      if (user != null) {
        final renewalDate = isYearly 
            ? DateTime.now().add(const Duration(days: 365))
            : DateTime.now().add(const Duration(days: 30));
            
        await repo.updateUserPlan(
          user.id,
          plan: UserPlan.premium,
          renewalDate: renewalDate,
        );
      }
    } catch (e) {
      // Log pero no fallar la compra si esto falla
      // ignore: avoid_print
      AppLog.debug('Error actualizando plan en Firestore: $e');
    }
  }
}
