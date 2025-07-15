const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: process.env.SMTP_PORT ? parseInt(process.env.SMTP_PORT) : 465,
  secure: true,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

async function sendVerificationEmail(email, token, code) {
  const verifyUrl = `${process.env.FRONTEND_URL || 'http://localhost:5000'}/api/auth/verify?token=${token}`;
  const mailOptions = {
    from: process.env.SMTP_FROM || 'no-reply@rentisha.com',
    to: email,
    subject: 'Verify your Rentisha Kodi account',
    html: `<h2>Welcome to Rentisha Kodi!</h2>
      <p>You can verify your account in two ways:</p>
      <ul>
        <li>Click the link: <a href="${verifyUrl}">${verifyUrl}</a></li>
        <li>Or enter this code in the app: <b>${code}</b></li>
      </ul>
      <p>If you did not sign up, please ignore this email.</p>`
  };
  await transporter.sendMail(mailOptions);
}

async function sendViewingRequestEmail(landlordEmail, propertyName, tenantName, viewingDate) {
  const mailOptions = {
    from: process.env.SMTP_FROM || 'no-reply@rentisha.com',
    to: landlordEmail,
    subject: 'New Viewing Request for Your Property',
    html: `<h2>New Viewing Request</h2>
      <p>${tenantName} has requested to view your property: <b>${propertyName}</b>.</p>
      <p>Requested viewing date: <b>${viewingDate}</b></p>
      <p>Please log in to your dashboard to respond.</p>`
  };
  await transporter.sendMail(mailOptions);
}

async function sendPasswordResetEmail(email, resetToken) {
  let resetUrl;
  if (process.env.FRONTEND_URL) {
    resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;
  } else {
    resetUrl = `rentisha://reset-password?token=${resetToken}`;
  }
  const mailOptions = {
    from: process.env.SMTP_FROM || 'no-reply@rentisha.com',
    to: email,
    subject: 'Reset your Rentisha Kodi password',
    html: `<h2>Password Reset Request</h2>
      <p>Click the link below to reset your password:</p>
      <a href="${resetUrl}">${resetUrl}</a>
      <p>If you did not request a password reset, you can ignore this email.</p>`
  };
  await transporter.sendMail(mailOptions);
}

module.exports = {
  sendVerificationEmail,
  sendViewingRequestEmail,
  sendPasswordResetEmail,
}; 