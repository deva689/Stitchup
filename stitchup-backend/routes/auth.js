const express = require("express");
const jwt = require("jsonwebtoken");
const sendEmail = require("../utils/sendEmail");
const sendSMS = require("../utils/sendSMS"); // ✅ Twilio-based SMS sender

const router = express.Router();

// ✅ In-memory OTP store (you should use DB in production)
const otpStore = new Map();

// 🔢 Generate a 6-digit OTP
const generateOtp = () => Math.floor(100000 + Math.random() * 900000).toString();

// 📧 Detect if input is an email
const isEmail = (input) => /\S+@\S+\.\S+/.test(input);

// 📤 Send OTP
router.post("/send-otp", async (req, res) => {
  console.log("📥 Received body:", req.body);

const emailOrPhone = req.body.emailOrPhone || req.body.phone || req.body.email;

  if (!emailOrPhone) {
    return res.status(400).json({ error: "Missing email or phone ❌" });
  }

  const otp = generateOtp();

  // Store OTP with 5 min expiry
  otpStore.set(emailOrPhone, {
    otp,
    expiresAt: Date.now() + 5 * 60 * 1000,
  });

  try {
    if (isEmail(emailOrPhone)) {
      await sendEmail(emailOrPhone, otp); // Send via email
    } else {
      await sendSMS(emailOrPhone, otp); // Send via SMS
    }

    console.log(`✅ OTP ${otp} sent to ${emailOrPhone}`);
    res.json({ message: "OTP sent successfully ✅" });
  } catch (err) {
    console.error("❌ Error sending OTP:", err);
    res.status(500).json({ error: "Failed to send OTP ❌" });
  }
});

// 🔐 Verify OTP & Issue JWT
router.post("/verify-otp", (req, res) => {
const emailOrPhone = req.body.emailOrPhone || req.body.phone || req.body.email;
  const otp = req.body.otp;

  if (!emailOrPhone || !otp) {
    return res.status(400).json({ error: "Missing fields ❌" });
  }

  const otpData = otpStore.get(emailOrPhone);

  console.log("🧪 Verifying OTP for", emailOrPhone);
  console.log("📥 Entered:", otp);
  console.log("📦 Stored:", otpData);

  if (!otpData) {
    return res.status(401).json({ error: "OTP not found ❌" });
  }

  const { otp: storedOtp, expiresAt } = otpData;

  if (Date.now() > expiresAt) {
    otpStore.delete(emailOrPhone);
    return res.status(401).json({ error: "OTP expired ⏰" });
  }

  if (storedOtp !== otp) {
    return res.status(401).json({ error: "Invalid OTP ❌" });
  }

  // ✅ OTP verified, issue JWT
  const token = jwt.sign(
    {
      userId: emailOrPhone,
      role: "partner",
    },
    process.env.JWT_SECRET || "default_secret",
    { expiresIn: "1h" }
  );

  otpStore.delete(emailOrPhone); // ♻️ Remove used OTP
  console.log("🎫 JWT Token issued:", token);

  res.json({ token });
});

module.exports = router;