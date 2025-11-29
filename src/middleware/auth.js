const jwt = require('jsonwebtoken');
const { query } = require('../config/database');

// Перевірка JWT токену
const authenticate = async (req, res, next) => {
  try {
    // Отримуємо токен з заголовка
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    const token = authHeader.substring(7); // Видаляємо "Bearer "

    // Перевіряємо токен
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Отримуємо користувача з БД
    const result = await query(
      'SELECT id, email, role, is_blocked FROM users WHERE id = $1',
      [decoded.userId]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'User not found'
      });
    }

    const user = result.rows[0];

    // Перевіряємо, чи користувач заблокований
    if (user.is_blocked) {
      return res.status(403).json({
        success: false,
        message: 'Your account has been blocked. Please contact administrator.'
      });
    }

    // Додаємо користувача до request
    req.user = user;
    next();

  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token'
      });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expired'
      });
    }
    
    console.error('Authentication error:', error);
    return res.status(500).json({
      success: false,
      message: 'Authentication failed'
    });
  }
};

// Перевірка ролі admin
const requireAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({
      success: false,
      message: 'Access denied. Admin rights required.'
    });
  }
  next();
};

module.exports = {
  authenticate,
  requireAdmin
};
