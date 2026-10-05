# Local Android family-test runbook

## Current blocker

No APK can be built on this machine yet. `flutter doctor` reports that the Android SDK is missing, and both `ANDROID_HOME` and `ANDROID_SDK_ROOT` are empty. This runbook does not assert that an Android toolchain, signing credential, or device is available.

## Owner prerequisite

1. Install Android Studio and its Android SDK on the controlled local machine.
2. Install the required SDK platform/build tools and accept the Android SDK licences in the installed toolchain.
3. Record the actual SDK path. Do not guess it or share credentials.
4. Only after that path is known, configure Flutter if needed:

   ```text
   flutter config --android-sdk <actual-sdk-path>
   ```

No credential, keystore path, password, or store link is requested at this stage.

## Agent steps after the prerequisite is complete

1. Run `flutter doctor` and stop if Android toolchain checks still fail.
2. Confirm the available signing configuration without exposing its contents. The repository contains `android/key.properties`; build a signed release APK only when the local signing setup is valid.
3. Build the release APK with the repository's normal Flutter release command.
4. Generate and record a checksum for the produced APK.
5. Give the tester the APK path, checksum, and standard Android installation guidance. The tester must allow installation from the selected local source if Android asks.

## Family-test scope

Direct APK sideloading bypasses Google Play. It is suitable for a controlled local family test, not proof of Play distribution, store review, production signing ownership, or release readiness.

Offline-only testing is limited. Local SQLite trips and packing data work on the device without network access. Firebase authentication and chats, Google Sign-In, and weather/maps require network access and valid provider configuration. Test those provider-backed flows only after their owner-controlled configuration is available.

## Evidence to retain

Record the `flutter doctor` result, APK build command/result, APK checksum, device model/Android version, installation result, and tested online/offline scenarios. Do not record passwords, private keys, recovery codes, or other credentials.
