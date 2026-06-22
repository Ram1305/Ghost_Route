import Plan from '../models/plan.model.js';
import User from '../models/user.model.js';
import { defaultPlans } from '../config/defaultPlans.js';
import { migrateLegacyPlanIndex } from '../config/plans.js';

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

/** Remap user activePlan / history from old 2-5 indices to new 0-1. */
export async function migrateUserPlanIndices() {
  const users = await User.find({
    $or: [
      { activePlan: { $gte: 2 } },
      { 'subscriptionHistory.plan': { $gte: 2 } },
    ],
  });

  for (const user of users) {
    let changed = false;
    if (user.activePlan != null && user.activePlan >= 2) {
      user.activePlan = migrateLegacyPlanIndex(user.activePlan);
      changed = true;
    }
    for (const entry of user.subscriptionHistory || []) {
      if (entry.plan != null && entry.plan >= 2) {
        entry.plan = migrateLegacyPlanIndex(entry.plan);
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
