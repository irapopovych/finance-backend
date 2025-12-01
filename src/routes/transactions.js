const express = require('express');
const { body, validationResult, query: expressQuery } = require('express-validator');
const { query } = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Всі роути потребують автентифікації
router.use(authenticate);

// Валідація для створення/оновлення транзакції
const transactionValidation = [
  body('amount').isFloat({ min: 0.01 }).withMessage('Amount must be a positive number'),
  body('type').isIn(['income', 'expense']).withMessage('Type must be either income or expense'),
  body('date').isISO8601().withMessage('Invalid date format'),
  body('description').optional().trim(),
  body('category_id').optional().isInt().withMessage('Category ID must be an integer'),
];

/**
 * @route   GET /api/transactions
 * @desc    Отримати всі транзакції користувача з фільтрацією
 * @access  Private
 */
router.get('/', async (req, res) => {
  try {
    const { type, category_id, date_from, date_to, limit = 100, offset = 0 } = req.query;

    let queryText = `
      SELECT 
        t.id, 
        t.amount, 
        t.type, 
        t.description, 
        t.date, 
        t.created_at,
        c.id as category_id,
        c.name as category_name
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = $1
    `;
    
    const queryParams = [req.user.id];
    let paramIndex = 2;

    // Фільтр по типу
    if (type && ['income', 'expense'].includes(type)) {
      queryText += ` AND t.type = $${paramIndex}`;
      queryParams.push(type);
      paramIndex++;
    }

    // Фільтр по категорії
    if (category_id) {
      queryText += ` AND t.category_id = $${paramIndex}`;
      queryParams.push(category_id);
      paramIndex++;
    }

    // Фільтр по даті від
    if (date_from) {
      queryText += ` AND t.date >= $${paramIndex}`;
      queryParams.push(date_from);
      paramIndex++;
    }

    // Фільтр по даті до
    if (date_to) {
      queryText += ` AND t.date <= $${paramIndex}`;
      queryParams.push(date_to);
      paramIndex++;
    }

    queryText += ` ORDER BY t.date DESC, t.created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    queryParams.push(parseInt(limit), parseInt(offset));

    const result = await query(queryText, queryParams);

    // Отримуємо загальну кількість
    const countResult = await query(
      'SELECT COUNT(*) as total FROM transactions WHERE user_id = $1',
      [req.user.id]
    );

    res.json({
      success: true,
      data: {
        transactions: result.rows,
        count: result.rows.length,
        total: parseInt(countResult.rows[0].total)
      }
    });

  } catch (error) {
    console.error('Get transactions error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch transactions'
    });
  }
});

/**
 * @route   GET /api/transactions/stats
 * @desc    Отримати статистику транзакцій (для ML і графіків)
 * @access  Private
 */
router.get('/stats', async (req, res) => {
  try {
    const { date_from, date_to } = req.query;

    // Загальна статистика
    let statsQuery = `
      SELECT 
        type,
        COUNT(*) as count,
        SUM(amount) as total,
        AVG(amount) as average
      FROM transactions
      WHERE user_id = $1
    `;
    
    const queryParams = [req.user.id];
    let paramIndex = 2;

    if (date_from) {
      statsQuery += ` AND date >= $${paramIndex}`;
      queryParams.push(date_from);
      paramIndex++;
    }

    if (date_to) {
      statsQuery += ` AND date <= $${paramIndex}`;
      queryParams.push(date_to);
      paramIndex++;
    }

    statsQuery += ' GROUP BY type';

    const statsResult = await query(statsQuery, queryParams);

    // Статистика по категоріях
    let categoryStatsQuery = `
      SELECT 
        c.id,
        c.name,
        t.type,
        COUNT(*) as count,
        SUM(t.amount) as total
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.user_id = $1
    `;
    
    const categoryParams = [req.user.id];
    let catParamIndex = 2;

    if (date_from) {
      categoryStatsQuery += ` AND t.date >= $${catParamIndex}`;
      categoryParams.push(date_from);
      catParamIndex++;
    }

    if (date_to) {
      categoryStatsQuery += ` AND t.date <= $${catParamIndex}`;
      categoryParams.push(date_to);
      catParamIndex++;
    }

    categoryStatsQuery += ' GROUP BY c.id, c.name, t.type ORDER BY total DESC';

    const categoryStatsResult = await query(categoryStatsQuery, categoryParams);

    // Статистика по місяцях (для ML предикції)
    const monthlyStatsQuery = `
      SELECT 
        DATE_TRUNC('month', date) as month,
        type,
        SUM(amount) as total,
        COUNT(*) as count
      FROM transactions
      WHERE user_id = $1
      GROUP BY month, type
      ORDER BY month DESC
      LIMIT 12
    `;

    const monthlyStatsResult = await query(monthlyStatsQuery, [req.user.id]);

    res.json({
      success: true,
      data: {
        overall: statsResult.rows,
        by_category: categoryStatsResult.rows,
        monthly: monthlyStatsResult.rows
      }
    });

  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch statistics'
    });
  }
});

/**
 * @route   GET /api/transactions/:id
 * @desc    Отримати одну транзакцію
 * @access  Private
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT 
        t.id, 
        t.amount, 
        t.type, 
        t.description, 
        t.date, 
        t.created_at,
        c.id as category_id,
        c.name as category_name
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.id = $1 AND t.user_id = $2`,
      [id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }

    res.json({
      success: true,
      data: {
        transaction: result.rows[0]
      }
    });

  } catch (error) {
    console.error('Get transaction error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch transaction'
    });
  }
});

/**
 * @route   POST /api/transactions
 * @desc    Створити нову транзакцію
 * @access  Private
 */
router.post('/', transactionValidation, async (req, res) => {
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

    const { amount, type, description, date, category_id } = req.body;

    // Якщо вказана категорія, перевіряємо що вона існує і має правильний тип
    if (category_id) {
      const categoryCheck = await query(
        'SELECT id, type FROM categories WHERE id = $1',
        [category_id]
      );

      if (categoryCheck.rows.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Category not found'
        });
      }

      // Перевіряємо що тип транзакції співпадає з типом категорії
      if (categoryCheck.rows[0].type !== type) {
        return res.status(400).json({
          success: false,
          message: `Cannot use ${categoryCheck.rows[0].type} category for ${type} transaction`
        });
      }
    }

    // Створюємо транзакцію
    const result = await query(
      `INSERT INTO transactions (amount, type, description, date, user_id, category_id) 
       VALUES ($1, $2, $3, $4, $5, $6) 
       RETURNING id, amount, type, description, date, category_id, created_at`,
      [amount, type, description || null, date, req.user.id, category_id || null]
    );

    res.status(201).json({
      success: true,
      message: 'Transaction created successfully',
      data: {
        transaction: result.rows[0]
      }
    });

  } catch (error) {
    console.error('Create transaction error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create transaction'
    });
  }
});

/**
 * @route   PUT /api/transactions/:id
 * @desc    Оновити транзакцію
 * @access  Private
 */
router.put('/:id', transactionValidation, async (req, res) => {
  try {
    const { id } = req.params;
    
    // Перевірка валідації
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { amount, type, description, date, category_id } = req.body;

    // Перевіряємо, чи транзакція належить користувачу
    const transactionCheck = await query(
      'SELECT id FROM transactions WHERE id = $1 AND user_id = $2',
      [id, req.user.id]
    );

    if (transactionCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }

    // Якщо вказана категорія, перевіряємо що вона існує і має правильний тип
    if (category_id) {
      const categoryCheck = await query(
        'SELECT id, type FROM categories WHERE id = $1',
        [category_id]
      );

      if (categoryCheck.rows.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Category not found'
        });
      }

      // Перевіряємо що тип транзакції співпадає з типом категорії
      if (categoryCheck.rows[0].type !== type) {
        return res.status(400).json({
          success: false,
          message: `Cannot use ${categoryCheck.rows[0].type} category for ${type} transaction`
        });
      }
    }

    // Оновлюємо
    const result = await query(
      `UPDATE transactions 
       SET amount = $1, type = $2, description = $3, date = $4, category_id = $5
       WHERE id = $6 AND user_id = $7 
       RETURNING id, amount, type, description, date, category_id, created_at`,
      [amount, type, description || null, date, category_id || null, id, req.user.id]
    );

    res.json({
      success: true,
      message: 'Transaction updated successfully',
      data: {
        transaction: result.rows[0]
      }
    });

  } catch (error) {
    console.error('Update transaction error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update transaction'
    });
  }
});

/**
 * @route   DELETE /api/transactions/:id
 * @desc    Видалити транзакцію
 * @access  Private
 */
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Перевіряємо, чи транзакція належить користувачу
    const transactionCheck = await query(
      'SELECT id FROM transactions WHERE id = $1 AND user_id = $2',
      [id, req.user.id]
    );

    if (transactionCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }

    // Видаляємо
    await query('DELETE FROM transactions WHERE id = $1', [id]);

    res.json({
      success: true,
      message: 'Transaction deleted successfully'
    });

  } catch (error) {
    console.error('Delete transaction error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete transaction'
    });
  }
});

module.exports = router;