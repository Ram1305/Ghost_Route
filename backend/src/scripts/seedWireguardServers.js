import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import connectDB from '../config/db.js';
import { upsertWireguardPremiumServers } from '../services/wireguardServersSeed.service.js';
import { wireguardPremiumServers } from '../config/wireguardPremiumServers.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, '../../.env') });
dotenv.config({ path: join(__dirname, '../../../.env') });

async function seedWireguardServers() {
  try {
    await connectDB();
    await upsertWireguardPremiumServers();
    console.log(`WireGuard premium servers synced (${wireguardPremiumServers.length})`);
  } catch (err) {
    console.error('Seed WireGuard servers error:', err);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
  }
}

seedWireguardServers();
