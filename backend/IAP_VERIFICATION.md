# Backend IAP verification (production)

Before App Store resubmission, confirm these environment variables are set on the production server (`ghostroute.octosofttechnologies.in`):

```env
APPLE_SHARED_SECRET=<App-Specific Shared Secret from App Store Connect → App Information>
APPLE_BUNDLE_ID=com.yencode.ghostroute
IAP_STRICT_VERIFY=true
```

## Quick checks

1. **Health:** `GET https://ghostroute.octosofttechnologies.in/api/health` → `{"status":"ok",...}`
2. **Paid Apps Agreement:** Active in App Store Connect → Business
3. **Products:** All 6 subscription IDs submitted with the app version (see `app_store_connect/STORE_PRODUCTS.md`)
4. **Sandbox test:** On device with sandbox Apple ID:
   - Login → Premium → Choose plan → complete purchase
   - Expect success dialog, not "Subscription verification failed"
5. **Logs:** If verification fails, check server logs for `Apple receipt verification not configured` or `Apple status <code>`

## Xcode StoreKit config vs real sandbox

The default **Runner** scheme must **not** attach `Products.storekit` when testing end-to-end IAP verification on a physical device.

| Setup | Use for | Receipt verify |
|-------|---------|----------------|
| Xcode Run **without** StoreKit Configuration | Real App Store Connect sandbox on device | Works |
| Xcode Run **with** `Products.storekit` attached | Local UI / product loading only | Always fails (21002) |

**Real sandbox test steps:**

1. Xcode → Product → Scheme → Edit Scheme → Run → confirm **StoreKit Configuration** is **None**
2. On device: Settings → App Store → Sandbox Account (sandbox Apple ID)
3. Delete and reinstall the app for a fresh receipt
4. Log in → buy a plan → Profile should show purchase history

To use `ios/Runner/Products.storekit` for local UI testing only, attach it temporarily in the scheme; do not expect server verification to succeed.

## Shared Secret location

App Store Connect → Your App → General → App Information → App-Specific Shared Secret

Do not commit the secret to git. Set it only in the server `.env` file.
