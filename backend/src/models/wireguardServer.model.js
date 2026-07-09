import mongoose from 'mongoose';

const wireguardServerSchema = new mongoose.Schema(
  {
    id: { type: Number, required: true, unique: true, index: true },
    serverName: { type: String, required: true, trim: true },
    country: { type: String, required: true, trim: true },
    city: { type: String, required: true, trim: true },
    host: { type: String, required: true, trim: true },
    port: { type: Number, required: true },
    publicKey: { type: String, required: true, trim: true },
    clientPrivateKey: { type: String, required: true, trim: true },
    address: { type: String, required: true, trim: true },
    dns: { type: String, required: true, trim: true },
    allowedIPs: { type: String, required: true, trim: true },
    persistentKeepalive: { type: Number, default: 25 },
    premiumOnly: { type: Boolean, default: true },
    active: { type: Boolean, default: true },
    sortOrder: { type: Number, default: 0 },
  },
  { timestamps: true }
);

wireguardServerSchema.index({ active: 1, premiumOnly: 1, sortOrder: 1, country: 1 });

export default mongoose.model('WireguardServer', wireguardServerSchema);

