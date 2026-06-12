import fs from 'fs';
import { PLAN_INDEX_BY_PRODUCT_ID } from '../config/iapProducts.js';

/** Loaded on demand so the server can start if googleapis is not installed yet. */
async function loadGoogleApis() {
  try {
    const mod = await import('googleapis');
    return mod.google;
  } catch (e) {
    if (e?.code === 'ERR_MODULE_NOT_FOUND') {
      throw new Error(
        'Missing package "googleapis". On the server run: cd backend && npm install',
      );
    }
    throw e;
  }
}

const STRICT = process.env.IAP_STRICT_VERIFY !== 'false';

export function resolvePlanIndex(productId) {
  const idx = PLAN_INDEX_BY_PRODUCT_ID[String(productId || '').trim()];
  return idx === undefined ? null : idx;
}

function isJwsReceipt(receiptData) {
  return String(receiptData || '').trim().startsWith('eyJ');
}

function logReceiptMeta(receiptData) {
  const trimmed = String(receiptData || '').trim();
  console.log(
    `IAP: receipt meta length=${trimmed.length} isJws=${isJwsReceipt(trimmed)}`,
  );
}

async function verifyAppleReceipt(receiptData, sharedSecret) {
  const trimmed = String(receiptData || '').trim();
  if (!trimmed) {
    return { valid: false, error: 'Missing iOS receipt data' };
  }
  logReceiptMeta(trimmed);
  if (isJwsReceipt(trimmed)) {
    return {
      valid: false,
      error: 'Invalid iOS receipt format (JWS); app receipt required',
    };
  }
  const body = {
    'receipt-data': trimmed,
    password: sharedSecret,
    'exclude-old-transactions': true,
  };
  const urls = [
    'https://buy.itunes.apple.com/verifyReceipt',
    'https://sandbox.itunes.apple.com/verifyReceipt',
  ];
  let lastError = null;
  for (const url of urls) {
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      const data = await res.json();
      if (data.status === 0) {
        const environment = url.includes('sandbox') ? 'sandbox' : 'production';
        console.log(`IAP: Apple receipt verified (${environment})`);
        return { valid: true, environment, data };
      }
      if (data.status === 21007 && url.includes('buy.itunes')) {
        console.log('IAP: Apple receipt is sandbox; retrying with sandbox endpoint');
        continue;
      }
      lastError = `Apple status ${data.status}`;
    } catch (e) {
      lastError = e.message;
    }
  }
  return { valid: false, error: lastError || 'Apple verification failed' };
}

async function verifyGoogleSubscription({ packageName, productId, purchaseToken }) {
  const keyPath = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_PATH;
  if (!keyPath || !fs.existsSync(keyPath)) {
    return { valid: false, skipped: true, error: 'Google Play service account not configured' };
  }
  const google = await loadGoogleApis();
  const auth = new google.auth.GoogleAuth({
    keyFile: keyPath,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  const androidPublisher = google.androidpublisher({ version: 'v3', auth });
  const res = await androidPublisher.purchases.subscriptions.get({
    packageName,
    subscriptionId: productId,
    token: purchaseToken,
  });
  const paymentState = res.data.paymentState;
  const valid = paymentState === 1 || paymentState === 2;
  return { valid, data: res.data };
}

/**
 * Verify store purchase. When IAP_STRICT_VERIFY=false and store credentials are missing,
 * accepts known product IDs only (development — not for production).
 */
export async function verifyStorePurchase({
  platform,
  productId,
  purchaseToken,
  receiptData,
}) {
  const planIndex = resolvePlanIndex(productId);
  if (planIndex === null) {
    return { valid: false, planIndex: null, error: 'Unknown product ID' };
  }

  if (platform === 'ios') {
    const secret = process.env.APPLE_SHARED_SECRET;
    const trimmedReceipt = String(receiptData || '').trim();
    if (!trimmedReceipt) {
      return { valid: false, planIndex, error: 'Missing iOS receipt data' };
    }
    if (secret && trimmedReceipt) {
      const result = await verifyAppleReceipt(trimmedReceipt, secret);
      if (result.valid && result.data) {
        const receiptInfo = result.data.latest_receipt_info || (result.data.receipt && result.data.receipt.in_app);
        if (receiptInfo && Array.isArray(receiptInfo) && receiptInfo.length > 0) {
          const matchingTransactions = receiptInfo.filter(t => t.product_id === productId);
          if (matchingTransactions.length === 0) {
            return { valid: false, planIndex, error: 'Product ID not found in receipt' };
          }
          matchingTransactions.sort((a, b) => Number(b.expires_date_ms) - Number(a.expires_date_ms));
          const latest = matchingTransactions[0];
          const expiresAtMs = Number(latest.expires_date_ms);
          if (isNaN(expiresAtMs)) {
            return { valid: false, planIndex, error: 'Invalid expiration date in receipt' };
          }
          const expiresAt = new Date(expiresAtMs);
          const now = new Date();
          if (expiresAt < now) {
            return { valid: false, planIndex, error: 'Subscription has expired', isExpired: true };
          }
          return {
            valid: true,
            planIndex,
            platform,
            expiresAt,
            transactionId: latest.transaction_id || latest.original_transaction_id,
          };
        } else {
          return { valid: false, planIndex, error: 'No transaction history found in receipt' };
        }
      }
      return { ...result, planIndex, platform };
    }
    if (!STRICT && productId) {
      console.warn('IAP: Apple verify skipped (missing secret/receipt); dev accept productId only');
      return { valid: true, planIndex, platform, devBypass: true };
    }
    return { valid: false, planIndex, error: 'Apple receipt verification not configured' };
  }

  if (platform === 'android') {
    const packageName = process.env.GOOGLE_PLAY_PACKAGE_NAME || 'com.yencode.ghostroute';
    if (purchaseToken && process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_PATH) {
      try {
        const result = await verifyGoogleSubscription({
          packageName,
          productId,
          purchaseToken,
        });
        if (result.valid && result.data) {
          const expiresAtMs = Number(result.data.expiryTimeMillis);
          if (isNaN(expiresAtMs)) {
            return { valid: false, planIndex, error: 'Invalid expiration date from Google Play' };
          }
          const expiresAt = new Date(expiresAtMs);
          const now = new Date();
          if (expiresAt < now) {
            return { valid: false, planIndex, error: 'Subscription has expired', isExpired: true };
          }
          return {
            valid: true,
            planIndex,
            platform,
            expiresAt,
          };
        }
        return { ...result, planIndex, platform };
      } catch (e) {
        return { valid: false, planIndex, error: e.message };
      }
    }
    if (!STRICT && productId && purchaseToken) {
      console.warn('IAP: Google verify skipped; dev accept token present');
      return { valid: true, planIndex, platform, devBypass: true };
    }
    return { valid: false, planIndex, error: 'Google Play verification not configured' };
  }

  return { valid: false, planIndex, error: 'Invalid platform' };
}
