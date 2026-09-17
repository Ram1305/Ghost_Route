import jwt from 'jsonwebtoken';

const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '30d';

function secret() {
  const s = process.env.JWT_SECRET;
  if (!s) {
    throw new Error('JWT_SECRET is not configured');
  }
  return s;
}

/** Signs a token carrying only the user id — role/subscription are always
 * re-read from the database per request, never trusted from the token. */
export function signAuthToken(userId) {
  return jwt.sign({ sub: String(userId) }, secret(), { expiresIn: JWT_EXPIRES_IN });
}

/** Returns the decoded payload, or null if missing/invalid/expired. */
export function verifyAuthToken(token) {
  try {
    return jwt.verify(token, secret());
  } catch {
    return null;
  }
}
