const express = require('express');
const { authenticateToken, authorizeRoles } = require('../middleware/auth');
const pool = require('../db');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { stkPush } = require('../mpesa');
const { sendViewingRequestEmail } = require('../utils/email');
const router = express.Router();

// Multer setup for photo uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/');
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
const upload = multer({ storage });

// GET /api/properties/map - Get all properties with coordinates for map integration
router.get('/map', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, name, latitude, longitude, status, rent, amenities FROM properties WHERE latitude IS NOT NULL AND longitude IS NOT NULL'
    );
    res.json(rows);
  } catch (err) {
    console.error('Error fetching properties for map:', err);
    res.status(500).json({ message: 'Failed to fetch properties for map.' });
  }
});

// POST /api/properties - Create property (landlord)
router.post('/', authenticateToken, authorizeRoles('landlord'), async (req, res) => {
  const { name, unit_type, rent, description, bathrooms, amenities, latitude, longitude, status } = req.body;
  try {
    const [result] = await pool.query(
      'INSERT INTO properties (name, unit_type, rent, description, bathrooms, amenities, latitude, longitude, status, landlord_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [name, unit_type, rent, description, bathrooms, JSON.stringify(amenities), latitude, longitude, status, req.user.id]
    );
    res.status(201).json({ id: result.insertId, message: 'Property created.' });
  } catch (err) {
    console.error('Error creating property:', err);
    res.status(500).json({ message: 'Failed to create property.' });
  }
});

// GET /api/properties - List all properties
router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM properties');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch properties.' });
  }
});

// GET /api/properties/:id - Get property details
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM properties WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ message: 'Property not found.' });
    const property = rows[0];
    property.amenities = property.amenities ? JSON.parse(property.amenities) : [];
    res.json(property);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch property.' });
  }
});

// POST /api/properties/:id/request-viewing - Request viewing
router.post('/:id/request-viewing', authenticateToken, authorizeRoles('tenant'), async (req, res) => {
  const { viewing_date, message } = req.body;
  try {
    // Insert viewing request
    await pool.query(
      'INSERT INTO viewing_requests (property_id, tenant_id, viewing_date, message, status) VALUES (?, ?, ?, ?, ?)',
      [req.params.id, req.user.id, viewing_date, message, 'pending']
    );

    // Fetch landlord_id, landlord email, property name, and tenant name
    const [propertyRows] = await pool.query('SELECT landlord_id, name FROM properties WHERE id = ?', [req.params.id]);
    if (propertyRows.length > 0) {
      const landlordId = propertyRows[0].landlord_id;
      const propertyName = propertyRows[0].name;
      // Get landlord email
      const [landlordRows] = await pool.query('SELECT email FROM users WHERE id = ?', [landlordId]);
      const landlordEmail = landlordRows.length > 0 ? landlordRows[0].email : null;
      // Get tenant name (if available)
      const [tenantRows] = await pool.query('SELECT email FROM users WHERE id = ?', [req.user.id]);
      const tenantName = tenantRows.length > 0 ? tenantRows[0].email : 'A tenant';
      // Create notification for landlord
      const notifMsg = `New viewing request for your property: ${propertyName}`;
      await pool.query(
        'INSERT INTO notifications (user_id, message) VALUES (?, ?)',
        [landlordId, notifMsg]
      );
      // Send email to landlord
      if (landlordEmail) {
        try {
          await sendViewingRequestEmail(landlordEmail, propertyName, tenantName, viewing_date);
        } catch (emailErr) {
          // Log but don't fail the request
          console.error('Failed to send viewing request email:', emailErr);
        }
      }
    }

    res.status(201).json({ message: 'Viewing request sent.' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to request viewing.' });
  }
});

// POST /api/properties/:id/pay-deposit - Pay deposit (M-Pesa STK Push)
router.post('/:id/pay-deposit', authenticateToken, authorizeRoles('tenant'), async (req, res) => {
  const property_id = req.params.id;
  const tenant_id = req.user.id;
  const { amount, phone } = req.body;
  if (!amount || !phone) {
    return res.status(400).json({ message: 'Amount and phone number are required.' });
  }
  try {
    await pool.query(
      'INSERT INTO payments (property_id, tenant_id, amount, phone_number, status) VALUES (?, ?, ?, ?, ?)',
      [property_id, tenant_id, amount, phone, 'pending']
    );
    // Initiate STK Push (mocked for now)
    // const mpesaRes = await stkPush(phone, amount);
    res.json({ message: 'Payment initiated (mock).' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to initiate payment.' });
  }
});

// GET /api/notifications - Get notifications for the logged-in user (landlord)
router.get('/notifications', authenticateToken, authorizeRoles('landlord'), async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, message, is_read, created_at FROM notifications WHERE user_id = ? ORDER BY created_at DESC',
      [req.user.id]
    );
    res.json(rows);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch notifications.' });
  }
});

// PATCH /api/notifications/:id/read - Mark a notification as read
router.patch('/notifications/:id/read', authenticateToken, authorizeRoles('landlord'), async (req, res) => {
  const notificationId = req.params.id;
  try {
    // Ensure the notification belongs to the logged-in landlord
    const [rows] = await pool.query('SELECT * FROM notifications WHERE id = ? AND user_id = ?', [notificationId, req.user.id]);
    if (rows.length === 0) {
      return res.status(404).json({ message: 'Notification not found.' });
    }
    await pool.query('UPDATE notifications SET is_read = TRUE WHERE id = ?', [notificationId]);
    res.json({ message: 'Notification marked as read.' });
  } catch (err) {
    res.status(500).json({ message: 'Failed to update notification.' });
  }
});

// Export router
module.exports = router;