import 'package:connectivity_plus/connectivity_plus.dart';

/// Comprueba el estado de la conexión a internet.
/// Inyectado como singleton en GetIt.
class ConnectivityChecker {
  final Connectivity _connectivity;

  ConnectivityChecker({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Devuelve true si hay conexión a internet activa.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  /// Stream que emite cambios de conectividad en tiempo real.
  Stream<bool> get connectivityStream => _connectivity.onConnectivityChanged
      .map((results) => results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet));
}
