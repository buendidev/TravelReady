// Firestore security rules emulator suite for TravelReady.
//
// Runs against the Firestore emulator using the repository's own
// `firestore.rules` (never a copy). Default path resolves relative to this
// file; override with RULES_FILE=<path> only for mutation checks.
//
// Local run:
//   cd rules_test
//   npx firebase emulators:exec --only firestore --project demo-travelready "npm test"
//
// Project id uses the `demo-` prefix so the emulator never touches a real
// Firebase project and needs no credentials.

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { test, describe, before, after } from 'node:test';
import assert from 'node:assert/strict';

import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  getDocs,
  collection,
} from 'firebase/firestore';

const PROJECT_ID = 'demo-travelready';

const defaultRulesPath = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  '..',
  'firestore.rules',
);
const rulesPath = process.env.RULES_FILE
  ? path.resolve(process.env.RULES_FILE)
  : defaultRulesPath;

const [emulatorHost, emulatorPort] = (
  process.env.FIRESTORE_EMULATOR_HOST ?? 'localhost:8080'
).split(':');

let testEnv;

// Arrange helpers -----------------------------------------------------------

async function seed(path_, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path_), data);
  });
}

async function seedLater(path_, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path_), data, { merge: true });
  });
}

async function removeDoc(path_) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await deleteDoc(doc(ctx.firestore(), path_));
  });
}

const fs = (uid) => testEnv.authenticatedContext(uid).firestore();
const anonFs = () => testEnv.unauthenticatedContext().firestore();

const chat = { memberIds: ['u1', 'u2'], unreadBy: { u1: 0, u2: 0 } };
const message = { senderId: 'u1', text: 'hola', createdAt: '2026-04-01T00:00:00Z' };

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(rulesPath, 'utf8'),
      host: emulatorHost,
      port: Number(emulatorPort),
    },
  });
  console.log(`rules under test: ${rulesPath}`);
  console.log(`emulator: ${emulatorHost}:${emulatorPort}`);
});

after(async () => {
  await testEnv.cleanup();
});

// ── users ──────────────────────────────────────────────────────────────────

describe('users', () => {
  test('ALLOW: u1 creates users/u1 (own uid)', async () => {
    await removeDoc('users/u1');
    await assertSucceeds(
      setDoc(doc(fs('u1'), 'users/u1'), { name: 'uno', email: 'u1@x.dev' }),
    );
  });

  test('DENY: u2 creates users/u1 (uid squatting)', async () => {
    await removeDoc('users/u1');
    await assertFails(
      setDoc(doc(fs('u2'), 'users/u1'), { name: 'impersonado' }),
    );
  });

  test('DENY: anonymous creates users/u1', async () => {
    await removeDoc('users/u1');
    await assertFails(
      setDoc(doc(anonFs(), 'users/u1'), { name: 'fantasma' }),
    );
  });

  test('ALLOW: u1 updates users/u1', async () => {
    await seed('users/u1', { name: 'uno' });
    await assertSucceeds(updateDoc(doc(fs('u1'), 'users/u1'), { name: 'uno!' }));
  });

  test('DENY: u2 updates users/u1', async () => {
    await seed('users/u1', { name: 'uno' });
    await assertFails(updateDoc(doc(fs('u2'), 'users/u1'), { name: 'hack' }));
  });

  // Exposición transicional documentada en firestore.rules y
  // docs/production/threat-model.md ("User directory"): get/list abiertos a
  // cualquier usuario autenticado hasta que el modelo de amigos los
  // reemplace. Estas dos pruebas existen para que el cambio que las cierre
  // tenga que actualizarlas a DENY.
  test('DENY-expected-ALLOW (documented transitional exposure): u1 reads users/u2', async () => {
    await seed('users/u2', { name: 'dos', email: 'u2@x.dev' });
    await assertSucceeds(getDoc(doc(fs('u1'), 'users/u2')));
  });

  test('DENY-expected-ALLOW (documented transitional exposure): u1 lists users', async () => {
    await seedLater('users/u2', { name: 'dos' });
    const snap = await assertSucceeds(getDocs(collection(fs('u1'), 'users')));
    assert.ok(snap.size >= 1);
  });
});

// ── chats ──────────────────────────────────────────────────────────────────

describe('chats (memberIds: ["u1","u2"])', () => {
  before(async () => {
    await seed('chats/c1', chat);
  });

  test('ALLOW: member u1 updates unreadBy.u1', async () => {
    await assertSucceeds(
      updateDoc(doc(fs('u1'), 'chats/c1'), { 'unreadBy.u1': 3 }),
    );
  });

  test('DENY: member u1 adds u3 to memberIds', async () => {
    await assertFails(
      updateDoc(doc(fs('u1'), 'chats/c1'), {
        memberIds: ['u1', 'u2', 'u3'],
      }),
    );
  });

  test('DENY: member u1 shrinks memberIds to ["u1"]', async () => {
    await assertFails(
      updateDoc(doc(fs('u1'), 'chats/c1'), { memberIds: ['u1'] }),
    );
  });

  test('ALLOW: member u1 updates another field with memberIds unchanged', async () => {
    await assertSucceeds(
      updateDoc(doc(fs('u1'), 'chats/c1'), { lastMessageText: 'hola' }),
    );
  });

  test('DENY: non-member u3 reads the chat', async () => {
    await assertFails(getDoc(doc(fs('u3'), 'chats/c1')));
  });

  test('DENY: non-member u3 updates the chat', async () => {
    await assertFails(
      updateDoc(doc(fs('u3'), 'chats/c1'), { lastMessageText: 'intruso' }),
    );
  });

  test('DENY: member u1 deletes the chat', async () => {
    await assertFails(deleteDoc(doc(fs('u1'), 'chats/c1')));
  });

  test('DENY: anonymous deletes the chat', async () => {
    await assertFails(deleteDoc(doc(anonFs(), 'chats/c1')));
  });
});

// ── messages ───────────────────────────────────────────────────────────────

describe('messages (chats/c1/messages)', () => {
  before(async () => {
    await seed('chats/c1', chat);
    await seed('chats/c1/messages/m1', message);
  });

  test('ALLOW: member u1 sends with senderId == caller', async () => {
    await assertSucceeds(
      setDoc(doc(fs('u1'), 'chats/c1/messages/m2'), {
        senderId: 'u1',
        text: 'nuevo',
        createdAt: '2026-04-02T00:00:00Z',
      }),
    );
  });

  test('DENY: member u1 sends with someone else senderId', async () => {
    await assertFails(
      setDoc(doc(fs('u1'), 'chats/c1/messages/m3'), {
        senderId: 'u2',
        text: 'spoofed',
        createdAt: '2026-04-02T00:00:00Z',
      }),
    );
  });

  test('ALLOW: member u2 reads a message', async () => {
    await assertSucceeds(getDoc(doc(fs('u2'), 'chats/c1/messages/m1')));
  });

  test('DENY: non-member u3 reads a message', async () => {
    await assertFails(getDoc(doc(fs('u3'), 'chats/c1/messages/m1')));
  });

  test('DENY: member u1 updates a message', async () => {
    await assertFails(
      updateDoc(doc(fs('u1'), 'chats/c1/messages/m1'), { text: 'editado' }),
    );
  });

  test('DENY: member u1 deletes a message', async () => {
    await assertFails(deleteDoc(doc(fs('u1'), 'chats/c1/messages/m1')));
  });
});

// ── removed paths: trips / packingLists / packingItems ────────────────────
// Sin reglas para estas rutas: ningún cliente las alcanza (los datos viven
// en SQLite local) y Firestore deniega por defecto. Si una regla futura las
// vuelve a abrir, estas pruebas lo detectan.

describe('removed paths (default deny)', () => {
  const paths = [
    'trips/t1',
    'trips/t1/packingLists/l1',
    'trips/t1/packingLists/l1/packingItems/i1',
  ];

  for (const p of paths) {
    test(`DENY: authenticated u1 reads ${p}`, async () => {
      await assertFails(getDoc(doc(fs('u1'), p)));
    });

    test(`DENY: authenticated u1 writes ${p}`, async () => {
      await assertFails(setDoc(doc(fs('u1'), p), { name: 'x' }));
    });

    test(`DENY: anonymous reads ${p}`, async () => {
      await assertFails(getDoc(doc(anonFs(), p)));
    });

    test(`DENY: anonymous writes ${p}`, async () => {
      await assertFails(setDoc(doc(anonFs(), p), { name: 'x' }));
    });
  }
});
