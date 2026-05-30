import User from '../models/user.model.js';

/**
 * Find users whose subscriptionExpiresAt is in the past and activePlan is set,
 * and set activePlan to null (subscription expired). subscriptionExpiresAt is
 * left as-is so the app can show "Expired" and "Renew" state.
 */
export async function expireSubscriptions() {
  const now = new Date();
  const result = await User.updateMany(
    {
      subscriptionExpiresAt: { $lt: now },
      activePlan: { $ne: null },
    },
    { $set: { activePlan: null } }
  );
  if (result.modifiedCount > 0) {
    console.log(`[expireSubscriptions] Expired ${result.modifiedCount} subscription(s)`);
  }
  return result;
}
