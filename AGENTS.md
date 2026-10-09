# AGENTS.md — TravelReady! Orchestrator
# TravelReady! — Guía del agente | Actualizado: Abril 2026

## Stack
Flutter 3.x · firebase_auth ^5.5.2 · cloud_firestore ^5.6.5 · google_sign_in **^6.2.1**
flutter_bloc ^9.1 · go_router ^17.2 · get_it ^9.2 · sqflite ^2.3.0 · fpdart ^1.1
url_launcher ^6.3 · http ^1.2

> Estas versiones son las de `pubspec.yaml`, que es la única fuente de verdad.
> **No hay Hive en este proyecto**: ni dependencia, ni código, ni boxes.

## Reglas críticas (NO ROMPER)

### google_sign_in v6
```dart
// injection.dart
GoogleSignIn(scopes: ['email', 'profile'])
// auth_remote_datasource.dart
final gUser = await _google.signIn();  // v6 API
```

### PackingItem — tripId SIEMPRE obligatorio
```dart
PackingItem(id:'', listId:'lid', tripId:'tid', name:'X')
```

### PackingBloc — sin add() dentro de _onItemAdded
Optimistic update local, stream reacciona automáticamente.

### WeatherBloc — sin compute()
http.Client no es Sendable entre isolates. Llamada directa async.

### AuthBloc — registro usa await
```dart
// _onSignUp: await result.fold((f) async {...}, (_) async {...})
await _signOut();  // AWAIT obligatorio antes de emit AuthRegistered
emit(AuthRegistered(email: ...));
```

### _onStarted — no pisar AuthRegistered
```dart
onData: (user) {
  if (user == null && state is AuthRegistered) return state; // guard
  ...
}
```

### Persistencia local — SQLite, nunca Hive
No existe Hive en este proyecto. Todo lo local pasa por `sqflite` a través de
`lib/core/database/database_helper.dart` y datasources tipados:
users, trips, tripTransport, tripActivities, packingLists, packingItems,
chats, chatMembers, messages, sessions, weatherCache.

```dart
// La tabla se declara en las migraciones de database_helper.dart
// y el datasource la usa tipada (no hay boxes dinámicas).
```

Al agregar una tabla nueva, declararla en `database_helper.dart` además del
`CREATE TABLE IF NOT EXISTS` perezoso del datasource.

### TripModel / PackingListModel — copyWith propio
Ambos modelos tienen @override copyWith() que devuelve el tipo concreto
(no el tipo base Trip/PackingList) para que Firestore pueda asignar IDs.

### watchPackingLists — tipo correcto
```dart
Stream<List<PackingList>> watchPackingLists(String tid)  // FirestoreDataSource
// PackingBloc usa emit.forEach<List<PackingList>>(...)
```

## Estado módulos
| M | Estado |
|---|--------|
| M0 Foundation | ✅ |
| M1 Auth email + Google | ✅ |
| M2 Home + Clima | ✅ |
| M3 Packing + Plantillas | ✅ |
| M4 Trips + filtros + búsqueda | ✅ |
| M5 Chats + IA + Soporte | ✅ (la "IA" es un asistente local por reglas, sin proveedor LLM) |
| M6 Profile + idioma + tema | ✅ |
| M7 Premium UI | ✅ (RevenueCat pendiente) |
| M8 Discovery + itinerario | ✅ (gateway demo; Google Places real bloqueado por cuentas del owner) |
| M9 Feed de recomendaciones con swipe | 📋 especificado — `docs/handoff/recommendations-feed.md` |
| M10 LLM del asistente | 📋 especificado — `docs/handoff/ai-assistant-llm.md` |

## Estado del repositorio (2026-10-09)

- `main` con CI verde: `analyze`, checker estructural del sitio, tests de `tool/`
  y `flutter test` (46 archivos). El job del emulador de Firestore
  (`rules_test/firestore.rules.test.js`) **todavia NO esta en `main`**: vive en la
  rama del PR #7, sin mergear. Antes de afirmar que un check corre, verificarlo en
  `main` y no en la rama donde se escribio.
- Endurecimiento de `firestore.rules` (el directorio de usuarios sigue abierto a
  propósito, con decisión de producto pendiente de implementar) más la suite del
  emulador en `rules_test/`, con job propio en CI.
- Discovery e itinerario sobre una frontera provider-neutral (`PlacesGateway`, con
  `DemoPlacesGateway` como implementación registrada y datos etiquetados como de
  ejemplo). La conexión real depende de prerequisitos del owner: `docs/places-integration.md`.
- Handoff a otro agente (Windsurf/Devin): `docs/handoff/README.md`.

## Novedades de sesiones anteriores
- TripsPage: buscador + filtros (Todos/Próximos/En curso/Pasados)
- TripCard: badge estado (EN CURSO / PASADO) + borde verde activo
- AuthBloc: guard AuthRegistered en _onStarted, await en signOut
- TripModel/PackingListModel: copyWith() propio para safe casting
- FirestoreDataSource: watchPackingLists tipado como Stream<List<PackingList>>
- PackingBloc: emit.forEach<List<PackingList>> (tipo correcto)
- ProfilePage: acceso directo a Soporte e IA desde menú

## Antes de tocar nada

Si sos un agente externo (Windsurf, Devin, Cursor…), leé primero
`docs/handoff/README.md`. Ahí están el contrato de trabajo y la lista de
documentos del repo que describen arquitectura que **no existe**
(AWS, MariaDB, Hive) y que no hay que tomar como estado del proyecto.
