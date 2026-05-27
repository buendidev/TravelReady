part of 'premium_bloc.dart';

sealed class PremiumState extends Equatable {
  const PremiumState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class PremiumInitial extends PremiumState {
  const PremiumInitial();
}

/// Cargando ofertas o procesando compra
class PremiumLoading extends PremiumState {
  const PremiumLoading();
}

/// Ofertas cargadas exitosamente
class PremiumOfferingsLoaded extends PremiumState {
  final Package? monthlyPackage;
  final Package? yearlyPackage;
  final bool isPremium;

  const PremiumOfferingsLoaded({
    this.monthlyPackage,
    this.yearlyPackage,
    this.isPremium = false,
  });

  @override
  List<Object?> get props => [monthlyPackage, yearlyPackage, isPremium];
}

/// Compra exitosa
class PremiumPurchased extends PremiumState {
  final bool isYearly;
  const PremiumPurchased({required this.isYearly});

  @override
  List<Object?> get props => [isYearly];
}

/// Restauración exitosa
class PremiumRestored extends PremiumState {
  final bool wasRestored;
  const PremiumRestored({required this.wasRestored});

  @override
  List<Object?> get props => [wasRestored];
}

/// Error en el proceso
class PremiumError extends PremiumState {
  final String message;
  const PremiumError(this.message);

  @override
  List<Object?> get props => [message];
}
