import mongoose from 'mongoose';

const freeVpnSessionSchema = new mongoose.Schema(
  {
    /** `device:<id>` or `user:<backendUserId>` */
    subject: { type: String, required: true, unique: true, index: true },
    sessionDate: { type: String, required: true },
    startedAt: { type: Date, default: null },
    deviceId: { type: String, default: null },
    userId: { type: String, default: null },
  },
  { timestamps: true }
);

export default mongoose.model('FreeVpnSession', freeVpnSessionSchema);
