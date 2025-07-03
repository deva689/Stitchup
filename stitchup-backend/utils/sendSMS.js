const twilio = require('twilio');

// Initialize Twilio client with credentials from environment
const client = twilio(
  process.env.TWILIO_SID,
  process.env.TWILIO_AUTH_TOKEN
);

/**
 * Send OTP SMS using Twilio
 * @param {string} phone - Phone number (with or without +91)
 * @param {string} otp - 6-digit OTP code
 */
const sendSMS = async (phone, otp) => {
  if (!phone || !otp) {
    throw new Error("Phone and OTP are required ❌");
  }

  // Normalize phone number (defaults to Indian numbers if not international)
  const fullPhone = phone.startsWith('+') ? phone : `+91${phone}`;

  try {
    const message = await client.messages.create({
      body: `<#> ${otp} is your StitchUp verification code. Never share this code with anyone.`,
      from: process.env.TWILIO_PHONE, // Your Twilio-verified sender number
      to: fullPhone
    });

    console.log(`✅ OTP sent to ${fullPhone}: SID=${message.sid}`);
    return message;
  } catch (err) {
    console.error("❌ SMS sending failed:", err.message);
    throw new Error("Failed to send OTP SMS ❌");
  }
};

module.exports = sendSMS;