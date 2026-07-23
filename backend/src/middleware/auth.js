const jwt = require('jsonwebtoken');
const { getAuth } = require('../config/firebase');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

async function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    
    // Verify user exists in Firebase
    const auth = getAuth();
    const user = await auth.getUser(decoded.uid);
    
    if (!user) {
      return res.status(401).json({ error: 'Invalid token' });
    }

    req.user = {
      uid: decoded.uid,
      email: decoded.email,
    };
    
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }
}

async function authenticateAdmin(req, res, next) {
  await authenticateToken(req, res, () => {});
  
  if (!req.user) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  // Check if user is admin (you can implement your own logic)
  const db = require('../config/firebase').getFirestore();
  const userDoc = await db.collection('users').doc(req.user.uid).get();
  
  if (!userDoc.exists || !userDoc.data().isAdmin) {
    return res.status(403).json({ error: 'Admin access required' });
  }

  next();
}

function generateToken(user) {
  return jwt.sign(
    {
      uid: user.uid,
      email: user.email,
    },
    JWT_SECRET,
    { expiresIn: '7d' }
  );
}

module.exports = {
  authenticateToken,
  authenticateAdmin,
  generateToken,
};
