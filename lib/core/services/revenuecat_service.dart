import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../utils/app_env.dart';

/// Servicio para manejar suscripciones mediante RevenueCat.
/// 
/// Configuración:
/// - Android: REVENUECAT_API_KEY en .env
/// - iOS: REVENUECAT_API_KEY_IOS en .env
/// 
/// Identificadores de productos esperados:
/// - 'premium_monthly' - Suscripción mensual
/// - 'premium_yearly' - Suscripción anual
class RevenueCatService {
  static bool get isConfigured => AppEnv.revenueCatApiKey.isNotEmpty;
  
  /// Inicializa RevenueCat con la API key correspondiente a la plataforma.
  static Future<void> initialize() async {
    final apiKey = Platform.isIOS 
        ? AppEnv.revenueCatApiKeyIOS 
        : AppEnv.revenueCatApiKey;
    
    if (apiKey.isEmpty) {
      throw Exception('RevenueCat API key no configurada en .env');
    }

    await Purchases.configure(
      PurchasesConfiguration(apiKey),
    );
  }

  /// Identifica al usuario autenticado en RevenueCat.
  static Future<void> identifyUser(String userId) async {
    if (!isConfigured) return;
    await Purchases.logIn(userId);
  }

  /// Cierra sesión del usuario en RevenueCat.
  static Future<void> logout() async {
    if (!isConfigured) return;
    await Purchases.logOut();
  }

  /// Obtiene los paquetes de suscripción disponibles.
  static Future<List<Package>> getOfferings() async {
    if (!isConfigured) throw Exception('RevenueCat no configurado');
    
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    
    if (current == null || current.availablePackages.isEmpty) {
      throw Exception('No hay ofertas disponibles');
    }
    
    return current.availablePackages;
  }

  /// Realiza la compra de un paquete.
  static Future<PurchaseResult> purchasePackage(Package package) async {
    if (!isConfigured) throw Exception('RevenueCat no configurado');
    return await Purchases.purchasePackage(package);
  }

  /// Restaura compras previas.
  static Future<CustomerInfo> restorePurchases() async {
    if (!isConfigured) throw Exception('RevenueCat no configurado');
    
    return await Purchases.restorePurchases();
  }

  /// Verifica si el usuario tiene suscripción activa.
  static Future<bool> isPremium() async {
    if (!isConfigured) return false;
    
    final customerInfo = await Purchases.getCustomerInfo();
    return customerInfo.entitlements.active.isNotEmpty;
  }

  /// Obtiene la información del cliente.
  static Future<CustomerInfo> getCustomerInfo() async {
    if (!isConfigured) throw Exception('RevenueCat no configurado');
    return await Purchases.getCustomerInfo();
  }

  /// Obtiene el paquete mensual si existe.
  static Future<Package?> getMonthlyPackage() async {
    final packages = await getOfferings();
    return packages.firstWhere(
      (p) => p.storeProduct.identifier.contains('monthly'),
      orElse: () => packages.first,
    );
  }

  /// Obtiene el paquete anual si existe.
  static Future<Package?> getYearlyPackage() async {
    final packages = await getOfferings();
    return packages.firstWhere(
      (p) => p.storeProduct.identifier.contains('yearly'),
      orElse: () => packages.first,
    );
  }

}
