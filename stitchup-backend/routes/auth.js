const express = require("express");
const jwt = require("jsonwebtoken");
const admin = require("firebase-admin");
const sendEmail = require("../utils/sendEmail");
const sendSMS = require("../utils/sendSMS"); // Custom SMS utility

const router = express.Router();

// ✅ In-memory OTP store (use DB in production)
const otpStore = new Map();

// 🔢 6-digit OTP
const generateOtp = () =>
  Math.floor(100000 + Math.random() * 900000).toString();

// 📧 Check email
const isEmail = (input) => /\S+@\S+\.\S+/.test(input);

// 📤 Send OTP
router.post("/send-otp", async (req, res) => {
  const emailOrPhone = req.body.emailOrPhone || req.body.phone || req.body.email;

  if (!emailOrPhone) {
    return res.status(400).json({ error: "Missing email or phone ❌" });
  }

  const otp = generateOtp();

  otpStore.set(emailOrPhone, {
    otp,
    expiresAt: Date.now() + 5 * 60 * 1000,
  });

  try {
    if (isEmail(emailOrPhone)) {
      await sendEmail(emailOrPhone, otp);
    } else {
      await sendSMS(emailOrPhone, otp);
    }

    console.log(`✅ OTP ${otp} sent to ${emailOrPhone}`);
    res.json({ message: "OTP sent successfully ✅" });
  } catch (err) {
    console.error("❌ Error sending OTP:", err);
    res.status(500).json({ error: "Failed to send OTP ❌" });
  }
});

// ✅ Verify OTP + Firebase Auth Token + Issue JWT
router.post("/verify-otp", async (req, res) => {
  const emailOrPhone = req.body.emailOrPhone || req.body.phone || req.body.email;
  const otp = req.body.otp;
  const firebaseIdToken = req.body.firebaseIdToken; // 👈 From frontend after Firebase Auth

  if (!firebaseIdToken) {
    return res.status(401).json({ error: "Missing Firebase token ❌" });
  }

  try {
    // 🔐 Verify Firebase ID token
    const decodedToken = await admin.auth().verifyIdToken(firebaseIdToken);
    const firebaseUid = decodedToken.uid;
    const phone = decodedToken.phone_number || null;
    const email = decodedToken.email || null;

    console.log("✅ Firebase verified:", firebaseUid);

    // Optional: If OTP fallback is enabled
    const otpData = otpStore.get(emailOrPhone);
    if (!otpData || otpData.otp !== otp || Date.now() > otpData.expiresAt) {
      return res.status(401).json({ error: "Invalid or expired OTP ❌" });
    }

    otpStore.delete(emailOrPhone); // 🧹 Clean up used OTP

    // 🎫 Create your own JWT (for app-specific auth)
    const token = jwt.sign(
      {
        uid: firebaseUid,
        phone,
        email,
        role: "partner",
      },
      process.env.JWT_SECRET || "your_default_secret",
      { expiresIn: "1h" }
    );

    res.json({ token });
  } catch (err) {
    console.error("❌ Firebase verification failed:", err);
    res.status(401).json({ error: "Firebase token invalid ❌" });
  }
});

module.exports = router;