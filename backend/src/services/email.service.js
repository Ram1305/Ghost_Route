import nodemailer from 'nodemailer';

// Email config from .env (EMAIL_*)
const EMAIL_HOST = process.env.EMAIL_HOST || process.env.SMTP_HOST || '';
const EMAIL_PORT = Number(process.env.EMAIL_PORT || process.env.SMTP_PORT) || 587;
const EMAIL_SECURE = (process.env.EMAIL_SECURE || process.env.SMTP_SECURE) === 'true';
const EMAIL_USER = process.env.EMAIL_USER || process.env.SMTP_USER || '';
const EMAIL_PASS = process.env.EMAIL_PASS || process.env.SMTP_PASS || '';
const MAIL_FROM = process.env.MAIL_FROM || EMAIL_USER || 'noreply@yencodetech.com';

let transporter = null;

function getTransport() {
  if (transporter) return transporter;
  if (!EMAIL_HOST || !EMAIL_USER || !EMAIL_PASS) {
    console.warn('Email not configured: set EMAIL_HOST, EMAIL_USER, EMAIL_PASS in .env');
    return null;
  }
  transporter = nodemailer.createTransport({
    host: EMAIL_HOST,
    port: EMAIL_PORT,
    secure: EMAIL_SECURE,
    auth: { user: EMAIL_USER, pass: EMAIL_PASS },
  });
  return transporter;
}

/**
 * Send a generic email. Returns promise that resolves when sent (or rejects).
 */
export async function sendMail({ to, subject, html, text }) {
  const transport = getTransport();
  if (!transport) {
    console.warn('Email skipped (SMTP not configured):', subject, 'to', to);
    return;
  }
  await transport.sendMail({
    from: MAIL_FROM,
    to,
    subject,
    html: html || text,
    text: text || (html ? html.replace(/<[^>]+>/g, '').trim() : undefined),
  });
}

const OTP_VALID_MINUTES = 10;

export async function sendOtpEmail(to, code) {
  const subject = 'Your Ghost Route verification code';
  const text = `Your verification code is: ${code}. It is valid for ${OTP_VALID_MINUTES} minutes.`;
  const html = `
    <p>Your verification code is: <strong>${code}</strong>.</p>
    <p>It is valid for ${OTP_VALID_MINUTES} minutes.</p>
    <p>If you did not request this code, please ignore this email.</p>
  `;
  await sendMail({ to, subject, html, text });
}

export async function sendWelcomeEmail(to, username) {
  const subject = 'Welcome to Ghost Route';
  const name = username || 'there';
  const text = `Hi ${name}, welcome to Ghost Route. Your account has been created successfully. You can now sign in with your email and password.`;
  const html = `
    <h2>Welcome to Ghost Route</h2>
    <p>Hi ${name},</p>
    <p>Your account has been created successfully. You can now sign in with your email and password.</p>
    <p>Thank you for joining us!</p>
  `;
  await sendMail({ to, subject, html, text });
}

export async function sendInvoiceEmail(to, { orderId, paymentId, planName, amount, currency, date }) {
  const subject = 'Your Ghost Route invoice';
  const dateStr = date ? new Date(date).toLocaleString() : new Date().toLocaleString();
  const text = `Invoice – Order: ${orderId || 'N/A'}, Plan: ${planName || 'N/A'}, Amount: ${amount} ${currency || 'USD'}, Date: ${dateStr}.`;
  const html = `
    <h2>Ghost Route – Payment receipt</h2>
    <p>Thank you for your purchase.</p>
    <table style="border-collapse: collapse;">
      <tr><td><strong>Order ID</strong></td><td>${orderId || 'N/A'}</td></tr>
      <tr><td><strong>Payment ID</strong></td><td>${paymentId || 'N/A'}</td></tr>
      <tr><td><strong>Plan</strong></td><td>${planName || 'N/A'}</td></tr>
      <tr><td><strong>Amount</strong></td><td>${amount} ${currency || 'USD'}</td></tr>
      <tr><td><strong>Date</strong></td><td>${dateStr}</td></tr>
    </table>
  `;
  await sendMail({ to, subject, html, text });
}

export async function sendPasswordResetConfirmation(to) {
  const subject = 'Your Ghost Route password was changed';
  const text = 'Your Ghost Route account password has been changed successfully. If you did not make this change, please contact support.';
  const html = `
    <h2>Password changed</h2>
    <p>Your Ghost Route account password has been changed successfully.</p>
    <p>If you did not make this change, please contact support.</p>
  `;
  await sendMail({ to, subject, html, text });
}
