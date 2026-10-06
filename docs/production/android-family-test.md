# Local Android build and family-test runbook

## Verified state on the controlled machine

- `flutter doctor` reports a healthy Android toolchain (Android SDK 37.0.0). The SDK path is recorded in `android/local.properties`, so `ANDROID_HOME` and `ANDROID_SDK_ROOT` do **not** need to be set for Flutter to find it.
- `flutter build apk --debug` succeeds and writes `build/app/outputs/flutter-apk/app-debug.apk`.
- Latest artifact: **177,881,630 bytes**, SHA-256 `f57e508cb74a3ff78ca2c0f54b5e07438c864b9c3524a605965140628b2b246d`, built from `62956a2`.
- A first on-device walkthrough was run on a **vivo V2440 (Android 16)** over USB: Home, trip detail, itinerary (add and persist a plan), discovery, packing lists, chats and profile all rendered, with **zero `E/flutter` or fatal entries** in logcat for the whole session. Details below.
- `android/key.properties` is **not** present in this checkout, so a signed *release* APK cannot be produced yet. The debug artifact is the only one available, and it is suitable for a controlled sideload test — not for distribution.

## Owner prerequisite for the device test

1. Connect an Android phone over USB and enable USB debugging in developer options.
2. Accept the RSA authorization prompt on the phone.
3. Confirm the connection: `adb devices` must list the phone as `device` (not `unauthorized`, not empty).

## Build and install

```powershell
flutter doctor                     # the Android toolchain line must be green
flutter build apk --debug          # writes build/app/outputs/flutter-apk/app-debug.apk
flutter install --debug            # or: adb install -r <apk path>
```

Re-record the artifact size and SHA-256 whenever the APK is rebuilt: an APK reports what the code did, not what the documentation says.

## Driver for the walkthrough

The pass is driven by `tool/android_walkthrough.py`, a dependency-free script
that reads the accessibility tree and sends taps. It exists because the first
attempt at this walkthrough lied twice, and both lessons are built into it:

```powershell
python tool/android_walkthrough.py focus      # foreground package
python tool/android_walkthrough.py list       # geometry, clickability and text
python tool/android_walkthrough.py tap "Perfil"
python tool/android_walkthrough.py text        # before/after comparison
python tool/android_walkthrough.py errors      # Flutter error lines in logcat
```

Two traps it encodes:

- **`uiautomator dump` leaves the previous file on the device when it fails**, so
  retrieving it returns a stale tree that looks exactly like fresh state. The
  script deletes the remote file first and refuses to parse a dump it cannot
  confirm.
- **`adb shell input tap` drops events.** During the 2026-10-06 pass one tap on a
  navigation item was silently lost and the screen looked frozen for a single
  measurement. Never conclude that the interface is frozen from one synthetic
  tap: retry it and corroborate with the tree, the foreground package and
  logcat. This is the same class of error as reading geometry as proof that
  something is painted.

## Checklist for the walkthrough

Run this on the device and record the result of each line.

- Splash and login; register with email; sign out and back in; Google sign-in.
- Home: greeting with the real name, avatar initials, weather card, next or active trip.
- Trips: create, search, filters (todos, próximos, en curso, pasados), open a detail page.
- Trip detail: planning cards present; a trip with **no packing lists** renders the empty state without the overflow banner that used to appear.
- Packing: create a list, toggle an item, watch the progress update.
- Itinerary: add, edit, delete, reorder, and check the day grouping.
- Discovery: search, change category, open the official site, add the place to a day.
- Chats: private chat and group chat.
- Profile: avatar initials with a padded or repeated-space name, theme switch, language switch.
- Airplane mode: packing and itinerary still readable; weather and discovery degrade without a crash.

## Evidence to retain

`flutter doctor` output, the build command and its result, the artifact size and SHA-256, the device model and Android version, the install result, and the checklist results. Do not record passwords, private keys, recovery codes or any other credential.

## Scope limitation

Sideloading bypasses Google Play. It is suitable for a controlled local family test, and it is not proof of store review, production signing ownership, Play distribution or release readiness.

## Walkthrough results (2026-10-05, vivo V2440, Android 16)

| Screen | Result |
| --- | --- |
| Home | Greeting with the session name, next-trip card, live weather for the destination (17 °C, Paris), premium banner, quick actions |
| Trip detail | Both planning cards present; the zero-packing-lists empty state renders with **no overflow banner** |
| Itinerary | Day grouping with the device locale ("dom 11 oct"), a plan created from the editor sheet, persisted and re-rendered with its category label |
| Discovery | Search field, category chips, real venue fixtures with address, category and indicative price, and the honest "Datos de ejemplo — sin proveedor configurado" notice |
| Packing lists | Empty state plus both bottom actions; template and create buttons reachable |
| Chats | Empty state with the private-chat and group prompts |
| Profile | Session user, email, free plan, language, theme and support entries |

### Defect found and fixed by this walkthrough

Every bottom-anchored action was painted **behind** the bottom navigation bar, because the shell wrapped each tab with `extendBody` and `Scaffold` therefore reserved no room for the bar. On the itinerary screen that button is the only way to add a plan, so the feature was unreachable: the accessibility tree placed it at y 2194-2348 while the bar started at 2170. It cannot be compensated with `MediaQuery` padding, because `Scaffold` positions a FAB from `viewInsets`, not from padding — verified against the Flutter source and by measurement. Dropping `extendBody` fixes it for every page. After the fix the itinerary button sits at y 1947-2101, above the bar at 2146, and a plan was created and persisted from the device.

## Walkthrough results (2026-10-06, vivo V2440, Android 16, built from `62956a2`)

This pass chased the owner-reported Home freeze and verified the modal-scoping
fix on hardware. **The freeze did not reproduce**, and the geometry of the only
mechanism that fits it is gone.

| Check | Result |
| --- | --- |
| Home | Greeting, trip card, luggage progress, live weather (20 °C, 54 %), premium banner, quick actions; the bar switches tabs |
| Modal scoping (the unit under test) | With a sheet open the bar's buttons are **absent from the accessibility tree** and the tree reaches **y=2392**, the real screen edge. Before the fix a sheet anchored to the body (ending at y=2145) and left the bar alive and tappable. With a sheet up, a tap on another tab is absorbed instead of navigating |
| Trips | Search field and four filter chips; the chip row scrolls horizontally, so "Pasados" being clipped at the edge is a scroll position, not an overflow |
| Trip detail | Both planning cards; the zero-packing-lists empty state renders with **no RenderFlex overflow** in logcat |
| Itinerary | Day grouping, two plans with categories and delete actions, and the add-plan FAB at y=2024, **above** the bar at y=2244 — the regression this runbook was written for |
| Discovery | Search, category chips, the sample-data notice and the venue fixtures |
| Chats | Private and group prompts plus the assistant and support entries |
| Profile | Avatar initials, free plan, stats, premium, theme and language entries |
| Theme switch | "Modo claro" flips to "Modo oscuro" and back with the layout intact |
| Language switch | The app was exercised in English: profile, trip detail, **itinerary** ("Edit plan", "Start · 10:00", "End · optional", all six categories) and discovery, with provider data staying as the provider returns it |
| Airplane mode, warm | Home renders from local data and the weather card shows the last reading labelled **"Stale data · 9 min ago"** |
| Airplane mode, cold start | The stored session is restored and the app lands on Home, but only after roughly **40 seconds** of splash |
| Rotation | Landscape and back to portrait with zero overflow entries; auto-rotation restored afterwards |
| Flutter errors | **Zero** `E/flutter` entries for the whole session |

### Finding: the offline cold start takes about 40 seconds

With no network, a force-stopped app waits out the full startup grace (30 s)
before restoring the stored session, so the reader stares at the splash for
roughly forty seconds to reach data that is already on the phone. The restore
works and the session is later re-verified against Firebase, so the delay does
not protect anything the snapshot restore does not already cover. A shorter
provisional restore that keeps listening would show the user their data in a few
seconds, at the cost of briefly showing a session that Firebase may then revoke.
That trade is a product decision, not a bug fix.

### Still not covered on a device

- Google Sign-In and anything that needs a second account.
- The provider-backed flows, which are all disabled until the owner configures Google Cloud, Maps and Places.
- iOS, tablets, and a low-storage or low-battery run.
- Creating a packing list and toggling an item was covered on 2026-10-05; the
  2026-10-06 pass opened the list, the templates sheet and the empty state, but
  did not create or toggle anything.
