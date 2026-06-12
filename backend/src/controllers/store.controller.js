import User from '../models/user.model.js';
import Plan from '../models/plan.model.js';
import * as emailService from '../services/email.service.js';
import { verifyStorePurchase } from '../services/storeVerify.service.js';

async function activatePlanForUser(user, planIndex, { transactionId, productId, platform, expiresAt }) {
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

  user.subscriptionHistory.push({
    plan: planIndex,
    date: now,
    transactionId: transactionId || null,
    productId: productId || null,
    platform: platform || null,
    amount: planDoc.price,
    currency: planDoc.currency || 'USD',
  });
  user.activePlan = planIndex;
  user.subscriptionExpiresAt = finalExpiresAt;
  user.subscriptionPlatform = platform;
  user.subscriptionProductId = productId;
  if (platform === 'ios' && transactionId) {
    user.appleOriginalTransactionId = transactionId;
  }
  if (platform === 'android' && transactionId) {
    user.googlePurchaseToken = transactionId;
  }
  await user.save();

  try {
    await emailService.sendInvoiceEmail(user.email, {
      orderId: transactionId || null,
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

    await activatePlanForUser(user, verification.planIndex, {
      transactionId: transactionId || purchaseToken || verification.transactionId,
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

/** Google Play Real-time developer notifications (Pub/Sub push). */
export async function googleWebhook(req, res) {
  try {
    console.log('Google webhook received');
    res.status(200).send();
  } catch (err) {
    console.error('Google webhook error:', err);
    res.status(500).send();
  }
}
