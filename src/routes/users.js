const express = require('express');
const { query } = require('../config/database');
const { authenticate, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Всі роути потребують автентифікації та прав адміна
router.use(authenticate);
router.use(requireAdmin);

/**
 * @route   GET /api/users
 * @desc    Отримати список всіх користувачів
 * @access  Admin
 */
router.get('/', async (req, res) => {
  try {
    const result = await query(
      `SELECT id, email, role, is_blocked, created_at 
       FROM users 
       ORDER BY created_at DESC`
    );

    res.json({
      success: true,
      data: {
        users: result.rows,
        count: result.rows.length
      }
    });

  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch users'
    });
  }
});

/**
 * @route   GET /api/users/:id
 * @desc    Отримати одного користувача за ID
 * @access  Admin
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT id, email, role, is_blocked, created_at 
       FROM users 
       WHERE id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: {
        user: result.rows[0]
      }
    });

  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user'
    });
  }
});

/**
 * @route   PUT /api/users/:id/block
 * @desc    Заблокувати/розблокувати користувача
 * @access  Admin
 */
router.put('/:id/block', async (req, res) => {
  try {
    const { id } = req.params;
    const { is_blocked } = req.body;

    // Валідація
    if (typeof is_blocked !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'is_blocked must be a boolean value'
      });
    }

    // Перевіряємо, чи користувач існує
    const userCheck = await query('SELECT id, role FROM users WHERE id = $1', [id]);
    
    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Не дозволяємо блокувати адміна
    if (userCheck.rows[0].role === 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Cannot block admin users'
      });
    }

    // Блокуємо/розблоковуємо
    const result = await query(
      `UPDATE users 
       SET is_blocked = $1 
       WHERE id = $2 
       RETURNING id, email, role, is_blocked`,
      [is_blocked, id]
    );

    res.json({
      success: true,
      message: `User ${is_blocked ? 'blocked' : 'unblocked'} successfully`,
      data: {
        user: result.rows[0]
      }
    });

  } catch (error) {
    console.error('Block user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update user status'
    });
  }
});

/**
 * @route   DELETE /api/users/:id
 * @desc    Видалити користувача
 * @access  Admin
 */
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Перевіряємо, чи користувач існує
    const userCheck = await query('SELECT id, role FROM users WHERE id = $1', [id]);
    
    if (userCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Не дозволяємо видаляти адміна
    if (userCheck.rows[0].role === 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Cannot delete admin users'
      });
    }

    // Не дозволяємо видаляти себе
    if (parseInt(id) === req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Cannot delete your own account'
      });
    }

    // Видаляємо (CASCADE автоматично видалить категорії та транзакції)
    await query('DELETE FROM users WHERE id = $1', [id]);

    res.json({
      success: true,
      message: 'User deleted successfully'
    });

  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete user'
    });
  }
});

module.exports = router;
