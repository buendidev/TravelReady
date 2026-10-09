# Guía de Bases de Datos - TravelReady!

> **Aviso (2026-10-09): casi todo este documento describe una arquitectura Hive
> que el proyecto NO usa.** No hay Hive, ni `hive_constants.dart`, ni modelos
> `@HiveType`: es documentación de una versión anterior. La persistencia local
> real es **SQLite** (`sqflite`) a través de `lib/core/database/database_helper.dart`
> y sus datasources tipados. Verificado contra `pubspec.yaml` y `lib/`.

## Arquitectura de Datos

TravelReady! utiliza una arquitectura **híbrida**:

- **Firestore (Nube)**: Datos principales del usuario, viajes, listas
- **Hive (Local)**: Caché offline, preferencias, datos temporales

---

## 1. Firestore (Firebase)

### Colecciones Principales

```
users/{userId}
  ├── id: string
  ├── name: string
  ├── email: string
  ├── plan: "free" | "premium"
  ├── planRenewalDate: timestamp (opcional)
  ├── createdAt: timestamp
  └── photoUrl: string (opcional)

trips/{tripId}
  ├── id: string
  ├── userId: string (referencia)
  ├── name: string
  ├── destination: string
  ├── startDate: timestamp
  ├── endDate: timestamp
  ├── tripType: string (vacation, business, etc.)
  ├── transport: string (flight, car, train, etc.)
  ├── activities: array<string>
  ├── createdAt: timestamp
  └── updatedAt: timestamp

packingLists/{listId}
  ├── id: string
  ├── tripId: string (referencia)
  ├── userId: string (referencia)
  ├── name: string
  ├── createdAt: timestamp
  └── updatedAt: timestamp

packingItems/{itemId}
  ├── id: string
  ├── listId: string (referencia)
  ├── tripId: string (referencia)
  ├── userId: string (referencia)
  ├── name: string
  ├── category: string
  ├── quantity: number
  ├── isPacked: boolean
  ├── order: number
  ├── createdAt: timestamp
  └── updatedAt: timestamp

chats/{chatId}
  ├── id: string
  ├── userId: string (referencia)
  ├── type: "support" | "ai" | "group"
  ├── name: string
  ├── createdAt: timestamp
  └── updatedAt: timestamp

messages/{messageId}
  ├── id: string
  ├── chatId: string (referencia)
  ├── userId: string (referencia)
  ├── text: string
  ├── isUser: boolean
  ├── createdAt: timestamp
  └── read: boolean
```

### Índices Recomendados

```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "trips",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "startDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "packingItems",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "listId", "order": "ASCENDING" },
        { "fieldPath": "order", "order": "ASCENDING" }
      ]
    }
  ]
}
```

---

## 2. Hive (Local Storage)

### Cajas (Boxes)

```dart
// lib/core/constants/hive_constants.dart
abstract class HiveBoxes {
  static const String trips = 'trips_cache';
  static const String packingLists = 'packing_lists_cache';
  static const String packingItems = 'packing_items_cache';
  static const String settings = 'app_settings';
  static const String user = 'user_cache';
}
```

### Modelos Hive

```dart
@HiveType(typeId: 1)
class TripHiveModel extends HiveObject {
  @HiveField(0)
  late String id;
  
  @HiveField(1)
  late String name;
  
  @HiveField(2)
  late String destination;
  
  @HiveField(3)
  late DateTime startDate;
  
  @HiveField(4)
  late DateTime endDate;
  
  @HiveField(5)
  late DateTime syncedAt; // Para control de sincronización
}
```

---

## 3. Estrategia de Sincronización

### Modo Online
```dart
// Datos se leen/escriben directamente en Firestore
// Hive se usa como caché transparente
```

### Modo Offline
```dart
// 1. Leer de Hive primero
// 2. Mostrar datos cacheados inmediatamente
// 3. Intentar sincronizar cuando haya conexión
// 4. Guardar operaciones pendientes en cola
```

### Cola de Sincronización
```dart
class SyncQueue {
  static const String boxName = 'sync_queue';
  
  // Operaciones pendientes
  // { type: 'create'|'update'|'delete', collection: string, data: map }
}
```

---

## 4. Configuración Inicial

### Paso 1: Crear proyecto Firebase
```bash
# Ir a https://console.firebase.google.com
# Crear proyecto → TravelReady
# Agregar app Android (com.travelready.app)
# Descargar google-services.json → android/app/
```

### Paso 2: Configurar Firestore Rules
```javascript
// firestore.rules (ya configurado en el proyecto)
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usuarios solo pueden leer/escribir su propio documento
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Viajes: propietario o miembros
    match /trips/{tripId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.resource.data.userId == request.auth.uid);
    }
    
    // Listas de packing: misma lógica
    match /packingLists/{listId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

### Paso 3: Habilitar IndexedDB para offline
```dart
// android/app/build.gradle
defaultConfig {
    minSdkVersion 21  // Requerido para Firestore offline
}

// ios/Runner/Info.plist (ya incluido en el proyecto)
```

---

## 5. Migraciones

### Versión 1 → 2
```dart
// lib/core/database/migrations.dart
class DatabaseMigrations {
  static Future<void> migrateV1ToV2() async {
    final box = await Hive.openBox('app_data');
    final version = box.get('db_version', defaultValue: 1);
    
    if (version < 2) {
      // Realizar migración
      await _migrateTripsToV2();
      await box.put('db_version', 2);
    }
  }
}
```

---

## 6. Backup y Restore

### Backup Manual
```dart
// Exportar datos del usuario
Future<String> exportUserData(String userId) async {
  final trips = await _firestore.getTrips(userId);
  final lists = await _firestore.getPackingLists(userId);
  
  final backup = {
    'trips': trips.map((t) => t.toJson()).toList(),
    'lists': lists.map((l) => l.toJson()).toList(),
    'exportedAt': DateTime.now().toIso8601String(),
  };
  
  return jsonEncode(backup);
}
```

---

## 7. Seguridad

### Datos Sensibles
- **NO almacenar** contraseñas en Firestore (usar Firebase Auth)
- **NO almacenar** información de pago (usar RevenueCat)
- **SÍ almacenar** tokens de sesión en `flutter_secure_storage`

### Validación
```dart
// Sanitizar inputs antes de guardar
final sanitizedName = InputSanitizer.sanitize(tripName);
final validDestination = InputSanitizer.validateCity(destination);
```

---

## 8. Monitoreo

### Métricas Recomendadas
- Tamaño de colecciones por usuario
- Latencia de lectura/escritura
- Tasa de errores de sincronización
- Uso de modo offline

### Alertas
```dart
// Notificar si sync falla múltiples veces
if (syncFailures > 3) {
  Analytics.log('sync_failure_streak', {'count': syncFailures});
}
```
