import fs from 'fs';
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import connectDB from '../config/db.js';
import Server from '../models/server.model.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, '../../.env') });
dotenv.config({ path: join(__dirname, '../../../.env') });

function readOvpnBase64(relativePath) {
  const fullPath = join(__dirname, '../../../', relativePath);
  const content = fs.readFileSync(fullPath, 'utf8');
  return Buffer.from(content, 'utf8').toString('base64');
}

const defaultServers = [
  {
    hostname: 'jp-yencode-01',
    ip: '0.0.0.0',
    ping: '45',
    speed: 100000000,
    countryLong: 'Japan',
    countryShort: 'JP',
    numVpnSessions: 12,
    openVPNConfigDataBase64: readOvpnBase64('assets/vpn/japan.ovpn'),
    premiumOnly: false,
    sortOrder: 0,
  },
  {
    hostname: 'th-yencode-01',
    ip: '0.0.0.0',
    ping: '62',
    speed: 80000000,
    countryLong: 'Thailand',
    countryShort: 'TH',
    numVpnSessions: 8,
    openVPNConfigDataBase64: readOvpnBase64('assets/vpn/thailand.ovpn'),
    premiumOnly: false,
    sortOrder: 1,
  },
];

async function seedServers() {
  try {
    await connectDB();
    for (const server of defaultServers) {
      await Server.findOneAndUpdate(
        { hostname: server.hostname },
        { $set: server },
        { upsert: true, new: true }
      );
      console.log(`Server ${server.hostname} (${server.countryLong}) upserted`);
    }
    console.log('VPN servers seeded successfully');
  } catch (err) {
    console.error('Seed servers error:', err);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
  }
}

seedServers();
