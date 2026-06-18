# App Store Connect — Privacy, Metadata & Review (Ghost Route)

Use this when updating App Store Connect before resubmission. Do not commit secrets here.

## Guideline 3.1.2(c) — Terms of Use (EULA) + subscription legal info

**In-app (fixed in binary):** Premium screen and plan picker show Privacy Policy and Terms of Use links. Subscription title, length, and price are displayed on plan tiles.

**App Store Connect — App Description:** Use the **full** copy-paste block in **[APP_STORE_METADATA.md](APP_STORE_METADATA.md) section 3** (starts with `PAID SUBSCRIPTION REQUIRED FOR VPN ACCESS`). Do not use a shortened description — Apple requires explicit **purchase required** language in the first lines.

**Privacy Policy URL (App Information field):** https://ghostroutes.netlify.app/

---

## Guideline 5.1.2(i) — App Privacy (no tracking)

1. App Privacy → **Does your app collect data?** → Yes  
2. **Do you or third-party partners use data for tracking?** → **No**  
3. For **Email Address** (and other types you declare):
   - Purposes: **App Functionality**, **Account Management** only
   - **Not** “Used for tracking”
4. Declare only what the app collects: email, username, optional phone, purchase/subscription status.

**Review Notes (paste):**

> This app does not track users across apps or websites. App Privacy labels have been corrected. No App Tracking Transparency prompt is shown because we do not collect data used for tracking.

---

## Guideline 2.3.2 — Accurate metadata (paid disclosure)

**Rejection (June 2026):** Description and screenshots referenced VPN features without clearly labelling them as requiring purchase.

**Fix:** Use the full copy-paste blocks in **[APP_STORE_METADATA.md](APP_STORE_METADATA.md)** — subtitle, promotional text, description, screenshot overlays, and App Review reply.

Minimum requirements:
1. **Description** — First line must state **PAID SUBSCRIPTION REQUIRED** and that VPN is **not** included with the free download; separate free vs paid sections.
2. **Subtitle** — Must not imply free VPN (use `VPN Access · Subscription`).
3. **Screenshots** — Any image showing connect/secured/servers/benefits needs a visible **“Purchase required”** overlay; re-upload **iPad** set.
4. **Promotional text** — Lead with paid purchase requirement.
5. **Keywords** — No `free vpn`; see APP_STORE_METADATA.md section 4.
6. **IAP localizations** — All 6 products + group names; see STORE_PRODUCTS.md.

Use **App Store** only in iOS metadata (no Google Play references).

---

## Guideline 2.1 — VPN questions (reply in App Store Connect)

**What user information is the app collecting using VPN?**

The VPN tunnel (OpenVPN via Network Extension) routes device traffic to the selected VPN server. Ghost Route’s backend does not receive browsing history, DNS queries, or packet contents from the VPN session. On-device only, the app stores connection statistics (bytes/packets, connection stage) locally for the UI. Account data (email, username, optional phone, subscription status) is collected separately for login and premium access.

**For what purposes?**

- VPN: encrypted connection to user-selected server location.  
- Account: authentication, subscription entitlement, password reset (email OTP), transactional emails.  
- Network test: optional call to ip-api.com to show approximate location/IP (not VPN logging).

**Shared with third parties? Where stored?**

- **Our backend** (ghostroute.octosofttechnologies.in): account/subscription in MongoDB; OTPs in memory; email via mail provider.  
- **VPN servers:** OpenVPN configs from our managed API (`GET /api/servers`); tunnel traffic handled by those endpoints.  
- **ip-api.com:** geolocation for network test only.  
- **Firebase:** Remote Config only (analytics disabled).  
- **Apple:** in-app subscription billing and receipt verification.  
- We do not sell personal data to data brokers and do not perform cross-app tracking.

---

## Guideline 2.1(b) — IAP purchase errors

Before resubmitting, confirm on production server:

```env
APPLE_SHARED_SECRET=<App-Specific Shared Secret from App Store Connect>
APPLE_BUNDLE_ID=com.yencode.ghostroute
IAP_STRICT_VERIFY=true
```

Also confirm:
- Paid Apps Agreement is active (App Store Connect → Business)
- All 6 subscription product IDs submitted with this app version (see STORE_PRODUCTS.md)
- Sandbox purchase tested: Premium → Choose plan → purchase while logged in → no verification error

---

## Account deletion demo (Guideline 5.1.1)

Record on a **physical device** and attach URL in App Review Information → Notes:

1. Login: `review@yencodetech.com` / `YencodeReview2026!`  
2. Profile (Account) → **Delete account** → confirm  
3. Show account removed and returned to logged-out state  

Path: Splash → Login → Home → Profile → Delete account.

---

## In-App Purchase testing (Guideline 3.1.1)

- Product IDs: see [STORE_PRODUCTS.md](STORE_PRODUCTS.md)  
- Sandbox Apple ID required for purchase flows  
- Demo account above has premium **without** purchase for VPN/feature testing  
- **Restore purchases** on Premium screen and Profile  
- Attach screen recording showing Premium legal links + successful sandbox purchase in Review Notes
