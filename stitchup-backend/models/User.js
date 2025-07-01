const { ObjectId } = require('mongodb');

class User {
  constructor(emailOrPhone, otp, roomId = null) {
    this._id = new ObjectId();                // Optional: unique MongoDB-style ID
    this.emailOrPhone = emailOrPhone;
    this.otp = otp;
    this.roomId = roomId;
    this.createdAt = new Date();              // Timestamp for OTP creation
    this.verified = false;                    // Optional: flag after successful OTP verification
  }
}

module.exports = User;