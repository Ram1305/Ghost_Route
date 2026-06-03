#!/usr/bin/env bash
# Fixes Xcode "invalid reuse after initialization failure" (stale DerivedData after a failed build).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Flutter clean"
flutter clean
flutter pub get

echo "==> Remove iOS build artifacts"
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks ios/build
rm -rf build/ios

echo "==> Clear Xcode DerivedData for this app"
DERIVED=~/Library/Developer/Xcode/DerivedData
if [ -d "$DERIVED" ]; then
  find "$DERIVED" -maxdepth 1 -type d \( -name 'Runner-*' -name '*ghostroute*' -name '*Ghost*' \) 2>/dev/null | while read -r d; do
    rm -rf "$d"
    echo "    removed $d"
  done
  # Broader clean if nothing matched (safe: only Runner-related folders)
  find "$DERIVED" -maxdepth 1 -type d -name 'Runner-*' -exec rm -rf {} + 2>/dev/null || true
fi

echo "==> pod install"
cd ios
pod install --repo-update
cd "$ROOT"

echo "==> Done. Build with: flutter run   or open ios/Runner.xcworkspace in Xcode"
echo "    In Xcode: Product > Clean Build Folder (Shift+Cmd+K) before first build."
