import dns from 'dns';
import dotenv from 'dotenv';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';
import mongoose from 'mongoose';
import { sendPushToTokens } from '../services/push.service.js';
import User from '../models/user.model.js';
import connectDB from '../config/db.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, '../../.env') });
dns.setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);

const ADMIN_EMAIL = (process.argv[2] || 'yencodedeveloper@gmail.com').trim().toLowerCase();

function previewToken(token) {
  if (!token) return '(empty)';
  if (token.length <= 12) return token;
  return `${token.slice(0, 6)}...${token.slice(-4)} (len=${token.length})`;
}

async function main() {
  const keyPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  console.log('[test-push] FIREBASE_SERVICE_ACCOUNT_PATH=', keyPath || '(unset)');
  if (!keyPath || !fs.existsSync(keyPath)) {
    console.error(
      '[test-push] Cannot send: drop a Firebase service-account JSON in backend/secrets/ and set FIREBASE_SERVICE_ACCOUNT_PATH in backend/.env',
    );
  }

  await connectDB();
  const admin = await User.findOne({
    $or: [{ email: ADMIN_EMAIL }, { role: 'admin', email: ADMIN_EMAIL }],
  }).select('email username role pushEnabled fcmTokens');

  const fallbackAdmins = admin
    ? [admin]
    : await User.find({ role: 'admin' }).select('email username role pushEnabled fcmTokens');

  if (fallbackAdmins.length === 0) {
    console.error('[test-push] No admin user found for', ADMIN_EMAIL);
    await mongoose.disconnect();
    process.exit(1);
  }

  for (const user of fallbackAdmins) {
    const tokens = (user.fcmTokens || []).filter(Boolean);
    console.log('[test-push] admin=', {
      email: user.email,
      username: user.username,
      role: user.role,
      pushEnabled: user.pushEnabled,
      tokenCount: tokens.length,
      tokens: tokens.map(previewToken),
    });

    if (tokens.length === 0) {
      console.error('[test-push] Admin has no FCM tokens stored. Open the iOS app while logged in as admin first.');
      continue;
    }

    const result = await sendPushToTokens(tokens, {
      title: 'Ghost Route test',
      body: 'Test notification to iOS admin',
      data: { type: 'test_push' },
    });
    console.log('[test-push] send result=', result);
  }

  await mongoose.disconnect();
}

main().catch(async (err) => {
  console.error('[test-push] failed:', err);
  try {
    await mongoose.disconnect();
  } catch (_) {}
  process.exit(1);
});
