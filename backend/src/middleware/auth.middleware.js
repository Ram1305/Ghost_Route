import User from '../models/user.model.js';
import { verifyAuthToken } from '../utils/jwt.util.js';

/**
 * Verifies the `Authorization: Bearer <token>` header and attaches the
 * current user (fresh from the database, minus password) as `req.user`.
 * Role/subscription state is always re-read from the DB here rather than
 * trusted from the token, so a revoked admin or expired subscription takes
 * effect immediately without waiting for the token to expire.
 */
export async function authenticate(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const [scheme, token] = header.split(' ');
    if (scheme !== 'Bearer' || !token) {
      return res.status(401).json({ error: 'Authentication required' });
    }
    const payload = verifyAuthToken(token);
    if (!payload?.sub) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }
    const user = await User.findById(payload.sub).select('-password');
    if (!user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  } catch (err) {
    console.error('Auth middleware error:', err);
    res.status(500).json({ error: 'Authentication failed' });
  }
}

/** Allows the request through only if the caller is the :id in the route or an admin. */
export function requireSelfOrAdmin(req, res, next) {
  if (req.user.role === 'admin' || String(req.user._id) === String(req.params.id)) {
    return next();
  }
  res.status(403).json({ error: 'Forbidden' });
}
