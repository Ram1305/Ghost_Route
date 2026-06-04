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

## Shared Secret location

App Store Connect → Your App → General → App Information → App-Specific Shared Secret

Do not commit the secret to git. Set it only in the server `.env` file.
