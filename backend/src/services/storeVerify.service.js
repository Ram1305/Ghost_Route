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

/** paymentState: 0 pending, 1 received, 2 free trial, 3 deferred upgrade/downgrade */
function isGooglePaymentAccepted(paymentState) {
  return paymentState === 1 || paymentState === 2;
}

/**
 * Call Play Developer API for a subscription purchase token.
 * Exported for RTDN webhook re-verification.
 */
export async function verifyGoogleSubscription({ packageName, productId, purchaseToken }) {
  const keyPath = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_PATH;
  if (!keyPath || !fs.existsSync(keyPath)) {
    return { valid: false, skipped: true, error: 'Google Play service account not configured' };
  }
  if (!purchaseToken) {
    return { valid: false, error: 'Missing Google Play purchase token' };
  }
  const google = await loadGoogleApis();
  const auth = new google.auth.GoogleAuth({
    keyFile: keyPath,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  const androidPublisher = google.androidpublisher({ version: 'v3', auth });
  const res = await androidPublisher.purchases.subscriptions.get({
    packageName: packageName || process.env.GOOGLE_PLAY_PACKAGE_NAME || 'com.yencode.ghostroute',
    subscriptionId: productId,
    token: purchaseToken,
  });
  const data = res.data || {};
  const paymentState = data.paymentState;
  const expiresAtMs = Number(data.expiryTimeMillis);
  const expiresAt = !isNaN(expiresAtMs) ? new Date(expiresAtMs) : null;
  const now = new Date();

  if (expiresAt && expiresAt < now) {
    return {
      valid: false,
      data,
      expiresAt,
      orderId: data.orderId || null,
      error: 'Subscription has expired',
      isExpired: true,
    };
  }

  if (!isGooglePaymentAccepted(paymentState)) {
    return {
      valid: false,
      data,
      expiresAt,
      orderId: data.orderId || null,
      error: `Google Play payment not accepted (paymentState=${paymentState})`,
    };
  }

  return {
    valid: true,
    data,
    expiresAt,
    orderId: data.orderId || null,
  };
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
        // Merge latest_receipt_info and receipt.in_app so a brand-new purchase
        // that Apple hasn't yet promoted into latest_receipt_info is still found.
        const latestInfo = Array.isArray(result.data.latest_receipt_info)
          ? result.data.latest_receipt_info
          : [];
        const inAppInfo = Array.isArray(result.data.receipt?.in_app)
          ? result.data.receipt.in_app
          : [];

        // Deduplicate by transaction_id; latest_receipt_info takes priority.
        const seen = new Set();
        const allTransactions = [];
        for (const t of [...latestInfo, ...inAppInfo]) {
          const id = t.transaction_id || t.original_transaction_id;
          if (id && seen.has(id)) continue;
          if (id) seen.add(id);
          allTransactions.push(t);
        }

        const normalizedProductId = String(productId || '').trim();
        console.log(
          `IAP: receipt has ${latestInfo.length} latest_receipt_info + ${inAppInfo.length} in_app = ` +
          `${allTransactions.length} total transactions. Looking for productId="${normalizedProductId}". ` +
          `Found productIds: [${[...new Set(allTransactions.map(t => t.product_id).filter(Boolean))].join(', ')}]`,
        );

        if (allTransactions.length === 0) {
          return { valid: false, planIndex, error: 'No transaction history found in receipt' };
        }

        const matchingTransactions = allTransactions.filter(
          t => String(t.product_id || '').trim() === normalizedProductId,
        );

        if (matchingTransactions.length === 0) {
          return {
            valid: false,
            planIndex,
            error: `Product ID "${normalizedProductId}" not found in receipt. ` +
              `Receipt contains: [${[...new Set(allTransactions.map(t => t.product_id).filter(Boolean))].join(', ')}]`,
          };
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
          originalTransactionId: latest.original_transaction_id || latest.transaction_id,
        };
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
    const keyPath = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_PATH;
    if (purchaseToken && keyPath) {
      try {
        const result = await verifyGoogleSubscription({
          packageName,
          productId,
          purchaseToken,
        });
        if (result.valid) {
          if (!result.expiresAt || isNaN(result.expiresAt.getTime())) {
            return { valid: false, planIndex, error: 'Invalid expiration date from Google Play' };
          }
          return {
            valid: true,
            planIndex,
            platform,
            expiresAt: result.expiresAt,
            // Play orderId for invoices/history; purchaseToken is the durable Android identity
            transactionId: result.orderId || null,
            purchaseToken,
          };
        }
        return { ...result, planIndex, platform };
      } catch (e) {
        return { valid: false, planIndex, error: e.message };
      }
    }
    if (!STRICT && productId && purchaseToken) {
      console.warn('IAP: Google verify skipped; dev accept token present');
      return { valid: true, planIndex, platform, purchaseToken, devBypass: true };
    }
    return { valid: false, planIndex, error: 'Google Play verification not configured' };
  }

  return { valid: false, planIndex, error: 'Invalid platform' };
}
