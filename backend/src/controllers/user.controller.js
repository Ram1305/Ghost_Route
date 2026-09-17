import User from '../models/user.model.js';

export async function getAllUsers(req, res) {
  try {
    const users = await User.find().select('-password').lean();
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

export async function getUserById(req, res) {
  try {
    const user = await User.findById(req.params.id).select('-password').lean();
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

export async function createUser(req, res) {
  try {
    const user = await User.create(req.body);
    const { password, ...rest } = user.toObject();
    res.status(201).json(rest);
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ error: 'Email already registered' });
    }
    res.status(400).json({ error: err.message });
  }
}

export async function updateUser(req, res) {
  try {
    // Role/password changes go through auth flows (ADMIN_EMAILS sync,
    // forgot-password) on purpose, never this generic field-update endpoint.
    const { password, role, _id, ...safeUpdates } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { $set: safeUpdates },
      { new: true, runValidators: true }
    ).select('-password');
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
}

/** POST /api/users/me/fcm-token — registers the caller's own device for push. */
export async function registerFcmToken(req, res) {
  try {
    const token = String(req.body?.token || '').trim();
    if (!token) {
      return res.status(400).json({ error: 'token is required' });
    }
    if (!req.user.fcmTokens.includes(token)) {
      req.user.fcmTokens.push(token);
      await req.user.save();
    }
    res.status(200).json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}

export async function deleteUser(req, res) {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
}
