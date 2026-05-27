# SECURITY.md — TravelReady! 🔐
Implementado según CLAUDE.md. Estado actual + roadmap.

---

## ✅ Implementado ahora

### 1. Rate Limiting (CLAUDE.md §1)
`lib/core/utils/rate_limiter.dart`
- Auth (login/registro/reset): **5 intentos / 15 min** por email hashed
- Bloqueo con mensaje: "Espera X minutos"
- Reset automático en login exitoso
- Sin estado server-side en esta fase (client-side guard + Firebase server-side nativo)

### 2. Secretos y Variables de Entorno (CLAUDE.md §2)
- API keys en `.env` → en `.gitignore` ✅
- `EnvValidator.validate()` en `main()` → warning en dev, error en prod
- `firebase_options.dart` en `.gitignore` ✅
- `google-services.json` / `GoogleService-Info.plist` en `.gitignore` ✅

### 3. Validación de Inputs (CLAUDE.md §3)
`lib/core/utils/input_sanitizer.dart`
- `sanitize()` elimina `<>"\x00`
- Validadores: email regex, password mín 6, nombre 2-60 chars, trip 0-80 chars
- `InputSanitizer` usado en: `AuthBloc`, `PackingBloc`, `TripsBloc`
- Firebase SDK usa queries parametrizadas → sin riesgo de inyección NoSQL

### 4. Autenticación Segura (CLAUDE.md §5)
- Firebase Auth gestiona tokens JWT con refresh automático
- Sesión persistida en `SharedPreferences` cifrado por Firebase SDK
- Google Sign-In con OAuth2 estándar
- Contraseñas hasheadas por Firebase (bcrypt interno) → nunca llegan al cliente
- Logout limpia tanto Firebase Auth como Google Sign-In

### 5. Logging de Seguridad (CLAUDE.md §6)
`lib/core/utils/security_log.dart`
- `authFailed(emailHash, reason)` — hash del email, sin PII
- `rateLimitExceeded(key, attempts)`
- `inputRejected(field, reason)`
- `sessionEvent(event, uid_prefix)` — solo 6 chars del UID
- En producción: sustituir `print` por Firebase Crashlytics / Cloud Logging

### 6. Reglas de Firestore
`firestore.rules`
- Usuario solo lee/escribe su propio doc (`userId == request.auth.uid`)
- Validación de esquema en create (campos requeridos, tipos)
- Subcolecciones protegidas con `get()` al padre
- No se permite borrar usuarios desde cliente

---

## 📋 Pendiente (prioridad para producción)

### Alta prioridad
- [ ] **HTTPS / TLS** — Flutter usa HTTPS por defecto. Verificar en Android: `network_security_config.xml` sin `cleartext`
- [ ] **Certificate Pinning** — Añadir `dio_certificate_pincer` para peticiones a APIs externas (OpenWeather, Google Maps)
- [ ] **Firebase App Check** — Activar en Firebase Console para verificar que las peticiones vienen de la app real (evita scraping)
- [ ] **Ofuscación Android** — Activar ProGuard/R8 en `build.gradle` para producción
- [ ] **Rate limiting server-side** — Crear Cloud Functions con `firebase-functions-rate-limiter` para endpoints críticos

### Media prioridad
- [ ] **Crashlytics logging** — Reemplazar `print` en `SecurityLog` por `FirebaseCrashlytics.instance.log()`
- [ ] **Sensitive data in memory** — Limpiar passwords de memoria tras uso (`_passCtrl.clear()` ya implementado)
- [ ] **Deeplink validation** — Validar esquema de deeplinks en `AndroidManifest.xml`
- [ ] **Android Keystore** — Guardar tokens sensibles en Android Keystore via `flutter_secure_storage`
- [ ] **Biometric auth** — `local_auth` para re-autenticar antes de operaciones sensibles

### Baja prioridad (post-TravelReady)
- [ ] **GDPR Compliance** — Política de privacidad + consentimiento explícito
- [ ] **Data encryption at rest** — Cifrar datos de Hive con `hive_flutter` AES key
- [ ] **Audit log en Firestore** — Colección `audit_logs` con timestamps de acciones
- [ ] **2FA** — Firebase Auth soporta TOTP como segundo factor
- [ ] **Penetration testing** — OWASP Mobile Top 10 checklist

---

## Firestore Security Rules — explicación

```javascript
// Regla clave: userId == auth.uid en TODOS los accesos
allow read: if request.auth != null && resource.data.userId == request.auth.uid;

// Validación de esquema en create (evita datos malformados)
allow create: if isAuthenticated() && isValidTrip();

// Subcolecciones: verifican que el padre pertenece al usuario
allow read, write: if get(/trips/$(tripId)).data.userId == request.auth.uid;
```

---

## Variables de entorno requeridas

```env
# .env (nunca subir al repo)
OPENWEATHER_API_KEY=     # https://openweathermap.org/api
GOOGLE_MAPS_API_KEY=     # https://console.cloud.google.com

# .env.example (sí subir al repo, sin valores)
OPENWEATHER_API_KEY=
GOOGLE_MAPS_API_KEY=
```

---

## Checklist antes de release

```
[ ] flutter_lints sin warnings
[ ] firebase_options.dart en .gitignore
[ ] google-services.json en .gitignore
[ ] .env en .gitignore
[ ] Firestore rules desplegadas: firebase deploy --only firestore:rules
[ ] Firebase App Check activado
[ ] ProGuard activado en android/app/build.gradle
[ ] debugShowCheckedModeBanner: false ✅ (ya implementado)
[ ] No hay print() en código de producción (solo en SecurityLog con assert)
```
