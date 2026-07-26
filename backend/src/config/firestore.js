const admin = require('firebase-admin');
const { getFirestore } = require('./firebase');

module.exports = {
  getFirestore,
  FieldValue: admin.firestore.FieldValue,
};
