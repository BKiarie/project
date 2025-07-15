const express = require('express');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { createUser, findUserByEmail, setVerificationToken, findUserByVerificationToken, verifyUserByToken } = require('../models/user');
const { sendVerificationEmail, sendPasswordResetEmail } = require('../utils/email');
// const nodemailer = require('nodemailer'); // Uncomment and configure for real email sending

const router = express.Router();

// Registration endpoint
router.post('/register', async (req, res) => {
  const { email, password, role } = req.body;
  if (!email || !password || !role) {
    return res.status(400).json({ message: 'Email, password, and role are required.' });
  }
  try {
    const existingUser = await findUserByEmail(email);
    if (existingUser) {
      return res.status(409).json({ message: 'User already exists.' });
    }
    const hashedPassword = await bcrypt.hash(password, 10);
    const verificationToken = crypto.randomBytes(32).toString('hex');
    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit code
    await require('../db').query(
      'INSERT INTO users (email, password, role, is_verified, verification_token, verification_code) VALUES (?, ?, ?, ?, ?, ?)',
      [email, hashedPassword, role, false, verificationToken, verificationCode]
    );
    // Send verification email with both link and code
    try {
      await sendVerificationEmail(email, verificationToken, verificationCode);
    } catch (emailErr) {
      return res.status(500).json({ message: 'User registered, but failed to send verification email.', error: emailErr.message });
    }
    res.status(201).json({ message: 'User registered. Please check your email to verify your account.' });
  } catch (err) {
    res.status(500).json({ message: 'Registration failed.', error: err.message });
  }
});

// Email verification endpoint
router.get('/verify', async (req, res) => {
  const { token } = req.query;
  if (!token) {
    return res.status(400).json({ message: 'Verification token is required.' });
  }
  try {
    const user = await findUserByVerificationToken(token);
    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired verification token.' });
    }
    await verifyUserByToken(token);
    res.json({ message: 'Email verified successfully. You can now log in.' });
  } catch (err) {
    res.status(500).json({ message: 'Email verification failed.', error: err.message });
  }
});

// Verify by code endpoint
router.post('/verify-code', async (req, res) => {
  const { email, code } = req.body;
  if (!email || !code) return res.status(400).json({ message: 'Email and code are required.' });
  try {
    const [rows] = await require('../db').query('SELECT * FROM users WHERE email = ? AND verification_code = ?', [email, code]);
    if (rows.length === 0) return res.status(400).json({ message: 'Invalid code.' });
    await require('../db').query('UPDATE users SET is_verified = ?, verification_token = NULL, verification_code = NULL WHERE email = ?', [true, email]);
    res.json({ message: 'Email verified successfully. You can now log in.' });
  } catch (err) {
    res.status(500).json({ message: 'Verification failed.', error: err.message });
  }
});

// Login endpoint
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required.' });
  }
  try {
    const user = await findUserByEmail(email);
    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials.' });
    }
    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(401).json({ message: 'Invalid credentials.' });
    }
    if (!user.is_verified) {
      return res.status(403).json({ message: 'Please verify your email before logging in.' });
    }
    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    res.json({ token, user: { id: user.id, email: user.email, role: user.role } });
  } catch (err) {
    res.status(500).json({ message: 'Login failed.', error: err.message });
  }
});

// Forgot password endpoint
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ message: 'Email is required.' });
  try {
    const user = await findUserByEmail(email);
    if (!user) return res.status(404).json({ message: 'No user found with that email.' });
    const resetToken = crypto.randomBytes(32).toString('hex');
    // Save token to user
    await require('../db').query('UPDATE users SET password_reset_token = ? WHERE email = ?', [resetToken, email]);
    await sendPasswordResetEmail(email, resetToken);
    res.json({ message: 'Password reset email sent.' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to send password reset email.', error: err.message });
  }
});

// Reset password endpoint
router.post('/reset-password', async (req, res) => {
  const { token, newPassword } = req.body;
  if (!token || !newPassword) return res.status(400).json({ message: 'Token and new password are required.' });
  try {
    const [rows] = await require('../db').query('SELECT * FROM users WHERE password_reset_token = ?', [token]);
    if (rows.length === 0) return res.status(400).json({ message: 'Invalid or expired reset token.' });
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await require('../db').query('UPDATE users SET password = ?, password_reset_token = NULL WHERE password_reset_token = ?', [hashedPassword, token]);
    res.json({ message: 'Password reset successful. You can now log in.' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to reset password.', error: err.message });
  }
});

module.exports = router; 