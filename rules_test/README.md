# Firestore rules emulator suite

Suite de `node --test` que carga el `firestore.rules` del repositorio en el
emulador de Firestore y afirma la matriz de permitir / denegar. Usa el runner
integrado de Node (sin jest ni mocha); las únicas dependencias son
`@firebase/rules-unit-testing` y `firebase-tools`, ambas con versión fija en
`package.json` y `package-lock.json`.

## Para qué sirve

`firestore.rules` es la única frontera de seguridad real de los datos en
Firestore. Un cambio en las reglas es un edit de una línea sin error de
compilación: el fallo solo se ve cuando alguien lee datos ajenos. Esta suite
hace que ese fallo sea un test rojo en CI antes del deploy, no un incidente.

Cada caso importante es un par: la acción que debe permitirse y la acción casi
idéntica que debe denegarse. Una suite que solo comprueba que la app funciona
no puede detectar un agujero en las reglas.

## Cómo ejecutarlo

```bash
cd rules_test
npx firebase emulators:exec --only firestore --project demo-travelready "npm test"
```

Requiere Java (el emulador de Firestore es un jar) y Node 24+. No necesita
credenciales ni conexión a ningún proyecto real.

## Proyecto del emulador

El id de proyecto es `demo-travelready`. El prefijo `demo-` hace que el SDK de
Firebase nunca intente alcanzar producción: todo queda en el emulador local en
`localhost:8080` (configurado en el bloque `emulators` de `firebase.json`, el
mismo que usa CI).

## Qué se prueba

- `users`: crear/actualizar solo el doc propio; crear el de otro uid (usurpar
  identidad) denegado; lectura y listado del directorio permitidos, que es la
  exposición transicional documentada en `firestore.rules` que el modelo de
  amigos reemplazará.
- `chats`: un miembro puede actualizar sus contadores pero no `memberIds`
  (ni ampliarlo ni reducirlo); no miembros sin acceso; nadie borra.
- `messages`: `senderId` siempre igual al llamador; lectura solo para
  miembros; nadie edita ni borra mensajes.
- `trips` y sus subcolecciones: denegado por defecto para todos, porque
  ninguna regla los cubre y ningún cliente los alcanza.

## Suite contra una copia de las reglas (mutation check)

Para verificar que la suite puede fallar, apúntala a una copia debilitada sin
tocar el `firestore.rules` del repo:

```bash
RULES_FILE=/tmp/firestore.rules.mutated \
  npx firebase emulators:exec --only firestore --project demo-travelready "npm test"
```

El valor por defecto de `RULES_FILE` es el `firestore.rules` del repositorio;
la suite nunca prueba una copia versionada, solo el archivo real.
