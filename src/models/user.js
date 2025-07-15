const pool = require('../db');

async function createUser({ email, password, role, verificationToken }) {
  const [result] = await pool.query(
    'INSERT INTO users (email, password, role, is_verified, verification_token) VALUES (?, ?, ?, ?, ?)',
    [email, password, role, false, verificationToken]
  );
  return result.insertId;
}

// Other functions remain unchanged
async function findUserByEmail(email) {
  const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
  return rows[0];
}

async function verifyUser(email) {
  await pool.query('UPDATE users SET is_verified = ? WHERE email = ?', [true, email]);
}

async function setVerificationToken(email, token) {
  await pool.query('UPDATE users SET verification_token = ? WHERE email = ?', [token, email]);
}

async function findUserByVerificationToken(token) {
  const [rows] = await pool.query('SELECT * FROM users WHERE verification_token = ?', [token]);
  return rows[0];
}

async function verifyUserByToken(token) {
  await pool.query('UPDATE users SET is_verified = ?, verification_token = NULL WHERE verification_token = ?', [true, token]);
}

async function deleteUserByEmail(email) {
  await pool.query('DELETE FROM users WHERE email = ?', [email]);
}

module.exports = {
  createUser,
  findUserByEmail,
  verifyUser,
  setVerificationToken,
  findUserByVerificationToken,
  verifyUserByToken,
  deleteUserByEmail,
};