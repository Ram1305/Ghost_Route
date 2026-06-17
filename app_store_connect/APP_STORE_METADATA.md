# App Store Connect — Metadata (Guideline 2.3.2)

Apple rejected build 1.0 (6) because the **description** and **screenshots** reference VPN features without clearly stating that a **paid subscription** is required to use them.

Update these fields in App Store Connect **before** resubmitting. No new binary is required for a metadata-only fix — but you must upload corrected text and screenshots, then reply to the rejection in App Review.

---

## 1. Subtitle (30 characters max)

Paste exactly (27 characters):

```
VPN · Subscription Required
```

**Do not use** subtitles that imply free VPN access, e.g.:
- ~~Secure private VPN~~
- ~~Fast VPN worldwide~~
- ~~Unlimited VPN protection~~

---

## 2. Promotional Text (170 characters max)

Paste exactly:

```
Free to download. VPN connection requires a Platinum or Platinum+ subscription (weekly, monthly, or yearly) via the App Store. Browse servers free; subscribe to connect.
```

---

## 3. Description (paste entire block)

```
SUBSCRIPTION REQUIRED FOR VPN ACCESS

Ghost Route is free to download. Browsing server locations, network tests, and viewing plans are free. Connecting to the VPN and using encrypted tunnel access requires an active Platinum or Platinum+ auto-renewable subscription (weekly, monthly, or yearly), purchased through the App Store. No account is required to purchase.

WHAT IS FREE
• Browse VPN server locations
• Network speed test
• View subscription plans and pricing
• Optional account creation

REQUIRES PAID SUBSCRIPTION
• VPN connection and encrypted browsing
• Full-speed, unlimited bandwidth
• 50+ countries / 200+ servers (Platinum) or 80+ locations (Platinum+)
• Multiple devices (3–10, depending on plan)
• Ad-free experience
• Priority support (Platinum+)

SUBSCRIPTION PLANS (auto-renewable)
Platinum: Weekly $4.99 · Monthly $9.99 · Yearly $39.99
Platinum+: Weekly $6.99 · Monthly $14.99 · Yearly $59.99

Payment is charged to your App Store account. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in Settings → Apple ID → Subscriptions.

Ghost Route routes your traffic through encrypted OpenVPN servers you select. Choose a location, connect with one tap, and browse with added privacy on public Wi‑Fi and mobile networks.

Terms of Use (EULA): https://ghostroutetermsofuse.netlify.app/
Privacy Policy: https://ghostroutes.netlify.app/
```

---

## 4. Screenshots — required changes

Apple specifically flagged **screenshot** copy. Every screenshot that shows VPN connection, the power orb, “connected/secured” state, server lists used for connecting, or premium benefits must include a visible paid-content label.

### Overlay text (add in Figma, Preview, or your design tool)

Use a consistent banner or badge on affected screenshots:

| Screenshot shows | Add this overlay |
|------------------|------------------|
| Home screen / power orb / “Connect” | **Subscription required to connect** |
| Connected / Secured / VPN active state | **Active subscription required** |
| Server list for connecting | **Subscribe to connect to servers** |
| Premium benefits (speed, locations, etc.) | **Included with Platinum subscription** |
| Plan / pricing screen | *(no overlay needed — already shows purchase)* |

### Recommended screenshot order (iPhone + iPad)

1. **Premium / Plans screen** — shows pricing (no overlay needed)
2. Home with overlay: *Subscription required to connect*
3. Server browser with overlay: *Browse free · Subscribe to connect*
4. Connected state with overlay: *Requires active subscription*
5. Account / optional sign-in screen

Re-upload **both iPhone and iPad** screenshot sets if you have iPad-specific assets (review was on iPad Air 11-inch).

### What to remove from screenshots

- Headlines like “Unlimited VPN”, “Browse freely”, “Stay protected” **without** a subscription disclaimer
- Any text that suggests VPN is included with the free download

---

## 5. App Review reply (paste in App Store Connect)

```
Hello App Review,

Thank you for the feedback on Guideline 2.3.2.

We have updated our App Store metadata:

1. Description — Added a “SUBSCRIPTION REQUIRED FOR VPN ACCESS” disclosure at the top, with separate “WHAT IS FREE” and “REQUIRES PAID SUBSCRIPTION” sections.
2. Subtitle — Updated to “VPN · Subscription Required”.
3. Promotional text — States that VPN connection requires a Platinum or Platinum+ subscription.
4. Screenshots — Added visible “Subscription required” labels on all screenshots that depict VPN connection or premium features.

In the app, tapping Connect without an active subscription opens the Premium screen with plan pricing before any purchase. Demo account review@yencodetech.com / YencodeReview2026! has an active subscription for testing VPN connection.

Please let us know if anything else is needed.
```

---

## 6. Pre-resubmit checklist

- [ ] Subtitle = `VPN · Subscription Required`
- [ ] Promotional text updated (section 2)
- [ ] Full description replaced (section 3)
- [ ] All VPN-related screenshots have subscription overlay text
- [ ] iPad screenshot set updated (review device was iPad Air 11-inch)
- [ ] Reply to rejection message in App Store Connect (section 5)
- [ ] Submit for review (metadata changes do not require a new build)

---

## 7. Fields that are usually fine (quick audit)

| Field | Guidance |
|-------|----------|
| **Name** | Ghost Route — OK |
| **Keywords** | Avoid “free vpn”; OK: `vpn, privacy, secure, subscription` |
| **Support URL** | Must load |
| **Privacy Policy URL** | https://ghostroutes.netlify.app/ |
| **In-app purchase names** | Already show Platinum / Platinum+ with prices |
