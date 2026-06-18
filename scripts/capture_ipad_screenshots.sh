#!/usr/bin/env bash
# Capture App Store screenshots on iPad Air 11-inch simulator for Guideline 2.3.2.
# Run from repo root after building the app in Xcode (Product → Run on iPad Air 11-inch M3).
#
# Usage:
#   ./scripts/capture_ipad_screenshots.sh [output_dir]
#
# Manual flow (recommended):
#   1. Xcode → iPad Air 11-inch (M3) → Product → Run
#   2. Premium screen → ⌘S (screenshot 1 — pricing, no overlay needed)
#   3. Home → banner "Purchase required to connect" visible → ⌘S (shot 2)
#   4. Servers tab → "Browse free · Purchase to connect" → ⌘S (shot 3)
#   5. Sign in review@yencodetech.com / YencodeReview2026! → connect VPN → ⌘S (shot 4)
#   6. Upload to App Store Connect → iPad 13" Display

set -euo pipefail

OUT_DIR="${1:-$HOME/Desktop/ghostroute-ipad-screenshots}"
mkdir -p "$OUT_DIR"

if ! xcrun simctl list devices booted | grep -q "Booted"; then
  echo "No booted simulator. Open Xcode, select iPad Air 11-inch (M3), and Product → Run first."
  exit 1
fi

STAMP=$(date +%Y%m%d-%H%M%S)
FILE="$OUT_DIR/ipad-$STAMP.png"
xcrun simctl io booted screenshot "$FILE"
echo "Saved: $FILE"
echo ""
echo "Navigate the app to each required screen and run this script again, or use ⌘S in Simulator."
echo "Upload all images to App Store Connect → Ghost Route → iPad 13\" Display."
echo "See app_store_connect/APP_STORE_METADATA.md section 6 for required shot order."
