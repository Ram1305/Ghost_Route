# App Store Connect — Metadata (Guideline 2.3.2)

Apple rejected build **1.0 (7)** because the description references subscriptions without clearly stating that a **paid in-app purchase** is required. Review device: **iPad Air 11-inch (M3)**.

Update these fields in App Store Connect **before** resubmitting. Metadata-only changes do not require a new build — but you must **Save** each field, upload corrected screenshots, reply in App Review, then **Submit for Review**.

In-app banners use: **Paid in-app purchase required to connect**

---

## 1. Subtitle (30 characters max)

```
VPN · Purchase Required
```

(24 characters)

---

## 2. Promotional text

```
PAID IN-APP PURCHASE REQUIRED to connect to VPN. Ghost Route is free to download only — browsing servers and viewing plans are free. Paid in-app purchase required to connect. Platinum or Platinum+ subscription (weekly, monthly, or yearly) via the App Store.
```

---

## 3. Description (paste entire block)

```
PAID IN-APP PURCHASE REQUIRED TO CONNECT

Ghost Route is free to download. VPN connection and encrypted tunnel access are NOT included with the free download. A separate paid in-app purchase is required to connect. Platinum or Platinum+ auto-renewable subscriptions (weekly, monthly, or yearly) are available through the App Store.

WHAT IS FREE
• Browse available VPN server locations
• Incognito in-app browser (private session — no history saved after you close)
• Network speed test
• View subscription plans and pricing
• Optional account creation

REQUIRES PAID IN-APP PURCHASE
• VPN connection and encrypted browsing
• Military-grade encryption to keep your data safe
• High-speed servers across multiple countries
• One-tap connect for instant protection
• Bypass geo-restrictions and access content worldwide
• Secure public Wi-Fi connections
• Zero-log policy (as described in our Privacy Policy)

Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Payment is charged to your Apple ID account. Manage or cancel in Settings → Apple ID → Subscriptions.

Privacy Policy: https://ghostroutes.netlify.app/
Terms of Use: https://ghostroutetermsofuse.netlify.app/
```

---

## 4. Keywords (do not use)

Avoid: `free`, `free vpn`, `unlimited free`

Suggested: `vpn,secure,privacy,encryption,proxy,wifi,subscription,ghost route`

---

## 5. iPad screenshots

Re-upload the full **iPad Air 11-inch** set. Screenshots must show the in-app banner:

**Paid in-app purchase required to connect**

Recommended captures:
1. **Premium** — plan picker with prices (no overlay needed)
2. **Home** — gold banner + helper text **“Paid subscription required before connecting”** (not “Tap the shield to connect”)
3. **Servers** — “Browse free · Paid in-app purchase to connect” banner

---

## 6. App Review reply (Resolution Center)

```
We updated our App Store metadata for Guideline 2.3.2:

1. Description — First line now states "PAID IN-APP PURCHASE REQUIRED TO CONNECT" and clarifies VPN is not included with the free download.

2. Subtitle and Promotional Text — Updated to state paid in-app purchase is required for VPN access.

3. iPad screenshots — Re-uploaded showing in-app "Paid in-app purchase required to connect" on VPN screens.

The app is free to download for browsing servers and viewing plans only. VPN connection requires a paid Platinum or Platinum+ subscription purchased through the App Store.

Demo account (premium for VPN testing): yencodedeverloper@gmail.com / YencodeReview2026!
```

---

## 7. IAP product IDs

| Product ID |
|------------|
| `com.yencode.ghostroute.platinum.weekly` |
| `com.yencode.ghostroute.platinum.monthly` |
| `com.yencode.ghostroute.platinum.yearly` |
| `com.yencode.ghostroute.platinumplus.weekly` |
| `com.yencode.ghostroute.platinumplus.monthly` |
| `com.yencode.ghostroute.platinumplus.yearly` |

IAP display names should include paid/purchase language, e.g. “Platinum Weekly — paid subscription required for VPN”.
