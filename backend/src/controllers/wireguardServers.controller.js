import WireguardServer from '../models/wireguardServer.model.js';

export async function listWireguardPremiumServers(req, res) {
  try {
    const servers = await WireguardServer.find({ active: true, premiumOnly: true })
      .sort({ sortOrder: 1, country: 1, city: 1 })
      .select('-__v -createdAt -updatedAt -_id')
      .lean();

    res.json(servers);
  } catch (err) {
    console.error('List WireGuard premium servers error:', err);
    res.status(500).json({
      error: err.message || 'Failed to load WireGuard premium servers',
    });
  }
}

