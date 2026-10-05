import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Servicio de criptografía para manejo seguro de contraseñas y datos.
/// 
/// NOTA: En producción usar bcrypt nativo. Aquí usamos una implementación
/// segura con salt + SHA256 + pepper para el TravelReady.
class CryptoService {
  static const String _pepper = 'TravelReady!2025SecureKey';
  static const int _saltLength = 32;
  static const int _iterations = 10000;

  /// Genera un salt aleatorio seguro
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(_saltLength, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Hashea una contraseña con salt + pepper + múltiples iteraciones
  /// 
  /// Retorna: "salt:hash" para almacenar en base de datos
  static String hashPassword(String password) {
    final salt = _generateSalt();
    final hash = _hashWithSalt(password, salt);
    return '$salt:$hash';
  }

  /// Verifica una contraseña contra un hash almacenado
  /// 
  /// El hash almacenado debe estar en formato "salt:hash"
  static bool verifyPassword(String password, String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final expectedHash = parts[1];
      final actualHash = _hashWithSalt(password, salt);
      
      // Comparación constant-time para prevenir timing attacks
      return _constantTimeCompare(expectedHash, actualHash);
    } catch (e) {
      return false;
    }
  }

  /// Hashea con salt + pepper
  static String _hashWithSalt(String password, String salt) {
    String hash = password + salt + _pepper;
    
    // Múltiples iteraciones de SHA256
    for (int i = 0; i < _iterations; i++) {
      final bytes = utf8.encode(hash);
      final digest = sha256.convert(bytes);
      hash = digest.toString();
    }
    
    return hash;
  }

  /// Comparación constant-time para prevenir timing attacks
  static bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Genera un ID único seguro (UUID v4)
  static String generateUuid() {
    final random = Random.secure();
    final bytes = Uint8List(16);
    
    for (int i = 0; i < 16; i++) {
      bytes[i] = random.nextInt(256);
    }
    
    // UUID v4 variant
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Genera un token de sesión seguro
  static String generateSessionToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(64, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// Hashea un email para logs (ofuscación parcial)
  static String hashEmailForLog(String email) {
    final parts = email.toLowerCase().trim().split('@');
    if (parts.length != 2) return 'invalid';
    
    final local = parts[0];
    final domain = parts[1];
    
    // Mostrar solo primeros 2 y últimos 2 caracteres del local
    if (local.isEmpty) {
      return '***@$domain';
    }
    if (local.length <= 4) {
      return '${local[0]}***@$domain';
    }
    
    return '${local.substring(0, 2)}***${local.substring(local.length - 2)}@${domain}';
  }

  /// Sanitiza input para prevenir inyección básica
  static String sanitizeInput(String input) {
    return input
        .replaceAll("'", "''")
        .replaceAll('"', '\\"')
        .replaceAll(';', '')
        .replaceAll('--', '')
        .trim();
  }
}
