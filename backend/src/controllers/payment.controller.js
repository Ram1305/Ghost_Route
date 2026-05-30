import crypto from 'crypto';
import { razorpay, razorpayConfig } from '../config/razorpay.js';
import User from '../models/user.model.js';
import Plan from '../models/plan.model.js';
import * as emailService from '../services/email.service.js';

/**
 * Create a Razorpay order. Amount in paise (e.g. 50000 = ₹500).
 * Returns orderId and keyId so the client can open Checkout.
 */
export async function createOrder(req, res) {
  try {
    if (!razorpay) {
      return res.status(503).json({ error: 'Razorpay is not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET in .env' });
    }

    const { amount, currency = 'INR', receipt, notes } = req.body;
    const amountPaise = Number(amount);

    if (!amountPaise || amountPaise < 100) {
      return res.status(400).json({ error: 'Amount is required and must be at least 100 paise (₹1)' });
    }

    const options = {
      amount: amountPaise,
      currency: currency.toUpperCase(),
      receipt: receipt || `rcpt_${Date.now()}`,
      ...(notes && { notes }),
    };

    const order = await razorpay.orders.create(options);

    res.status(201).json({
      orderId: order.id,
      amount: order.amount,
      currency: order.currency,
      keyId: razorpayConfig.keyId,
    });
  } catch (err) {
    console.error('Razorpay create order error:', err);
    res.status(500).json({ error: err.message || 'Failed to create order' });
  }
}

/**
 * Verify payment signature after successful payment on client.
 * Body: { razorpay_order_id, razorpay_payment_id, razorpay_signature }
 */
export async function verifyPayment(req, res) {
  try {
    const { keySecret } = razorpayConfig;
    if (!keySecret) {
      return res.status(503).json({ error: 'Razorpay is not configured' });
    }

    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({
        error: 'Missing razorpay_order_id, razorpay_payment_id or razorpay_signature',
      });
    }

    const body = `${razorpay_order_id}|${razorpay_payment_id}`;
    const expected = crypto
      .createHmac('sha256', keySecret)
      .update(body)
      .digest('hex');

    const verified = expected === razorpay_signature;

    if (!verified) {
      return res.status(400).json({ error: 'Payment verification failed', verified: false });
    }

    res.json({
      verified: true,
      orderId: razorpay_order_id,
      paymentId: razorpay_payment_id,
    });
  } catch (err) {
    console.error('Razorpay verify error:', err);
    res.status(500).json({ error: err.message || 'Verification failed' });
  }
}

/**
 * Get all plans (for app to display and use for payment). Sorted by index.
 */
export async function getPlans(req, res) {
  try {
    const plans = await Plan.find().sort({ index: 1 }).lean();
    if (!plans.length) {
      return res.status(503).json({
        error: 'No plans configured. Run: npm run seed:plans',
      });
    }
    res.json(plans);
  } catch (err) {
    console.error('Get plans error:', err);
    res.status(500).json({ error: err.message || 'Failed to get plans' });
  }
}

/**
 * Return the Razorpay key ID for the frontend (no secret).
 */
export function getKeyId(req, res) {
  const { keyId } = razorpayConfig;
  if (!keyId) {
    return res.status(503).json({ error: 'Razorpay is not configured' });
  }
  res.json({ keyId });
}

/**
 * Activate subscription for a user after successful payment.
 * Body: { userId, plan } (plan = PremiumPlan index 0-5). Optional: orderId, paymentId.
 */
export async function activateSubscription(req, res) {
  try {
    const { userId, plan, orderId, paymentId } = req.body;
    if (userId == null || plan == null) {
      return res.status(400).json({ error: 'userId and plan are required' });
    }
    const planIndex = Number(plan);
    const planDoc = await Plan.findOne({ index: planIndex });
    if (!planDoc) {
      return res.status(400).json({ error: 'Invalid plan index. Run: npm run seed:plans' });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const now = new Date();
    const expiresAt = new Date(now);
    expiresAt.setDate(expiresAt.getDate() + planDoc.durationDays);

    user.subscriptionHistory.push({ plan: planIndex, date: now });
    user.activePlan = planIndex;
    user.subscriptionExpiresAt = expiresAt;
    await user.save();

    const invoiceInfo = {
      name: planDoc.displayName,
      amount: planDoc.price,
      currency: planDoc.currency,
    };
    try {
      await emailService.sendInvoiceEmail(user.email, {
        orderId: orderId || null,
        paymentId: paymentId || null,
        planName: invoiceInfo.name,
        amount: invoiceInfo.amount,
        currency: invoiceInfo.currency,
        date: now,
      });
    } catch (e) {
      console.error('Invoice email failed:', e);
    }

    const updated = await User.findById(userId).select('-password').lean();
    res.status(200).json({
      activePlan: updated.activePlan,
      subscriptionExpiresAt: updated.subscriptionExpiresAt,
      user: updated,
    });
  } catch (err) {
    console.error('Activate subscription error:', err);
    res.status(500).json({ error: err.message || 'Failed to activate subscription' });
  }
}
