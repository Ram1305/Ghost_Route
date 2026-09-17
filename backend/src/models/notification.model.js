import mongoose from 'mongoose';

/**
 * Shared admin notification log (persisted alongside the push alert, so
 * events are visible even if a device missed the push or has none
 * registered). Not per-admin — read state is shared across all admins,
 * same as a small team inbox.
 */
const notificationSchema = new mongoose.Schema(
  {
    type: { type: String, required: true }, // e.g. 'new_subscription'
    title: { type: String, required: true },
    body: { type: String, required: true },
    data: { type: mongoose.Schema.Types.Mixed, default: {} },
    read: { type: Boolean, default: false },
  },
  { timestamps: true },
);

export default mongoose.model('Notification', notificationSchema);
