import Razorpay from 'razorpay';

/**
 * Razorpay config – keys loaded from .env
 * Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET in your .env
 */
const keyId = process.env.RAZORPAY_KEY_ID;
const keySecret = process.env.RAZORPAY_KEY_SECRET;

if (!keyId || !keySecret) {
  console.warn(
    'Razorpay: RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET missing in .env. Payment APIs will fail.'
  );
}

export const razorpayConfig = {
  keyId,
  keySecret,
};

/** Razorpay instance for server-side API calls (create order, fetch payment, etc.) */
export const razorpay = keyId && keySecret
  ? new Razorpay({ key_id: keyId, key_secret: keySecret })
  : null;

export default razorpay;
