import Plan from '../models/plan.model.js';
import User from '../models/user.model.js';
import { defaultPlans } from '../config/defaultPlans.js';
import { normalizePlanIndex } from '../config/plans.js';

/** Upsert all default plans into MongoDB (by index). */
export async function upsertDefaultPlans() {
  for (const plan of defaultPlans) {
    await Plan.findOneAndUpdate(
      { index: plan.index },
      { $set: plan },
      { upsert: true, new: true }
    );
  }
}

/** Remove every plan document, then insert the current defaultPlans (USD). */
export async function resetAndSeedDefaultPlans() {
  const deleted = await Plan.deleteMany({});
  console.log(`Removed ${deleted.deletedCount} plan(s) from database`);
  await upsertDefaultPlans();
  await migrateUserPlanIndices();
}

/** Clamp user activePlan / history to valid indices (0 = monthly, 1 = yearly). */
export async function migrateUserPlanIndices() {
  const users = await User.find({
    $or: [
      { activePlan: { $nin: [0, 1, null] } },
      { 'subscriptionHistory.plan': { $nin: [0, 1, null] } },
    ],
  });

  for (const user of users) {
    let changed = false;
    if (user.activePlan != null && user.activePlan !== 0 && user.activePlan !== 1) {
      user.activePlan = normalizePlanIndex(user.activePlan);
      changed = true;
    }
    for (const entry of user.subscriptionHistory || []) {
      if (entry.plan != null && entry.plan !== 0 && entry.plan !== 1) {
        entry.plan = normalizePlanIndex(entry.plan);
        changed = true;
      }
    }
    if (changed) {
      await user.save();
    }
  }
}

/** Seed plans when the collection is empty (first deploy / fresh database). */
export async function ensurePlansSeeded() {
  const count = await Plan.countDocuments();
  if (count > 0) return;

  await upsertDefaultPlans();
  console.log(`Seeded ${defaultPlans.length} default plans`);
}
