import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import connectDB from '../config/db.js';
import { resetAndSeedDefaultPlans } from '../services/plansSeed.service.js';
import { defaultPlans } from '../config/defaultPlans.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, '../../.env') });
dotenv.config({ path: join(__dirname, '../../../.env') });

async function seedPlans() {
  try {
    await connectDB();
    await resetAndSeedDefaultPlans();
    for (const plan of defaultPlans) {
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
