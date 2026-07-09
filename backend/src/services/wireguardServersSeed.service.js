import WireguardServer from '../models/wireguardServer.model.js';
import { wireguardPremiumServers } from '../config/wireguardPremiumServers.js';

/** Upsert WireGuard servers into MongoDB (by id). */
export async function upsertWireguardPremiumServers() {
  for (const s of wireguardPremiumServers) {
    const doc = {
      ...s,
      premiumOnly: true,
      active: true,
      sortOrder: typeof s.id === 'number' ? s.id : 0,
    };
    await WireguardServer.findOneAndUpdate(
      { id: s.id },
      { $set: doc },
      { upsert: true, new: true }
    );
  }
}

/** Seed WireGuard servers when the collection is empty (first deploy / fresh database). */
export async function ensureWireguardServersSeeded() {
  const count = await WireguardServer.countDocuments();
  if (count > 0) return;

  await upsertWireguardPremiumServers();
  console.log(`Seeded ${wireguardPremiumServers.length} WireGuard premium server(s)`);
}

