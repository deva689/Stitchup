// Load environment variables
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { MongoClient } = require('mongodb');

const authRoutes = require('./routes/auth');
const authMiddleware = require('./middlewares/authMiddleware');
const sendSMS = require('./utils/sendSMS');
const sendEmail = require('./utils/sendEmail');

const app = express();
app.use(cors());
app.use(express.json());

// ✅ Public health check (early response for Render)
app.get('/', (req, res) => {
  res.send('✅ CareGoals backend working!');
});

// ✅ Protected test route
app.get('/protected', authMiddleware, (req, res) => {
  res.json({ message: `🔐 Welcome, ${req.user.userId}` });
});

// 🧪 Optional test SMS route
app.get('/test-sms', async (req, res) => {
  try {
    const phone = process.env.TEST_PHONE || '+917305240210';
    await sendSMS(phone, '123456');
    res.send('✅ Test SMS sent to ' + phone);
  } catch (err) {
    console.error('❌ SMS Error:', err.message);
    res.status(500).send('❌ Failed to send SMS');
  }
});

// 🧪 Optional test email route
app.get('/test-email', async (req, res) => {
  try {
    const email = process.env.TEST_EMAIL || 'youremail@example.com';
    await sendEmail(email, '123456');
    res.send('✅ Test Email sent to ' + email);
  } catch (err) {
    console.error('❌ Email Error:', err.message);
    res.status(500).send('❌ Failed to send email');
  }
});

// ✅ Bind port before DB connect (required by Render)
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});

// ✅ MongoDB connection
const client = new MongoClient(process.env.MONGO_URI, {
  ssl: true,
});

client.connect()
  .then(() => {
    console.log('✅ MongoDB connected');

    // Attach DB globally
    app.locals.db = client.db();

    // Setup routes that need DB
    app.use('/auth', authRoutes);
  })
  .catch((err) => {
    console.error('❌ MongoDB connection error:', err.message);
  });
