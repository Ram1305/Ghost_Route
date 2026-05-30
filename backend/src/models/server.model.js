import mongoose from 'mongoose';

const serverSchema = new mongoose.Schema(
  {
    hostname: { type: String, required: true, trim: true },
    ip: { type: String, required: true, trim: true },
    ping: { type: String, default: '0' },
    speed: { type: Number, default: 0 },
    countryLong: { type: String, required: true, trim: true },
    countryShort: { type: String, required: true, trim: true, uppercase: true },
    numVpnSessions: { type: Number, default: 0 },
    openVPNConfigDataBase64: { type: String, required: true },
    premiumOnly: { type: Boolean, default: false },
    active: { type: Boolean, default: true },
    sortOrder: { type: Number, default: 0 },
  },
  { timestamps: true }
);

serverSchema.index({ active: 1, sortOrder: 1 });

export default mongoose.model('Server', serverSchema);
