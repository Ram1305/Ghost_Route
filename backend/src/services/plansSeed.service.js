import Plan from '../models/plan.model.js';
import { defaultPlans } from '../config/defaultPlans.js';

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
}

/** Seed plans when the collection is empty (first deploy / fresh database). */
export async function ensurePlansSeeded() {
  const count = await Plan.countDocuments();
  if (count > 0) return;

  await upsertDefaultPlans();
  console.log(`Seeded ${defaultPlans.length} default plans`);
}
