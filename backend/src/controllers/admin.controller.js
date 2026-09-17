import User from '../models/user.model.js';
import Plan from '../models/plan.model.js';
import Notification from '../models/notification.model.js';

/** GET /api/admin/stats */
export async function getStats(req, res) {
  try {
    const [totalUsers, activeSubscribers, unreadNotifications] = await Promise.all([
      User.countDocuments(),
      // Matches the definition expireSubscriptions.js uses to clear a lapsed plan.
      User.countDocuments({ activePlan: { $ne: null } }),
      Notification.countDocuments({ read: false }),
    ]);
    res.json({ totalUsers, activeSubscribers, unreadNotifications });
  } catch (err) {
    console.error('Admin stats error:', err);
    res.status(500).json({ error: err.message || 'Failed to load stats' });
  }
}

/** GET /api/admin/notifications?limit=50 */
export async function getNotifications(req, res) {
  try {
    const limit = Math.min(Math.max(Number(req.query.limit) || 50, 1), 200);
    const notifications = await Notification.find()
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();
    res.json(notifications);
  } catch (err) {
    console.error('Admin notifications error:', err);
    res.status(500).json({ error: err.message || 'Failed to load notifications' });
  }
}

/** POST /api/admin/notifications/:id/read */
export async function markNotificationRead(req, res) {
  try {
    const notification = await Notification.findByIdAndUpdate(
      req.params.id,
      { $set: { read: true } },
      { new: true },
    );
    if (!notification) return res.status(404).json({ error: 'Notification not found' });
    res.json(notification);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

/** POST /api/admin/notifications/read-all */
export async function markAllNotificationsRead(req, res) {
  try {
    await Notification.updateMany({ read: false }, { $set: { read: true } });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
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
