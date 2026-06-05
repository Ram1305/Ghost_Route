#!/usr/bin/env bash
# Build and run Ghost Route on the iOS Simulator WITH StoreKit testing enabled.
#
# `flutter run` does NOT apply the Xcode scheme StoreKit configuration, which
# causes storekit_no_response. This script uses xcodebuild so Products.storekit
# is loaded from the Runner scheme.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIMULATOR="${1:-iPhone 16}"
DERIVED="$ROOT/build/ios_storekit"
WORKSPACE="$ROOT/ios/Runner.xcworkspace"

cd "$ROOT"
flutter pub get

echo "Building for iOS Simulator ($SIMULATOR)..."
xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme Runner \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=$SIMULATOR" \
  -derivedDataPath "$DERIVED" \
  build

APP="$DERIVED/Build/Products/Debug-iphonesimulator/Runner.app"
if [[ ! -d "$APP" ]]; then
  echo "Runner.app not found at $APP" >&2
  exit 1
fi

echo "Booting simulator and installing app..."
xcrun simctl boot "$SIMULATOR" 2>/dev/null || true
open -a Simulator
xcrun simctl install booted "$APP"

echo ""
echo "Launching from Xcode so StoreKit config applies..."
echo "If the app does not start automatically:"
echo "  1. open ios/Runner.xcworkspace"
echo "  2. Select simulator '$SIMULATOR'"
echo "  3. Product → Run (⌘R)"
echo ""

open "$WORKSPACE"
