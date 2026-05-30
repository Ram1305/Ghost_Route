# Apple Developer setup for `com.yencode.ghostroute`

The Xcode project and entitlements in this repo already use the new bundle ID. Complete these steps in [Apple Developer](https://developer.apple.com/account) before release builds or App Store submission.

## 1. App Group

1. **Identifiers** → **App Groups** → **+**
2. Identifier: `group.com.yencode.ghostroute`
3. Register the group.

## 2. Main app identifier

1. **Identifiers** → **App IDs** → **+** → **App**
2. Description: Ghost Route
3. Bundle ID (explicit): `com.yencode.ghostroute`
4. Enable capabilities used by the app (match the old `com.yencodetech.vpn` app):
   - **App Groups** → select `group.com.yencode.ghostroute`
   - **Network Extensions** (Packet Tunnel) if required for VPN
   - Any other capabilities from the previous app (Push, Sign in with Apple, etc.)
5. Register.

## 3. VPN extension identifier

1. **Identifiers** → **App IDs** → **+** → **App**
2. Bundle ID: `com.yencode.ghostroute.VPNExtension`
3. Enable **App Groups** → `group.com.yencode.ghostroute`
4. Enable **Network Extensions** (Packet Tunnel).
5. Register.

## 4. Provisioning profiles

Create (or let Xcode manage) profiles for:

| Target        | Bundle ID                              |
|---------------|----------------------------------------|
| Runner        | `com.yencode.ghostroute`               |
| VPNExtension  | `com.yencode.ghostroute.VPNExtension`  |

Use Development and App Store distribution as needed.

## 5. Xcode signing

1. Open `ios/Runner.xcworkspace`.
2. Select **Runner** and **VPNExtension** targets → **Signing & Capabilities**.
3. Choose your team; enable **Automatically manage signing** or assign the new profiles.
4. Confirm **App Groups** shows `group.com.yencode.ghostroute` on both targets.

## 6. App Store Connect

Bundle ID cannot be changed on an existing app. Create a **new app** with bundle ID `com.yencode.ghostroute`, or keep the old listing on `com.yencodetech.vpn`.

## Code alignment (already in repo)

- `ios/Runner/Runner.entitlements` → `group.com.yencode.ghostroute`
- `ios/VPNExtension/VPNExtension.entitlements` → same
- `lib/services/vpn_engine.dart` → same group + `com.yencode.ghostroute.VPNExtension`

Test VPN on a **physical device** after profiles are in place (Simulator does not run the packet-tunnel extension reliably).
