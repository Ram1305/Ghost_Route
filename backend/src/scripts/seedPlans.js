import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import connectDB from '../config/db.js';
import Plan from '../models/plan.model.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
// Load .env from backend folder (or project root)
dotenv.config({ path: join(__dirname, '../../.env') });
dotenv.config({ path: join(__dirname, '../../../.env') });

const defaultPlans = [
  {
    index: 0,
    name: 'platinumWeekly',
    tier: 'platinum',
    interval: 'weekly',
    durationDays: 7,
    amount: 499,
    currency: 'INR',
    devices: 3,
    displayName: 'Platinum Weekly (3 devices)',
    intervalLabel: 'Weekly',
    period: 'per week',
    price: '₹4.99',
    description: 'Full speed · 50+ locations',
    badge: null,
  },
  {
    index: 1,
    name: 'platinumMonthly',
    tier: 'platinum',
    interval: 'monthly',
    durationDays: 30,
    amount: 999,
    currency: 'INR',
    devices: 5,
    displayName: 'Platinum Monthly (5 devices)',
    intervalLabel: 'Monthly',
    period: 'per month',
    price: '₹9.99',
    description: 'Best for individuals & families',
    badge: null,
  },
  {
    index: 2,
    name: 'platinumYearly',
    tier: 'platinum',
    interval: 'yearly',
    durationDays: 365,
    amount: 3999,
    currency: 'INR',
    devices: 5,
    displayName: 'Platinum Yearly (5 devices)',
    intervalLabel: 'Yearly',
    period: 'per year',
    price: '₹39.99',
    description: 'Save 67% · Full access',
    badge: 'Best value',
  },
  {
    index: 3,
    name: 'platinumPlusWeekly',
    tier: 'platinumPlus',
    interval: 'weekly',
    durationDays: 7,
    amount: 699,
    currency: 'INR',
    devices: 5,
    displayName: 'Platinum+ Weekly (5 devices)',
    intervalLabel: 'Weekly',
    period: 'per week',
    price: '₹6.99',
    description: 'Priority support · 80+ locations',
    badge: null,
  },
  {
    index: 4,
    name: 'platinumPlusMonthly',
    tier: 'platinumPlus',
    interval: 'monthly',
    durationDays: 30,
    amount: 1499,
    currency: 'INR',
    devices: 10,
    displayName: 'Platinum+ Monthly (10 devices)',
    intervalLabel: 'Monthly',
    period: 'per month',
    price: '₹14.99',
    description: 'For power users & small teams',
    badge: null,
  },
  {
    index: 5,
    name: 'platinumPlusYearly',
    tier: 'platinumPlus',
    interval: 'yearly',
    durationDays: 365,
    amount: 5999,
    currency: 'INR',
    devices: 10,
    displayName: 'Platinum+ Yearly (10 devices)',
    intervalLabel: 'Yearly',
    period: 'per year',
    price: '₹59.99',
    description: 'Save 71% · Family pack',
    badge: 'Best value',
  },
];

async function seedPlans() {
  try {
    await connectDB();
    for (const plan of defaultPlans) {
      await Plan.findOneAndUpdate(
        { index: plan.index },
        { $set: plan },
        { upsert: true, new: true }
      );
      console.log(`Plan ${plan.index} (${plan.name}) upserted`);
    }
    console.log('Plans seeded successfully');
  } catch (err) {
    console.error('Seed error:', err);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log('MongoDB disconnected');
  }
}

seedPlans();
