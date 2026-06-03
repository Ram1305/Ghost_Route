# App Store Connect — Privacy, Metadata & Review (Ghost Route)

Use this when updating App Store Connect before resubmission. Do not commit secrets here.

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

## Guideline 2.3.2 — App description (paid disclosure)

Add near the top of the **Description**:

> Ghost Route is free to download. Full VPN access requires an active Platinum or Platinum+ subscription (weekly, monthly, or yearly), purchased through the App Store or Google Play. Premium features, server tiers, and device limits vary by plan.

Audit subtitle, screenshots, and promotional text for “premium included” without “subscription required.”

---

## Guideline 2.1 — VPN questions (reply in App Store Connect)

**What user information is the app collecting using VPN?**

The VPN tunnel (OpenVPN via Network Extension) routes device traffic to the selected VPN server. Ghost Route’s backend does not receive browsing history, DNS queries, or packet contents from the VPN session. Account data (email, username, optional phone, subscription status) is collected separately for login and premium access.

**For what purposes?**

- VPN: encrypted connection to user-selected server location.  
- Account: authentication, subscription entitlement, password reset (email OTP), transactional emails.  
- Network test: optional call to ip-api.com to show approximate location/IP (not VPN logging).

**Shared with third parties? Where stored?**

- **Our backend** (ghostroute.octosofttechnologies.in): account/subscription in MongoDB; OTPs in memory; email via mail provider.  
- **VPN servers:** OpenVPN configs from our managed API (`GET /api/servers`); tunnel traffic handled by those endpoints.  
- **ip-api.com:** geolocation for network test only.  
- **Firebase:** Remote Config only (analytics disabled).  
- **Apple / Google:** in-app subscription billing.  
- We do not sell personal data to data brokers and do not perform cross-app tracking.

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
- Sandbox Apple ID + Play license testers required for purchase flows  
- Demo account above has premium **without** purchase for VPN/feature testing  
- **Restore purchases** on Premium screen and Profile  
