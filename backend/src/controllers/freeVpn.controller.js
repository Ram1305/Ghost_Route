import FreeVpnSession from '../models/freeVpnSession.model.js';

function subjectsFor(deviceId, userId) {
  const subjects = [`device:${deviceId}`];
  if (userId) subjects.push(`user:${userId}`);
  return subjects;
}

function pickLatestRecord(records, localDate) {
  const forToday = records.filter((r) => r.sessionDate === localDate);
  if (forToday.length === 0) return null;
  return forToday.sort(
    (a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime()
  )[0];
}

export async function getFreeVpnStatus(req, res) {
  try {
    const deviceId = String(req.query.deviceId || '').trim();
    const localDate = String(req.query.localDate || '').trim();
    const userId = String(req.query.userId || '').trim() || null;

    if (!deviceId || !localDate) {
      return res.status(400).json({ error: 'deviceId and localDate are required' });
    }

    const records = await FreeVpnSession.find({
      subject: { $in: subjectsFor(deviceId, userId) },
    }).lean();

    const latest = pickLatestRecord(records, localDate);
    const usedToday = latest != null;

    res.json({
      usedToday,
      sessionDate: usedToday ? latest.sessionDate : null,
      startedAt: usedToday && latest.startedAt ? latest.startedAt.getTime() : null,
    });
  } catch (err) {
    console.error('getFreeVpnStatus error:', err);
    res.status(500).json({ error: err.message || 'Failed to load free VPN status' });
  }
}

export async function markFreeVpnSessionUsed(req, res) {
  try {
    const deviceId = String(req.body.deviceId || '').trim();
    const localDate = String(req.body.localDate || '').trim();
    const userId = String(req.body.userId || '').trim() || null;
    const startedAtMs = req.body.startedAt;

    if (!deviceId || !localDate) {
      return res.status(400).json({ error: 'deviceId and localDate are required' });
    }

    const startedAt =
      typeof startedAtMs === 'number' && startedAtMs > 0
        ? new Date(startedAtMs)
        : new Date();

    const payload = {
      sessionDate: localDate,
      startedAt,
      deviceId,
      userId,
    };

    await FreeVpnSession.findOneAndUpdate(
      { subject: `device:${deviceId}` },
      { ...payload, subject: `device:${deviceId}` },
      { upsert: true, new: true }
    );

    if (userId) {
      await FreeVpnSession.findOneAndUpdate(
        { subject: `user:${userId}` },
        { ...payload, subject: `user:${userId}` },
        { upsert: true, new: true }
      );
    }

    res.json({ ok: true, sessionDate: localDate, startedAt: startedAt.getTime() });
  } catch (err) {
    console.error('markFreeVpnSessionUsed error:', err);
    res.status(500).json({ error: err.message || 'Failed to mark free VPN session' });
  }
}
