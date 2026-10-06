# TravelReady! 🧳✈️

**Aplicación móvil de planificación de viajes**  
© 2026 TravelReady · Pablo Buendicho Ortín

---

## 📱 Descripción

TravelReady! es una aplicación Flutter multiplataforma (Android/iOS) que permite a los usuarios planificar sus viajes de forma completa: gestión de viajes, listas de equipaje inteligentes, clima en tiempo real, mensajería con otros usuarios y asistente de IA integrado.

---

## 🏗️ Arquitectura

Clean Architecture + BLoC Pattern + Offline-First

```
Presentación (Flutter/BLoC) ←→ Dominio (UseCases/Entities) ←→ Datos (Firebase/Hive)
```

### Módulos
| # | Módulo | Estado |
|---|--------|--------|
| M0 | Foundation (tema, router, inyección) | ✅ |
| M1 | Autenticación (email + Google) | ✅ |
| M2 | Home + Clima (OpenWeatherMap) | ✅ |
| M3 | Listas de equipaje + Plantillas | ✅ |
| M4 | Viajes + Generación IA local | ✅ |
| M5 | Chats privados + grupos + Asistente IA | ✅ |
| M6 | Perfil + Idioma (ES/EN) + Tema | ✅ |
| M7 | Premium (UI lista, RevenueCat pendiente) | 🟡 |

---

## 🚀 Tecnologías

| Categoría | Paquete | Versión |
|-----------|---------|---------|
| Framework | Flutter | 3.x |
| Auth | firebase_auth | ^6.4 |
| BD remota | cloud_firestore | ^6.3 |
| Google Sign-In | google_sign_in | ^6.2 |
| BD local | hive_flutter | ^1.1 |
| Estado | flutter_bloc | ^9.1 |
| Navegación | go_router | ^17.2 |
| Inyección | get_it | ^9.2 |
| Funcional | fpdart | ^1.1 |

---

## ⚙️ Configuración

### 1. Variables de entorno

```bash
cp .env.example .env
# Editar .env con tus claves reales:
# OPENWEATHER_API_KEY=xxx
# GOOGLE_MAPS_API_KEY=xxx
```

### 2. Firebase

```bash
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar proyecto (requiere Firebase CLI instalado)
flutterfire configure --project=travelready-app

# Desplegar reglas e índices
firebase deploy --only firestore:rules,firestore:indexes,storage
```

### 3. Ejecutar

```bash
flutter pub get
flutter gen-l10n          # Genera archivos de localización
flutter run
```

---

## 🧪 Tests

```bash
flutter test                          # Todos los tests
flutter test --reporter=expanded      # Con detalle
flutter test test/domain/             # Solo dominio
flutter test test/presentation/bloc/  # Solo BLoCs
```

**Cobertura aproximada**: ~70 tests

---

## 📂 Estructura del proyecto

```
lib/
├── core/           Constantes, tema, router, utilidades, errores
├── data/           Datasources, modelos, repositorios
├── domain/         Entidades, repositorios (contratos), casos de uso
├── injection/      Configuración de dependencias (GetIt)
├── l10n/           Archivos de localización (ES + EN)
└── presentation/   BLoCs, páginas, widgets
```

---

## 🔐 Seguridad

- Rate limiting en auth (5 intentos / 15 min)
- Sanitización de inputs en todos los formularios
- Security logging sin PII
- Firestore Rules con validación de esquema
- Variables de entorno en `.env` (nunca en VCS)
- `usesCleartextTraffic="false"` en Android

---

## 🌍 Internacionalización

La app soporta **Español** e **Inglés**.  
Cambiar idioma en: Perfil → Idioma

---

## 📋 Licencia

© 2026 TravelReady · Pablo Buendicho Ortín.  
Todos los derechos reservados.
