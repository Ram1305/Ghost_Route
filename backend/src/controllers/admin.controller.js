import User from '../models/user.model.js';
import Plan from '../models/plan.model.js';
import Notification from '../models/notification.model.js';
import { sendPushToTokens } from '../services/push.service.js';

/** POST /api/admin/notifications/test — push a test alert to the caller's devices. */
export async function sendTestNotification(req, res) {
  try {
    const title = 'Ghost Route test';
    const body = 'Test notification to admin';
    const data = { type: 'test_push' };

    await Notification.create({ type: 'test_push', title, body, data });

    const tokens = (req.user.fcmTokens || []).filter(Boolean);
    if (tokens.length === 0) {
      return res.status(200).json({
        success: false,
        tokenCount: 0,
        error:
          'Saved in Notifications, but this admin has no FCM token yet. Open the app while logged in, allow notifications, then retry.',
      });
    }
    const result = await sendPushToTokens(tokens, { title, body, data });
    res.json({
      success: result.successCount > 0,
      tokenCount: tokens.length,
      ...result,
    });
  } catch (err) {
    console.error('Admin test push error:', err);
    res.status(500).json({ error: err.message || 'Failed to send test push' });
  }
}

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
