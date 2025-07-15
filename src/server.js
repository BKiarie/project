const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

const authRoutes = require('./routes/auth');
app.use('/api/auth', authRoutes);

const propertyRoutes = require('./routes/properties');
app.use('/api/properties', propertyRoutes);

// Test route
app.get('/', (req, res) => {
  res.send('Rentisha Kodi API is running');
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
}); 