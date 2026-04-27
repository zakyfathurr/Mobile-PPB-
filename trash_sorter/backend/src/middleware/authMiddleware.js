const admin = require('firebase-admin');
const path = require('path');
require('dotenv').config();

function initFirebaseAdmin() {
  if (admin.apps.length === 0) {
    const serviceAccountPath = path.resolve(
      process.env.FIREBASE_SERVICE_ACCOUNT_PATH || '../serviceAccountKey.json'
    );
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }
}

/**
 * Middleware: verifies Firebase ID token from Authorization: Bearer <token>
 * Sets req.uid on success.
 */
async function verifyFirebaseToken(req, res, next) {
  try {
    initFirebaseAdmin();
    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing Authorization header' });
    }
    const idToken = authHeader.split('Bearer ')[1];
    const decoded = await admin.auth().verifyIdToken(idToken);
    req.uid = decoded.uid;
    req.email = decoded.email;
    next();
  } catch (err) {
    console.error('[Auth] Token error:', err.message);
    return res.status(401).json({ error: 'Unauthorized — invalid token' });
  }
}

module.exports = { verifyFirebaseToken };
