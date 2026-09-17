# Ghost Route

Secure VPN app with account management, subscriptions, and Yencode-managed server infrastructure.

## Backend `.env`

Copy `backend/.env.example` to `backend/.env` and fill in the values below. Do not commit `backend/.env`.

```bash
cp backend/.env.example backend/.env
```

### Required

| Variable | What to put |
| --- | --- |
| `PORT` | API port. Example uses `2626`. |
| `MONGODB_URI` | MongoDB connection string. Local: `mongodb://localhost:27017/ghostroute`. Atlas: `mongodb+srv://USER:PASS@cluster/...` |
| `JWT_SECRET` | Long random secret. Login/register fail if this is empty. Generate with `openssl rand -hex 32`. |
| `JWT_EXPIRES_IN` | Token lifetime. Default `30d`. |
| `ADMIN_EMAILS` | Comma-separated emails that become admin on next login/register. Example: `you@example.com`. |

### Email (OTP, welcome, invoice)

Use either `SMTP_*` (as in `.env.example`) or `EMAIL_*` (both work).

| Variable | What to put |
| --- | --- |
| `SMTP_HOST` / `EMAIL_HOST` | SMTP host, e.g. `smtp.gmail.com` |
| `SMTP_PORT` / `EMAIL_PORT` | Usually `587` |
| `SMTP_USER` / `EMAIL_USER` | SMTP username / mailbox |
| `SMTP_PASS` / `EMAIL_PASS` | SMTP password. For Gmail, use an [App Password](https://support.google.com/accounts/answer/185833), not your normal password. |
| `SMTP_FROM` / `MAIL_FROM` | From address. Defaults to the SMTP user if omitted. |
| `EMAIL_SECURE` / `SMTP_SECURE` | `true` only for port 465. Use `false` for 587. |

### Push notifications (admin new-subscription alerts)

Set these in `backend/.env` **and** on the live server. Do not use a local JSON file path.

| Variable | What to put |
| --- | --- |
| `FIREBASE_PROJECT_ID` | `project_id` from the Firebase service-account JSON, e.g. `ghostroute-7d157` |
| `FIREBASE_CLIENT_EMAIL` | `client_email` from that JSON |
| `FIREBASE_PRIVATE_KEY` | `private_key` from that JSON, in double quotes, keeping the `\n` characters |

Example:

```env
FIREBASE_PROJECT_ID=ghostroute-7d157
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@ghostroute-7d157.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

### In-app purchases (required for production iOS/Android)

| Variable | What to put |
| --- | --- |
| `APPLE_SHARED_SECRET` | App-specific shared secret from App Store Connect. |
| `APPLE_BUNDLE_ID` | `com.yencode.ghostroute` |
| `GOOGLE_PLAY_PACKAGE_NAME` | `com.yencode.ghostroute` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Full Play Console service-account JSON as one line (preferred on live). |
| `IAP_STRICT_VERIFY` | Keep `true` in production. Set `false` only for local dev without store credentials. |

### Optional / unused by the mobile app

| Variable | What to put |
| --- | --- |
| `RAZORPAY_KEY_ID` | Razorpay key. Only needed if you use the legacy payment APIs. |
| `RAZORPAY_KEY_SECRET` | Razorpay secret. |

### Typical values still missing on live

Copy the same `.env` keys onto the production host. Firebase push uses env vars only (no file). Until Play credentials exist, set `IAP_STRICT_VERIFY=false` only for local Android IAP testing.
