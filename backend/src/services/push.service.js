let messagingInstance = null;
let initTried = false;

function unescapePrivateKey(value) {
  return String(value || '')
    .trim()
    .replace(/^["']|["']$/g, '')
    .replace(/\\n/g, '\n');
}

/** Reads Firebase Admin credentials from .env so local and live servers
 * use the same config — no machine-specific JSON file path. */
function getFirebaseCredentials() {
  const projectId = (process.env.FIREBASE_PROJECT_ID || '').trim();
  const clientEmail = (process.env.FIREBASE_CLIENT_EMAIL || '').trim();
  const privateKey = unescapePrivateKey(process.env.FIREBASE_PRIVATE_KEY);
  if (projectId && clientEmail && privateKey.includes('BEGIN PRIVATE KEY')) {
    return { projectId, clientEmail, privateKey };
  }

  const rawJson = (process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '').trim();
  if (rawJson) {
    try {
      const parsed = JSON.parse(rawJson);
      if (parsed.project_id && parsed.client_email && parsed.private_key) {
        return {
          projectId: parsed.project_id,
          clientEmail: parsed.client_email,
          privateKey: unescapePrivateKey(parsed.private_key),
        };
      }
    } catch (err) {
      console.warn('FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON:', err.message);
    }
  }

  return null;
}

/** Lazily initializes firebase-admin from .env.
 * Returns null (and warns once) when not configured, mirroring how
 * email/Google-Play verification degrade gracefully in this codebase. */
async function getMessaging() {
  if (messagingInstance) return messagingInstance;
  if (initTried) return null;
  initTried = true;

  const creds = getFirebaseCredentials();
  if (!creds) {
    console.warn(
      'Push notifications not configured: set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY in .env',
    );
    return null;
  }
  const admin = (await import('firebase-admin')).default;
  const app = admin.initializeApp({
    credential: admin.credential.cert({
      projectId: creds.projectId,
      clientEmail: creds.clientEmail,
      privateKey: creds.privateKey,
    }),
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
  if (list.length === 0) return { successCount: 0, failureCount: 0, invalidTokens: [], errors: [] };

  const messaging = await getMessaging();
  if (!messaging) {
    return {
      successCount: 0,
      failureCount: list.length,
      invalidTokens: [],
      errors: [
        'Push notifications not configured: set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY in .env',
      ],
    };
  }

  const dataPayload = data
    ? Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)]))
    : undefined;

  const response = await messaging.sendEachForMulticast({
    tokens: list,
    notification: { title, body },
    data: dataPayload,
    android: {
      priority: 'high',
      notification: { sound: 'default' },
    },
    // iOS will not reliably show a banner without an APNs alert/sound payload.
    apns: {
      headers: {
        'apns-priority': '10',
        'apns-push-type': 'alert',
      },
      payload: {
        aps: {
          alert: { title, body },
          sound: 'default',
          badge: 1,
        },
      },
    },
  });

  const invalidTokens = [];
  const errors = [];
  response.responses.forEach((r, i) => {
    if (r.success) return;
    const code = r.error?.code || 'unknown';
    const message = r.error?.message || 'send failed';
    errors.push(`${code}: ${message}`);
    if ([
      'messaging/invalid-registration-token',
      'messaging/registration-token-not-registered',
    ].includes(code)) {
      invalidTokens.push(list[i]);
    }
  });

  return {
    successCount: response.successCount,
    failureCount: response.failureCount,
    invalidTokens,
    errors,
  };
}
