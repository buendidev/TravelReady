# Local Android build and family-test runbook

## Verified state on the controlled machine

- `flutter doctor` reports a healthy Android toolchain (Android SDK 37.0.0). The SDK path is recorded in `android/local.properties`, so `ANDROID_HOME` and `ANDROID_SDK_ROOT` do **not** need to be set for Flutter to find it.
- `flutter build apk --debug` succeeds and writes `build/app/outputs/flutter-apk/app-debug.apk`.
- Latest artifact: **178,311,398 bytes**, SHA-256 `56cdd703a234b363e22a0de4734d07aa601ce3ba019500a439f6cf310f77babb`.
- **No Android device is connected.** `flutter devices` lists only Chrome, and `adb devices` is empty, so the on-device walkthrough below has not been run.
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
