part of 'premium_bloc.dart';

sealed class PremiumEvent extends Equatable {
  const PremiumEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar ofertas disponibles
class PremiumLoadOfferings extends PremiumEvent {
  const PremiumLoadOfferings();
}

/// Comprar paquete mensual
class PremiumPurchaseMonthly extends PremiumEvent {
  const PremiumPurchaseMonthly();
}

/// Comprar paquete anual
class PremiumPurchaseYearly extends PremiumEvent {
  const PremiumPurchaseYearly();
}

/// Restaurar compras previas
class PremiumRestorePurchases extends PremiumEvent {
  const PremiumRestorePurchases();
}

/// Verificar estado actual de suscripción
class PremiumCheckStatus extends PremiumEvent {
  const PremiumCheckStatus();
}
