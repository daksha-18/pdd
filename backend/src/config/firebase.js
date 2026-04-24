const admin = require('firebase-admin');
const path = require('path');

let firebaseInitialized = false;

const initializeFirebase = () => {
  if (firebaseInitialized) return;

  try {
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
    if (serviceAccountPath) {
      const serviceAccount = require(path.resolve(serviceAccountPath));
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      firebaseInitialized = true;
      console.log('✅ Firebase Admin initialized');
    } else {
      console.log('⚠️ Firebase service account not configured, notifications disabled');
    }
  } catch (error) {
    console.error('❌ Firebase initialization error:', error.message);
  }
};

const sendPushNotification = async (fcmToken, title, body, data = {}) => {
  if (!firebaseInitialized) {
    console.log('Firebase not initialized, skipping push notification');
    return null;
  }

  try {
    const message = {
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      token: fcmToken,
    };

    const response = await admin.messaging().send(message);
    console.log('Push notification sent:', response);
    return response;
  } catch (error) {
    console.error('Push notification error:', error.message);
    return null;
  }
};

const sendToTopic = async (topic, title, body, data = {}) => {
  if (!firebaseInitialized) return null;

  try {
    const message = {
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      topic,
    };

    return await admin.messaging().send(message);
  } catch (error) {
    console.error('Topic notification error:', error.message);
    return null;
  }
};

// Initialize on import
initializeFirebase();

module.exports = { admin, sendPushNotification, sendToTopic };
