const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { query } = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Валідація для реєстрації
const registerValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Invalid email format'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
];

// Валідація для логіну
const loginValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Invalid email format'),
  body('password').notEmpty().withMessage('Password is required'),
];

/**
 * @route   POST /api/auth/register
 * @desc    Реєстрація нового користувача
 * @access  Public
 */
router.post('/register', registerValidation, async (req, res) => {
  try {
    // Перевірка валідації
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { email, password } = req.body;

    // Перевіряємо, чи користувач вже існує
    const existingUser = await query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'User with this email already exists'
      });
    }

    // Хешуємо пароль
    const passwordHash = await bcrypt.hash(password, 10);

    // Створюємо користувача
    const result = await query(
      `INSERT INTO users (email, password_hash, role) 
       VALUES ($1, $2, $3) 
       RETURNING id, email, role, created_at`,
      [email, passwordHash, 'user']
    );

    const newUser = result.rows[0];

    // Категорії тепер глобальні - не треба створювати для кожного користувача

    // Генеруємо JWT токен
    const token = jwt.sign(
      { userId: newUser.id, email: newUser.email, role: newUser.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: {
          id: newUser.id,
          email: newUser.email,
          role: newUser.role,
          createdAt: newUser.created_at
        },
        token
      }
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Registration failed',
      // error: error.message
    });
  }
});

/**
 * @route   POST /api/auth/login
 * @desc    Вхід користувача
 * @access  Public
 */
router.post('/login', loginValidation, async (req, res) => {
  try {
    // Перевірка валідації
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { email, password } = req.body;

    // Шукаємо користувача
    const result = await query(
      'SELECT id, email, password_hash, role, is_blocked FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
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

    // Перевіряємо пароль
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Генеруємо JWT токен
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRE || '7d' }
    );

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: user.id,
          email: user.email,
          role: user.role
        },
        token
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Login failed',
      // error: error.message
    });
  }
});

/**
 * @route   GET /api/auth/me
 * @desc    Отримати поточного користувача
 * @access  Private
 */
router.get('/me', authenticate, async (req, res) => {
  try {
    res.json({
      success: true,
      data: {
        user: {
          id: req.user.id,
          email: req.user.email,
          role: req.user.role
        }
      }
    });
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get user data'
    });
  }
});

/**
 * @route   POST /api/auth/logout
 * @desc    Вихід користувача (на фронтенді видалити токен)
 * @access  Private
 */
router.post('/logout', authenticate, (req, res) => {
  // JWT stateless, тому просто повертаємо успіх
  // Фронтенд має видалити токен зі свого сховища
  res.json({
    success: true,
    message: 'Logout successful'
  });
});

module.exports = router;