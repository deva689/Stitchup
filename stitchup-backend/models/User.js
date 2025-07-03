const { ObjectId } = require('mongodb');

class User {
  constructor({ email = null, phone = null, otp = null, roomId = null }) {
    this._id = new ObjectId();             // MongoDB Object ID
    this.email = email;                    // Optional email
    this.phone = phone;                    // Optional phone
    this.otp = otp;                        // OTP code
    this.roomId = roomId;                  // Optional chat room ID
    this.createdAt = new Date();           // When OTP/user was created
    this.verified = false;                 // Flag for successful OTP login
  }
}

module.exports = User;