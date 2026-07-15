#!/bin/bash
set -e

# Log to a temp file for debugging
LOG_FILE="/tmp/wireguard_build_log.txt"
echo "--- Build started at $(date) ---" > "$LOG_FILE"
echo "ACTION: $1" >> "$LOG_FILE"
echo "BUILD_DIR: $BUILD_DIR" >> "$LOG_FILE"
echo "SYMROOT: $SYMROOT" >> "$LOG_FILE"
echo "SOURCE_ROOT: $SOURCE_ROOT" >> "$LOG_FILE"
echo "PATH: $PATH" >> "$LOG_FILE"

# Ensure Go is in PATH (common locations on Intel + Apple Silicon Macs)
export PATH="/opt/homebrew/bin:/usr/local/go/bin:/usr/local/bin:$PATH"
echo "Updated PATH: $PATH" >> "$LOG_FILE"

if ! command -v go &> /dev/null; then
    echo "error: go not found in PATH. Install with: brew install go cmake" | tee -a "$LOG_FILE" >&2
    exit 1
fi

ACTION="$1"

find_wireguard_kit_go() {
    local start_dir="$1"
    local search_dir="$start_dir"
    local depth=0
    local max_depth=12

    while [ -n "$search_dir" ] && [ "$depth" -lt "$max_depth" ]; do
        local candidate="$search_dir/SourcePackages/checkouts/wireguard-apple/Sources/WireGuardKitGo"
        echo "Depth $depth: $candidate" >> "$LOG_FILE"
        if [ -d "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
        local parent
        parent="$(dirname "$search_dir")"
        if [ "$parent" = "$search_dir" ]; then
            break
        fi
        search_dir="$parent"
        depth=$((depth + 1))
    done
    return 1
}

TARGET_DIR=""
for ROOT in "$BUILD_DIR" "$SYMROOT" "$SOURCE_ROOT"; do
    if [ -n "$ROOT" ]; then
        echo "Searching from: $ROOT" >> "$LOG_FILE"
        if FOUND=$(find_wireguard_kit_go "$ROOT"); then
            TARGET_DIR="$FOUND"
            echo "Found WireGuardKitGo at: $TARGET_DIR" >> "$LOG_FILE"
            break
        fi
    fi
done

echo "Target Dir: $TARGET_DIR" >> "$LOG_FILE"

if [ -z "$TARGET_DIR" ] || [ ! -d "$TARGET_DIR" ]; then
    echo "error: [WireGuardGoBridge] WireGuardKitGo directory not found." | tee -a "$LOG_FILE"
    exit 1
fi

cd "$TARGET_DIR"
echo "Current Directory: $(pwd)" >> "$LOG_FILE"

# WireGuardKitGo's Makefile only maps GOOS for iphoneos, not iphonesimulator.
# Without this, simulator builds use host GOOS and fail at link time with:
#   Undefined symbol: _darwin_arm_init_mach_exception_handler
if ! grep -q 'GOOS_iphonesimulator' Makefile; then
    sed -i '' '/^GOOS_iphoneos := ios/a\
GOOS_iphonesimulator := ios
' Makefile
    echo "Patched Makefile: added GOOS_iphonesimulator := ios" >> "$LOG_FILE"
fi

# Run make
if [ "$ACTION" == "build" ] || [ -z "$ACTION" ]; then
    echo "Running make..." >> "$LOG_FILE"
    /usr/bin/make >> "$LOG_FILE" 2>&1
    EXIT_CODE=$?
else
    echo "Running make $ACTION..." >> "$LOG_FILE"
    /usr/bin/make "$ACTION" >> "$LOG_FILE" 2>&1
    EXIT_CODE=$?
fi

echo "Make finished with exit code: $EXIT_CODE" >> "$LOG_FILE"
exit $EXIT_CODE
