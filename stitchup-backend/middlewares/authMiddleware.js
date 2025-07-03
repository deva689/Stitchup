// middleware/firebaseAuthMiddleware.js
const admin = require('firebase-admin');

// Initialize Firebase Admin once (do this in a central place like server.js)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(), // or use cert
  });
}

const firebaseAuthMiddleware = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: '❌ No Firebase token provided' });
  }

  const idToken = authHeader.split(' ')[1];

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken; // you get uid, email, phoneNumber etc.
    next();
  } catch (err) {
    console.error('Firebase Token Error:', err);
    return res.status(401).json({ error: '❌ Invalid Firebase token' });
  }
};

module.exports = firebaseAuthMiddleware;