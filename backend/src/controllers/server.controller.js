import Server from '../models/server.model.js';

export async function listServers(req, res) {
  try {
    const { premiumOnly } = req.query;
    const filter = { active: true };
    if (premiumOnly === 'true' || premiumOnly === 'false') {
      filter.premiumOnly = premiumOnly === 'true';
    }

    const servers = await Server.find(filter)
      .sort({ sortOrder: 1, countryLong: 1 })
      .select('-__v -createdAt -updatedAt')
      .lean();

    const payload = servers.map((s) => ({
      HostName: s.hostname,
      IP: s.ip,
      Ping: s.ping,
      Speed: s.speed,
      CountryLong: s.countryLong,
      CountryShort: s.countryShort,
      NumVpnSessions: s.numVpnSessions,
      OpenVPN_ConfigData_Base64: s.openVPNConfigDataBase64,
      PremiumOnly: s.premiumOnly,
    }));

    res.json(payload);
  } catch (err) {
    console.error('List servers error:', err);
    res.status(500).json({ error: err.message || 'Failed to load servers' });
  }
}
