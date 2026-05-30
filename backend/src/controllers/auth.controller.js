import bcrypt from 'bcrypt';
import User from '../models/user.model.js';
import * as otpStore from '../services/otp.store.js';
import * as emailService from '../services/email.service.js';

const PURPOSES = ['signup', 'forgot_password'];

export async function sendOtp(req, res) {
  try {
    const { email, purpose } = req.body;
    const normalizedEmail = String(email || '').trim().toLowerCase();
    if (!normalizedEmail) {
      return res.status(400).json({ error: 'Email is required' });
    }
    if (!PURPOSES.includes(purpose)) {
      return res.status(400).json({ error: 'Invalid purpose. Use signup or forgot_password' });
    }
    if (!otpStore.canSend(normalizedEmail)) {
      return res.status(429).json({ error: 'Please wait a minute before requesting another code' });
    }
    if (purpose === 'forgot_password') {
      const user = await User.findOne({ email: normalizedEmail });
      if (!user) {
        return res.status(404).json({ error: 'No account found with this email' });
      }
    }
    const code = otpStore.generateCode();
    otpStore.set(normalizedEmail, purpose, code);
    await emailService.sendOtpEmail(normalizedEmail, code);
    res.status(200).json({ success: true, message: 'OTP sent to your email' });
  } catch (err) {
    console.error('Send OTP error:', err);
    res.status(500).json({ error: err.message || 'Failed to send OTP' });
  }
}

export async function verifyOtp(req, res) {
  try {
    const { email, code, purpose } = req.body;
    const normalizedEmail = String(email || '').trim().toLowerCase();
    if (!normalizedEmail || !code || !PURPOSES.includes(purpose)) {
      return res.status(400).json({ error: 'Email, code and purpose (signup|forgot_password) are required' });
    }
    const valid = otpStore.verifyAndConsume(normalizedEmail, purpose, code);
    if (!valid) {
      return res.status(400).json({ error: 'Invalid or expired OTP' });
    }
    res.status(200).json({ success: true, message: 'OTP verified' });
  } catch (err) {
    console.error('Verify OTP error:', err);
    res.status(500).json({ error: err.message || 'Verification failed' });
  }
}

export async function register(req, res) {
  try {
    const { email, password, username, phone } = req.body;
    const normalizedEmail = String(email || '').trim().toLowerCase();
    if (!normalizedEmail || !password || !username) {
      return res.status(400).json({ error: 'Email, password and username are required' });
    }
    if (!otpStore.checkVerifiedAndConsume(normalizedEmail, 'signup')) {
      return res.status(400).json({ error: 'Please verify your email with OTP first' });
    }
    const user = await User.create({
      email: normalizedEmail,
      password,
      username: String(username).trim(),
      phone: phone ? String(phone).trim() : '',
    });
    const obj = user.toObject();
    delete obj.password;
    try {
      await emailService.sendWelcomeEmail(normalizedEmail, user.username);
    } catch (e) {
      console.error('Welcome email failed:', e);
    }
    res.status(201).json({ user: obj, backendUserId: obj._id.toString() });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ error: 'Email already registered' });
    }
    console.error('Register error:', err);
    res.status(400).json({ error: err.message || 'Registration failed' });
  }
}

export async function login(req, res) {
  try {
    const { email, password } = req.body;
    const normalizedEmail = String(email || '').trim().toLowerCase();
    if (!normalizedEmail || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    const user = await User.findOne({ email: normalizedEmail });
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    const match = await bcrypt.compare(password, user.password);
    if (!match) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    const obj = user.toObject();
    delete obj.password;
    res.status(200).json({ user: obj, backendUserId: obj._id.toString() });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: err.message || 'Login failed' });
  }
}

export async function forgotPasswordSendOtp(req, res) {
  req.body.purpose = 'forgot_password';
  return sendOtp(req, res);
}

export async function forgotPasswordVerifyAndReset(req, res) {
  try {
    const { email, code, newPassword } = req.body;
    const normalizedEmail = String(email || '').trim().toLowerCase();
    if (!normalizedEmail || !newPassword) {
      return res.status(400).json({ error: 'Email and newPassword are required' });
    }
    let valid = false;
    if (code) {
      valid = otpStore.verifyAndConsume(normalizedEmail, 'forgot_password', code);
    }
    if (!valid) {
      valid = otpStore.checkVerifiedAndConsume(normalizedEmail, 'forgot_password');
    }
    if (!valid) {
      return res.status(400).json({ error: 'Invalid or expired OTP. Please verify OTP first or request a new code.' });
    }
    const user = await User.findOne({ email: normalizedEmail });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    user.password = await bcrypt.hash(newPassword, 10);
    await user.save();
    try {
      await emailService.sendPasswordResetConfirmation(normalizedEmail);
    } catch (e) {
      console.error('Password reset confirmation email failed:', e);
    }
    res.status(200).json({ success: true, message: 'Password updated' });
  } catch (err) {
    console.error('Forgot password reset error:', err);
    res.status(500).json({ error: err.message || 'Failed to reset password' });
  }
}
