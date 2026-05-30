# Firebase setup for `com.yencode.ghostroute`

Bundle IDs in `google-services.json`, `GoogleService-Info.plist`, and `lib/firebase_options.dart` have been updated to `com.yencode.ghostroute`. Firebase must register matching apps or Analytics/Crashlytics will not link correctly.

## Console steps

1. Open [Firebase Console](https://console.firebase.google.com/) → project **adtest-76f2f** (or your production project).
2. **Project settings** → **Your apps**:
   - **Add app** → Android → package name: `com.yencode.ghostroute`
   - **Add app** → iOS → bundle ID: `com.yencode.ghostroute`
3. Download is optional if you use FlutterFire CLI below.

## Regenerate config (recommended)

From the repo root, with [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup) installed and logged in:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Select the Firebase project and platforms (android, ios, macos). This updates:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`
- `firebase.json`

Commit the regenerated files.

## Until Firebase apps exist

`iosBundleId` / `package_name` in repo match the new ID. If you have not added the apps in Firebase yet, `Firebase.initializeApp()` may still work with the old `appId` until you run `flutterfire configure` with the new registrations.
