# Ghost Route — iOS build

## Important: always use the workspace

Open **`Runner.xcworkspace`**, not `Runner.xcodeproj`.

Building from `Runner.xcodeproj` causes:

```
Framework 'Pods_Runner' not found
Linker command failed with exit code 1
```

CocoaPods lives in the workspace (`Pods/Pods.xcodeproj`). Xcode must build `Pods_Runner` before linking the app.

```bash
open ios/Runner.xcworkspace
```

## After `flutter clean`

Regenerate iOS deps before building in Xcode:

```bash
flutter pub get
cd ios && pod install && cd ..
```

## Recommended build commands

**From Flutter (device/simulator):**

```bash
flutter run
# or
flutter build ios
```

**From Xcode:**

1. Open `ios/Runner.xcworkspace`
2. Select the **Runner** scheme
3. Product → Clean Build Folder (⇧⌘K)
4. Product → Build (⌘B)

## If linking still fails

1. Quit Xcode
2. Clean Flutter + Pods:

```bash
flutter clean
flutter pub get
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

3. Clear DerivedData for this project (Xcode → Settings → Locations → Derived Data → delete `Runner-*`)
4. Reopen `Runner.xcworkspace` and build again
