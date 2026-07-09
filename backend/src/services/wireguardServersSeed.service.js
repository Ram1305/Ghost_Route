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

/** Sync WireGuard servers from config into MongoDB on every startup. */
export async function ensureWireguardServersSeeded() {
  await upsertWireguardPremiumServers();
  console.log(`Synced ${wireguardPremiumServers.length} WireGuard premium server(s)`);
}

