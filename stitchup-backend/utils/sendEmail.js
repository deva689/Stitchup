const nodemailer = require('nodemailer');

const sendEmail = async (to, otp) => {
  if (!to || !otp) {
    throw new Error("Email and OTP are required to send mail.");
  }

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS, // App-specific password
    },
  });

  const mailOptions = {
    from: `"CareGoals ❤️" <${process.env.EMAIL_USER}>`,
    to,
    subject: '🔐 Your OTP for CareGoals',
    html: `
      <div style="font-family: Arial, sans-serif; color: #333;">
        <h2 style="color: #ff4d4d;">Welcome to CareGoals 💕</h2>
        <p>Your OTP is: <strong style="font-size: 18px;">${otp}</strong></p>
        <p>Please use this OTP to verify your identity. It is valid for a limited time only.</p>
        <br/>
        <small>If you didn't request this, you can ignore this message.</small>
      </div>
    `,
  };

  try {
    const info = await transporter.sendMail(mailOptions);
    console.log(`📧 OTP email sent to ${to}: ${info.messageId}`);
  } catch (error) {
    console.error("❌ Failed to send email:", error);
    throw error;
  }
};

module.exports = sendEmail;
