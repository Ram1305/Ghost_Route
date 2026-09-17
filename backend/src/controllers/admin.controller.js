import User from '../models/user.model.js';
import Plan from '../models/plan.model.js';

/** GET /api/admin/stats */
export async function getStats(req, res) {
  try {
    const [totalUsers, activeSubscribers] = await Promise.all([
      User.countDocuments(),
      // Matches the definition expireSubscriptions.js uses to clear a lapsed plan.
      User.countDocuments({ activePlan: { $ne: null } }),
    ]);
    res.json({ totalUsers, activeSubscribers });
  } catch (err) {
    console.error('Admin stats error:', err);
    res.status(500).json({ error: err.message || 'Failed to load stats' });
  }
}

/** GET /api/admin/subscriptions/recent?limit=20&since=ISO-date */
export async function getRecentSubscriptions(req, res) {
  try {
    const limit = Math.min(Math.max(Number(req.query.limit) || 20, 1), 100);
    const since = req.query.since ? new Date(req.query.since) : null;

    const rows = await User.aggregate([
      { $unwind: '$subscriptionHistory' },
      ...(since && !isNaN(since.getTime())
        ? [{ $match: { 'subscriptionHistory.date': { $gt: since } } }]
        : []),
      { $sort: { 'subscriptionHistory.date': -1 } },
      { $limit: limit },
      {
        $project: {
          _id: 0,
          userId: '$_id',
          email: 1,
          username: 1,
          plan: '$subscriptionHistory.plan',
          date: '$subscriptionHistory.date',
          amount: '$subscriptionHistory.amount',
          currency: '$subscriptionHistory.currency',
          platform: '$subscriptionHistory.platform',
        },
      },
    ]);

    const plans = await Plan.find().select('index displayName').lean();
    const planNameByIndex = new Map(plans.map((p) => [p.index, p.displayName]));
    const result = rows.map((r) => ({ ...r, planName: planNameByIndex.get(r.plan) || null }));

    res.json(result);
  } catch (err) {
    console.error('Admin recent subscriptions error:', err);
    res.status(500).json({ error: err.message || 'Failed to load recent subscriptions' });
  }
}
