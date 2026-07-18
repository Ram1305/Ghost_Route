import User from '../models/user.model.js';
import Plan from '../models/plan.model.js';
import * as emailService from '../services/email.service.js';
import {
  verifyStorePurchase,
  verifyGoogleSubscription,
  resolvePlanIndex,
} from '../services/storeVerify.service.js';

/** Google Play RTDN subscriptionNotification.notificationType values */
const GOOGLE_NOTIF = {
  SUBSCRIPTION_RECOVERED: 1,
  SUBSCRIPTION_RENEWED: 2,
  SUBSCRIPTION_CANCELED: 3,
  SUBSCRIPTION_PURCHASED: 4,
  SUBSCRIPTION_ON_HOLD: 5,
  SUBSCRIPTION_IN_GRACE_PERIOD: 6,
  SUBSCRIPTION_RESTARTED: 7,
  SUBSCRIPTION_PRICE_CHANGE_CONFIRMED: 8,
  SUBSCRIPTION_DEFERRED: 9,
  SUBSCRIPTION_PAUSED: 10,
  SUBSCRIPTION_PAUSE_SCHEDULE_CHANGED: 11,
  SUBSCRIPTION_REVOKED: 12,
  SUBSCRIPTION_EXPIRED: 13,
};

async function activatePlanForUser(
  user,
  planIndex,
  { transactionId, originalTransactionId, purchaseToken, productId, platform, expiresAt },
) {
  const planDoc = await Plan.findOne({ index: planIndex });
  if (!planDoc) {
    throw new Error('Invalid plan index');
  }
  const now = new Date();
  let finalExpiresAt = expiresAt;
  if (!finalExpiresAt || isNaN(new Date(finalExpiresAt).getTime())) {
    finalExpiresAt = new Date(now);
    finalExpiresAt.setDate(finalExpiresAt.getDate() + planDoc.durationDays);
  }

  const txId = transactionId ? String(transactionId).trim() : null;
  const origTxId = originalTransactionId ? String(originalTransactionId).trim() : null;
  const googleToken = purchaseToken ? String(purchaseToken).trim() : null;

  const matchesKnownTransaction = (id) => {
    if (!id) return false;
    const trimmed = String(id).trim();
    return (
      user.subscriptionHistory.some(
        (entry) => entry.transactionId && String(entry.transactionId).trim() === trimmed,
      ) ||
      (user.appleOriginalTransactionId &&
        String(user.appleOriginalTransactionId).trim() === trimmed) ||
      (user.googlePurchaseToken && String(user.googlePurchaseToken).trim() === trimmed)
    );
  };

  const refreshActiveSubscription = async () => {
    user.activePlan = planIndex;
    const currentExpiry = user.subscriptionExpiresAt
      ? new Date(user.subscriptionExpiresAt)
      : null;
    if (!currentExpiry || new Date(finalExpiresAt) > currentExpiry) {
      user.subscriptionExpiresAt = finalExpiresAt;
    }
    user.subscriptionPlatform = platform;
    user.subscriptionProductId = productId;
    if (platform === 'ios') {
      const appleId = origTxId || txId;
      if (appleId) user.appleOriginalTransactionId = appleId;
    }
    // Durable Android identity is the purchase token, not orderId
    if (platform === 'android' && googleToken) {
      user.googlePurchaseToken = googleToken;
    }
    await user.save();
    return user;
  };

  const knownByToken =
    platform === 'android' && googleToken && matchesKnownTransaction(googleToken);
  if (
    (txId && matchesKnownTransaction(txId)) ||
    (origTxId && matchesKnownTransaction(origTxId)) ||
    knownByToken
  ) {
    return refreshActiveSubscription();
  }

  // Restore: same active product — refresh expiry only, no duplicate history row.
  if (
    user.activePlan === planIndex &&
    user.subscriptionProductId === productId &&
    user.subscriptionPlatform === platform &&
    user.subscriptionExpiresAt &&
    new Date(user.subscriptionExpiresAt) > now
  ) {
    return refreshActiveSubscription();
  }

  user.subscriptionHistory.push({
    plan: planIndex,
    date: now,
    // Prefer Play orderId / Apple transactionId for invoices; fall back to token
    transactionId: txId || googleToken || null,
    productId: productId || null,
    platform: platform || null,
    amount: planDoc.price,
    currency: planDoc.currency || 'USD',
  });
  user.activePlan = planIndex;
  user.subscriptionExpiresAt = finalExpiresAt;
  user.subscriptionPlatform = platform;
  user.subscriptionProductId = productId;
  if (platform === 'ios') {
    const appleId = origTxId || txId;
    if (appleId) user.appleOriginalTransactionId = appleId;
  }
  if (platform === 'android' && googleToken) {
    user.googlePurchaseToken = googleToken;
  }
  await user.save();

  try {
    await emailService.sendInvoiceEmail(user.email, {
      orderId: txId || googleToken || null,
      paymentId: productId,
      planName: planDoc.displayName,
      amount: planDoc.price,
      currency: planDoc.currency,
      date: now,
    });
  } catch (e) {
    console.error('Invoice email failed:', e);
  }

  return user;
}

/**
 * POST /api/payments/store/verify
 * Body: { userId, platform, productId, purchaseToken?, receiptData?, transactionId? }
 */
export async function verifyAndActivateStorePurchase(req, res) {
  try {
    const { userId, platform, productId, purchaseToken, receiptData, transactionId } = req.body;
    if (!userId || !platform || !productId) {
      return res.status(400).json({ error: 'userId, platform, and productId are required' });
    }

    const verification = await verifyStorePurchase({
      platform,
      productId,
      purchaseToken,
      receiptData,
    });

    if (!verification.valid) {
      return res.status(400).json({
        error: verification.error || 'Purchase verification failed',
        verified: false,
      });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const androidToken =
      platform === 'android'
        ? verification.purchaseToken || purchaseToken || null
        : null;

    await activatePlanForUser(user, verification.planIndex, {
      // History/invoice: Play orderId or client transactionId; never overwrite token with orderId
      transactionId: verification.transactionId || transactionId || null,
      originalTransactionId: verification.originalTransactionId,
      purchaseToken: androidToken,
      productId,
      platform,
      expiresAt: verification.expiresAt,
    });

    const updated = await User.findById(userId).select('-password').lean();
    res.status(200).json({
      verified: true,
      activePlan: updated.activePlan,
      subscriptionExpiresAt: updated.subscriptionExpiresAt,
      user: updated,
    });
  } catch (err) {
    console.error('Store verify error:', err);
    res.status(500).json({ error: err.message || 'Verification failed' });
  }
}

/** Apple App Store Server Notifications V2 (configure URL in App Store Connect). */
export async function appleWebhook(req, res) {
  try {
    const body = req.body;
    console.log('Apple webhook received:', body?.notificationType || 'unknown');
    res.status(200).send();
  } catch (err) {
    console.error('Apple webhook error:', err);
    res.status(500).send();
  }
}

function decodePubSubData(body) {
  const b64 = body?.message?.data;
  if (!b64) return null;
  try {
    const json = Buffer.from(b64, 'base64').toString('utf8');
    return JSON.parse(json);
  } catch (e) {
    console.error('Google webhook: failed to decode Pub/Sub data', e.message);
    return null;
  }
}

async function revokeAndroidSubscription(user) {
  user.activePlan = null;
  user.subscriptionExpiresAt = new Date(0);
  await user.save();
  console.log(`Google RTDN: revoked/expired plan for user ${user._id}`);
}

async function extendAndroidSubscription(user, productId, purchaseToken) {
  const packageName = process.env.GOOGLE_PLAY_PACKAGE_NAME || 'com.yencode.ghostroute';
  const result = await verifyGoogleSubscription({
    packageName,
    productId,
    purchaseToken,
  });
  if (!result.valid || !result.expiresAt) {
    console.warn(
      `Google RTDN: re-verify failed for token=${purchaseToken?.slice?.(0, 12)}…: ${result.error}`,
    );
    return;
  }
  const planIndex = resolvePlanIndex(productId);
  if (planIndex === null) {
    console.warn(`Google RTDN: unknown productId ${productId}`);
    return;
  }
  await activatePlanForUser(user, planIndex, {
    transactionId: result.orderId || null,
    purchaseToken,
    productId,
    platform: 'android',
    expiresAt: result.expiresAt,
  });
  console.log(
    `Google RTDN: extended user ${user._id} until ${result.expiresAt.toISOString()}`,
  );
}

/**
 * Google Play Real-time developer notifications (Pub/Sub push).
 * Configure topic + push endpoint: POST /api/payments/webhooks/google
 */
export async function googleWebhook(req, res) {
  // Always ACK quickly so Pub/Sub does not retry-storm; log failures after.
  try {
    const payload = decodePubSubData(req.body);
    if (!payload) {
      console.log('Google webhook: no/empty Pub/Sub payload');
      return res.status(200).send();
    }

    const sub = payload.subscriptionNotification;
    if (!sub) {
      // testNotification, oneTimeProductNotification, voidedPurchaseNotification, etc.
      console.log(
        'Google webhook: non-subscription notification',
        Object.keys(payload).filter((k) => k.endsWith('Notification')),
      );
      return res.status(200).send();
    }

    const notificationType = Number(sub.notificationType);
    const purchaseToken = sub.purchaseToken ? String(sub.purchaseToken).trim() : null;
    const productId = sub.subscriptionId ? String(sub.subscriptionId).trim() : null;

    console.log(
      `Google webhook: type=${notificationType} productId=${productId} token=${purchaseToken?.slice(0, 12)}…`,
    );

    if (!purchaseToken) {
      return res.status(200).send();
    }

    const user = await User.findOne({ googlePurchaseToken: purchaseToken });
    if (!user) {
      console.warn('Google RTDN: no user for purchase token');
      return res.status(200).send();
    }

    const renewTypes = new Set([
      GOOGLE_NOTIF.SUBSCRIPTION_RECOVERED,
      GOOGLE_NOTIF.SUBSCRIPTION_RENEWED,
      GOOGLE_NOTIF.SUBSCRIPTION_PURCHASED,
      GOOGLE_NOTIF.SUBSCRIPTION_RESTARTED,
      GOOGLE_NOTIF.SUBSCRIPTION_IN_GRACE_PERIOD,
    ]);

    if (renewTypes.has(notificationType)) {
      const pid = productId || user.subscriptionProductId;
      if (pid) {
        await extendAndroidSubscription(user, pid, purchaseToken);
      }
      return res.status(200).send();
    }

    if (notificationType === GOOGLE_NOTIF.SUBSCRIPTION_CANCELED) {
      // Keep access until current expiry; do not wipe plan early.
      console.log(`Google RTDN: canceled (access until expiry) user ${user._id}`);
      return res.status(200).send();
    }

    if (
      notificationType === GOOGLE_NOTIF.SUBSCRIPTION_REVOKED ||
      notificationType === GOOGLE_NOTIF.SUBSCRIPTION_EXPIRED
    ) {
      await revokeAndroidSubscription(user);
      return res.status(200).send();
    }

    // ON_HOLD / PAUSED / etc. — leave as-is; renew/revoke paths handle outcomes
    console.log(`Google RTDN: ignored notification type ${notificationType}`);
    return res.status(200).send();
  } catch (err) {
    console.error('Google webhook error:', err);
    // Still 200 so Pub/Sub does not hammer retries for handler bugs
    return res.status(200).send();
  }
}
