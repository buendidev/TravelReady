# Firestore rules hardening

Branch: `fix/firestore-rules-hardening` (off `main` `01aaa48`)

## Why

`firestore.rules` is the only thing enforcing who reads and writes whose data
in the deployed app, and no client code change can compensate for it. The
native review of the tracked-build-inputs candidate
(`review-7117cc28ee590a76`, four of four lenses, approved and acknowledged)
admitted five findings against it, and the repository's own
`docs/production/threat-model.md` independently lists two of the same risks:
"cross-user reads/writes, forged memberships, mass listing and privileged field
changes", and "User directory: enumeration, bulk scraping, email/profile
leakage — do not equate login with unrestricted directory access".

## Findings in scope

| id | location | severity | what it says |
|----|----------|----------|--------------|
| `R1-001` | `firestore.rules:11-15` | WARNING | any authenticated user can **create** a `users` doc for an arbitrary `userId` (`isOwner(userId) \|\| isAuth()`), so a uid can be squatted before its real owner registers; and any authenticated user can `get`/`list` the whole directory |
| `R1-002` | `firestore.rules:41` | WARNING | `allow update: if isMember(resource.data)` lets a member rewrite `memberIds`, adding an arbitrary uid and keeping persistent access |
| `R2-002` | `firestore.rules:15` | WARNING | the `\|\| isAuth()` makes `isOwner(userId)` dead code: the condition reads as a check that does not check anything |
| `R3-rules-recorded-unfixed` | `firestore.rules:13-15` | WARNING | the rules were recorded as findings and left unfixed |
| `R4-2` | `firestore.rules:27-35` | WARNING | `get()` of the parent trip per candidate document in `packingLists`/`packingItems` |
## What the client actually uses

Verified by reading every Firestore call site, not by reading the rules:

- `lib/data/datasources/remote/firebase_auth_datasource.dart` — writes
  `users/<own uid>` on register (`:113`, `:118`) and updates it (`:216`,
  `:223`). It never writes another user's document.
- `lib/data/datasources/remote/firestore_chats_datasource.dart` — `chats`,
  `chats/*/messages`, and `users` for name resolution (`:46`, `:84`) plus the
  directory picker (`.get()` at `:239`, a `lastSeen` query at `:271-274`, an
  exact-email query at `:304-308`).
- `lib/data/datasources/remote/weather_service.dart` — no Firestore.
- There is **no** remote data source for `trips`, `packingLists` or
  `packingItems`. Those live in local SQLite (`docs/database_schema.md`
  documents them as tables with indexes and triggers), and
  `docs/production/launch-plan.md` contains no plan to move them to Firestore.

Consequences:

- The `users` directory exposure (`get`/`list`) is **load-bearing today**: the
  chat picker, the `lastSeen` query and the exact-email lookup all depend on it.
  Closing it means building the friends model, not tightening a rule.
- The `trips`, `packingLists` and `packingItems` rules are **unreachable from
  the client**. `R4-2` (a parent `get()` per candidate document) is a property
  of rules no client invokes.

## Decisions

- **D1 — close the `create` hole now.** `allow create: if isOwner(userId)`.
  Nothing in the client creates another user's document, so this is compatible
  today and it closes a real uid-squatting hole independently of the directory
  work. It also removes the dead `|| isAuth()` that `R2-002` names.
- **D2 — membership is fixed at creation.** No client path mutates
  `memberIds` after a chat exists (`:135` and `:157-161` set it at creation);
  what updates are `unreadBy.<uid>` (`:297`) and the chat counters (`:221`,
  `:227`). So `memberIds` is made immutable on update, which closes `R1-002`
  without breaking a feature.
- **D3 — the directory exposure stays open, and is documented as such.** The
  owner's target model is friends-only: no directory at all, a stable unique
  username, invitation links, friend requests with accept/reject, and trip
  group participants resolved through the friend list. That is a product
  feature, not a rule edit, and it is **not** in this unit. Pretending the
  exposure is closed by tightening a query would be the dishonest option.
- **D4 — the unreachable `trips`/`packingLists`/`packingItems` rules are
  deleted, on the owner's explicit decision.** The `R4-2` finding assumed those
  rules run; they cannot. Deleting them closes `R4-2` outright and shrinks the
  audited surface to the two collections a client actually reaches. The file
  records why those paths have no rules, so the absence reads as a decision
  rather than an oversight, and says they come back with emulator tests if the
  packing data ever syncs to Firestore. Firestore denies by default, so the
  deleted paths are closed, not open.

## Verification

The repository has no version-controlled Firestore emulator suite, and
`docs/production/threat-model.md` says rules are "unverified" until emulator
tests cover "anonymous, owner, other user, former member and unauthorized
field/query access". Node, Java and the Firebase CLI are available on this
machine, so this unit verified the rules against the **real emulator** before
claiming anything.

A throwaway harness outside the repository (own `firebase.json`, project
`demo-travelready`, `@firebase/rules-unit-testing`) ran the **same 21-case
suite twice**: once against `git show HEAD:firestore.rules`, once against the
working tree. The emulator genuinely started both times
(`Firestore Emulator was started in standard edition`,
`cloud-firestore-emulator-v1.20.4.jar`).

| case | old rules | new rules |
|------|-----------|-----------|
| `u2` creates `users/u1` (uid squatting) | **ALLOW — the hole** | DENY |
| member adds `u3` to `memberIds` | **ALLOW — the hole** | DENY |
| member shrinks `memberIds` to `[u1]` | **ALLOW — the hole** | DENY |
| the other 18 cases | as expected | as expected |
| `trips/x` read and write | allowed for the owner | **DENY** (rules deleted; the client has no such path) |
| `trips/x/packingLists/y`, `.../packingItems/z` read and write | allowed for the owner, each paying a parent `get()` | **DENY** (same) |

No case differs between the two runs other than those three, so the change
closes exactly what it claims and widens or narrows nothing else. The 18
control cases include the actions a legitimate client needs (own-uid create,
profile update, reading another user's doc, the directory list query,
`unreadBy` update, sending a message) and the actions that must stay denied
(sender spoofing, message edit, message delete, chat delete, non-member read
and write).

Not covered, stated plainly: the real chat-selector composite-index queries
were approximated by a `lastSeen` list query, and nothing was deployed to a
real Firebase project, so this is emulator behaviour, not deployed-state
evidence.

## Out of scope

- The friends/directory feature (`R1-001`'s exposure half).
- `users.create`-adjacent storage rules (`storage.rules`).
- Wiring an emulator rules suite into CI — a separate decision with real CI
  cost, not smuggled into a rules fix. The owner has since asked for it, as its
  own unit.
