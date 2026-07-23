const admin = require('firebase-admin');

let db = null;
let auth = null;

function initializeFirebase() {
  try {
    const serviceAccount = {
      type: process.env.FIREBASE_TYPE || 'service_account',
      project_id: process.env.FIREBASE_PROJECT_ID || 'lucky-quest-production',
      private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID || '',
      private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n') || '',
      client_email: process.env.FIREBASE_CLIENT_EMAIL || '',
      client_id: process.env.FIREBASE_CLIENT_ID || '',
      auth_uri: process.env.FIREBASE_AUTH_URI || 'https://accounts.google.com/o/oauth2/auth',
      token_uri: process.env.FIREBASE_TOKEN_URI || 'https://oauth2.googleapis.com/token',
    };

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: process.env.FIREBASE_DATABASE_URL,
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    });

    db = admin.firestore();
    auth = admin.auth();

    console.log('Firebase initialized successfully');
  } catch (error) {
    console.error('Firebase initialization error:', error);
    throw error;
  }
}

function getFirestore() {
  if (!db) {
    throw new Error('Firestore not initialized');
  }
  return db;
}

function getAuth() {
  if (!auth) {
    throw new Error('Auth not initialized');
  }
  return auth;
}

module.exports = {
  initializeFirebase,
  getFirestore,
  getAuth,
};
