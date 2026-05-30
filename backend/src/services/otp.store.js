/**
 * In-memory OTP store: keyed by email + purpose, with expiry and rate limiting.
 * Structure: { email, code, purpose, expiresAt }
 */

const OTP_EXPIRY_MS = 10 * 60 * 1000; // 10 minutes
const RATE_LIMIT_MS = 60 * 1000; // 1 per 60s per email
const VERIFIED_EXPIRY_MS = 5 * 60 * 1000; // 5 min to complete register/reset after verify

const store = new Map(); // key: `${email.toLowerCase()}:${purpose}`
const verified = new Map(); // key: `${email.toLowerCase()}:${purpose}`, value: expiresAt
const lastSent = new Map(); // key: email (lowercase), value: timestamp

function key(email, purpose) {
  return `${String(email).trim().toLowerCase()}:${purpose}`;
}

export function set(email, purpose, code) {
  const k = key(email, purpose);
  store.set(k, {
    email: String(email).trim().toLowerCase(),
    code: String(code),
    purpose,
    expiresAt: Date.now() + OTP_EXPIRY_MS,
  });
  lastSent.set(String(email).trim().toLowerCase(), Date.now());
}

export function get(email, purpose) {
  const k = key(email, purpose);
  const entry = store.get(k);
  if (!entry) return null;
  if (Date.now() > entry.expiresAt) {
    store.delete(k);
    return null;
  }
  return entry;
}

export function verifyAndConsume(email, purpose, code) {
  const entry = get(email, purpose);
  if (!entry) return false;
  if (entry.code !== String(code).trim()) return false;
  store.delete(key(email, purpose));
  verified.set(key(email, purpose), Date.now() + VERIFIED_EXPIRY_MS);
  return true;
}

export function checkVerifiedAndConsume(email, purpose) {
  const k = key(email, purpose);
  const expiresAt = verified.get(k);
  if (!expiresAt || Date.now() > expiresAt) {
    verified.delete(k);
    return false;
  }
  verified.delete(k);
  return true;
}

export function canSend(email) {
  const last = lastSent.get(String(email).trim().toLowerCase());
  if (!last) return true;
  return Date.now() - last >= RATE_LIMIT_MS;
}

export function generateCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}
