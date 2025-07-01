const twilio = require('twilio');

const client = twilio(process.env.TWILIO_SID, process.env.TWILIO_AUTH_TOKEN);

const sendSMS = async (phone, otp) => {
  if (!phone || !otp) throw new Error("Phone and OTP required");

  const fullPhone = phone.startsWith('+') ? phone : `+91${phone}`;

  try {
    const message = await client.messages.create({
      body: `<#> ${otp} is the OTP for your Stitchup account. Wishing you an awesome experience.`,
      from: process.env.TWILIO_PHONE,
      to: fullPhone
    });

    console.log(`📱 OTP sent to ${fullPhone}: SID=${message.sid}`);
    return message;
  } catch (err) {
    console.error("❌ SMS sending failed:", err.message);
    throw err;
  }
};

module.exports = sendSMS;