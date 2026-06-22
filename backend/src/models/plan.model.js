import mongoose from 'mongoose';

/**
 * Plan schema. Index 0-1 matches PremiumPlan enum in the app.
 * 0: platinumMonthly, 1: platinumYearly
 */
const planSchema = new mongoose.Schema(
  {
    index: { type: Number, required: true, unique: true },
    name: { type: String, required: true },
    tier: { type: String, required: true, enum: ['platinum'] },
    interval: { type: String, required: true, enum: ['monthly', 'yearly'] },
    durationDays: { type: Number, required: true },
    amount: { type: Number, required: true }, // in cents (USD smallest unit)
    currency: { type: String, default: 'USD' },
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
