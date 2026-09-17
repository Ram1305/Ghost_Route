import fs from 'fs';

let messagingInstance = null;
let initTried = false;

/** Lazily initializes firebase-admin from FIREBASE_SERVICE_ACCOUNT_PATH.
 * Returns null (and warns once) when not configured, mirroring how
 * email/Google-Play verification degrade gracefully in this codebase. */
async function getMessaging() {
  if (messagingInstance) return messagingInstance;
  if (initTried) return null;
  initTried = true;

  const keyPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  if (!keyPath || !fs.existsSync(keyPath)) {
    console.warn(
      'Push notifications not configured: set FIREBASE_SERVICE_ACCOUNT_PATH in .env',
    );
    return null;
  }
  const admin = (await import('firebase-admin')).default;
  const serviceAccount = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
  const app = admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  messagingInstance = admin.messaging(app);
  return messagingInstance;
}

/**
 * Sends a push notification to one or more FCM device tokens. Invalid/
 * unregistered tokens are reported back so callers can prune them; never
 * throws for individual send failures.
 */
export async function sendPushToTokens(tokens, { title, body, data } = {}) {
  const list = (tokens || []).filter(Boolean);
  if (list.length === 0) return { successCount: 0, invalidTokens: [] };

  const messaging = await getMessaging();
  if (!messaging) return { successCount: 0, invalidTokens: [] };

  const response = await messaging.sendEachForMulticast({
    tokens: list,
    notification: { title, body },
    data: data ? Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])) : undefined,
  });

  const invalidTokens = [];
  response.responses.forEach((r, i) => {
    if (!r.success && [
      'messaging/invalid-registration-token',
      'messaging/registration-token-not-registered',
    ].includes(r.error?.code)) {
      invalidTokens.push(list[i]);
    }
  });

  return { successCount: response.successCount, invalidTokens };
}
