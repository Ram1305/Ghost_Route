import mongoose from 'mongoose';
import bcrypt from 'bcrypt';

const subscriptionSchema = new mongoose.Schema(
  {
    plan: { type: Number, required: true }, // PremiumPlan index 0-5
    date: { type: Date, default: Date.now },
  },
  { _id: false }
);

const userSchema = new mongoose.Schema(
  {
    username: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, trim: true, lowercase: true },
    phone: { type: String, trim: true },
    password: { type: String, required: true },
    subscriptionHistory: { type: [subscriptionSchema], default: [] },
    activePlan: { type: Number, default: null }, // PremiumPlan index or null
    subscriptionExpiresAt: { type: Date, default: null },
  },
  { timestamps: true }
);

userSchema.index({ email: 1 });

userSchema.pre('save', async function () {
  if (!this.isModified('password')) return;
  const p = this.password;
  if (p && p.length < 60 && !p.startsWith('$2')) {
    this.password = await bcrypt.hash(p, 10);
  }
});

export default mongoose.model('User', userSchema);
