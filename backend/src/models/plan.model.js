import mongoose from 'mongoose';

/**
 * Plan schema. Index 0-5 matches PremiumPlan enum in the app.
 * 0: platinumWeekly, 1: platinumMonthly, 2: platinumYearly,
 * 3: platinumPlusWeekly, 4: platinumPlusMonthly, 5: platinumPlusYearly
 */
const planSchema = new mongoose.Schema(
  {
    index: { type: Number, required: true, unique: true },
    name: { type: String, required: true },
    tier: { type: String, required: true, enum: ['platinum', 'platinumPlus'] },
    interval: { type: String, required: true, enum: ['weekly', 'monthly', 'yearly'] },
    durationDays: { type: Number, required: true },
    amount: { type: Number, required: true }, // in paise (smallest unit)
    currency: { type: String, default: 'INR' },
    devices: { type: Number, required: true },
    displayName: { type: String, required: true },
    intervalLabel: { type: String, required: true },
    period: { type: String, required: true },
    price: { type: String, required: true },
    description: { type: String, default: '' },
    badge: { type: String, default: null },
  },
  { timestamps: true }
);

export default mongoose.model('Plan', planSchema);
