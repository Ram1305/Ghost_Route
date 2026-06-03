# Store subscription products (Ghost Route)

Create these **auto-renewable subscriptions** in App Store Connect and Google Play Console.  
Bundle ID / package: `com.yencode.ghostroute`

| Plan index | Product ID | Tier | Interval |
|------------|------------|------|----------|
| 0 | `com.yencode.ghostroute.platinum.weekly` | Platinum | Weekly |
| 1 | `com.yencode.ghostroute.platinum.monthly` | Platinum | Monthly |
| 2 | `com.yencode.ghostroute.platinum.yearly` | Platinum | Yearly |
| 3 | `com.yencode.ghostroute.platinumplus.weekly` | Platinum+ | Weekly |
| 4 | `com.yencode.ghostroute.platinumplus.monthly` | Platinum+ | Monthly |
| 5 | `com.yencode.ghostroute.platinumplus.yearly` | Platinum+ | Yearly |

## App Store Connect

1. Subscriptions → create two **subscription groups** (e.g. `platinum`, `platinum_plus`).  
2. Add three durations per group with IDs above.  
3. Submit subscriptions with the app version.  
4. Optional: add `ios/Runner/Products.storekit` for local StoreKit testing.

## Google Play Console

1. Monetize → Subscriptions → create matching product IDs.  
2. Link service account for server verification (see backend `.env.example`).  
3. Add license testers for internal testing.

## Backend environment

```env
GOOGLE_PLAY_PACKAGE_NAME=com.yencode.ghostroute
GOOGLE_PLAY_SERVICE_ACCOUNT_PATH=/path/to/play-service-account.json
APPLE_SHARED_SECRET=75ba09e1cebb4b60b56c59f3aac53eff
APPLE_BUNDLE_ID=com.yencode.ghostroute
IAP_STRICT_VERIFY=true
```

Set `IAP_STRICT_VERIFY=false` only for local dev without store credentials (not for production).
