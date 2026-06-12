import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import connectDB from '../config/db.js';
import User from '../models/user.model.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, '../../.env') });
dotenv.config({ path: join(__dirname, '../../../.env') });

const REVIEW_EMAIL = process.env.REVIEW_ACCOUNT_EMAIL || 'review@yencodetech.com';
const REVIEW_PASSWORD = process.env.REVIEW_ACCOUNT_PASSWORD || 'YencodeReview2026!';
const REVIEW_USERNAME = process.env.REVIEW_ACCOUNT_USERNAME || 'App Review';

export async function seedReviewAccount({ connect = false, disconnect = false } = {}) {
  try {
    if (connect) {
      await connectDB();
    }

    const subscriptionData = [{
      plan: 2,
      date: new Date(),
      amount: '$39.99',
      currency: 'USD',
      platform: 'ios',
      transactionId: 'GHOST-REV-2026',
      productId: 'com.yencode.ghostroute.platinum.yearly'
    }];

    const existing = await User.findOne({ email: REVIEW_EMAIL });
    if (existing) {
      existing.username = REVIEW_USERNAME;
      existing.password = REVIEW_PASSWORD;
      existing.activePlan = 2;
      existing.subscriptionExpiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
      existing.subscriptionHistory = subscriptionData;
      await existing.save();
      console.log(`Review account updated: ${REVIEW_EMAIL}`);
    } else {
      await User.create({
        email: REVIEW_EMAIL,
        password: REVIEW_PASSWORD,
        username: REVIEW_USERNAME,
        phone: '',
        activePlan: 2,
        subscriptionExpiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
        subscriptionHistory: subscriptionData,
      });
      console.log(`Review account created: ${REVIEW_EMAIL}`);
    }

    console.log('\n--- App Store Connect: App Review Information ---');
    console.log(`Email: ${REVIEW_EMAIL}`);
    console.log(`Password: ${REVIEW_PASSWORD}`);
    console.log('Path: Splash → Premium → "Already have account? Login"');
    console.log('Health check: GET /api/health');
    console.log('------------------------------------------------\n');
  } catch (err) {
    console.error('Seed review account error:', err);
    if (connect) {
      process.exit(1);
    } else {
      throw err;
    }
  } finally {
    if (disconnect) {
      await mongoose.disconnect();
    }
  }
}

// Run immediately if this file was executed directly
const isDirectRun = process.argv[1] && (
  process.argv[1].endsWith('seedReviewAccount.js') || 
  process.argv[1].endsWith('seedReviewAccount')
);
if (isDirectRun) {
  seedReviewAccount({ connect: true, disconnect: true });
}
