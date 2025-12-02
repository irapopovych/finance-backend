const express = require('express');
const { body, validationResult } = require('express-validator');
const { query } = require('../config/database');
const { authenticate, requireAdmin } = require('../middleware/auth');  // ← Додай requireAdmin

const router = express.Router();

// Всі роути потребують автентифікації
router.use(authenticate);

// Валідація для створення категорії
const createCategoryValidation = [
  body('name').trim().notEmpty().withMessage('Category name is required')
    .isLength({ max: 255 }).withMessage('Category name too long'),
  body('type').optional().isIn(['income', 'expense']).withMessage('Type must be income or expense')
];

/**
 * @route   GET /api/categories
 * @desc    Отримати всі категорії (глобальні для всіх)
 * @access  Private
 */
router.get('/', authenticate, async (req, res) => {
  try {
    const result = await query(
      `SELECT id, name, type, created_at 
       FROM categories 
       ORDER BY type ASC, name ASC`
    );

    res.json({
      success: true,
      data: {
        categories: result.rows,
        count: result.rows.length
      }
    });

  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch categories'
    });
  }
});

/**
 * @route   GET /api/categories/all
 * @desc    Отримати всі категорії у форматі { id, name, type }
 * @access  Private
 */
router.get('/all', authenticate, async (req, res) => {
  try {
    const result = await query(
      `SELECT id, name, type 
       FROM categories 
       ORDER BY type ASC, name ASC`
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('Get all categories error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch categories'
    });
  }
});

/**
 * @route   GET /api/categories/:id
 * @desc    Отримати одну категорію
 * @access  Private
 */
router.get('/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT id, name, type, created_at 
       FROM categories 
       WHERE id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    res.json({
      success: true,
      data: {
        category: result.rows[0]
      }
    });

  } catch (error) {
    console.error('Get category error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch category'
    });
  }
});

/**
 * @route   POST /api/categories
 * @desc    Створити нову категорію (глобальну)
 * @access  Admin only
 */
router.post('/', authenticate, requireAdmin, createCategoryValidation, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { name, type = 'expense' } = req.body;

    // Перевіряємо чи категорія вже існує (глобально)
    const existing = await query(
      'SELECT id FROM categories WHERE name = $1',
      [name]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Category with this name already exists'
      });
    }

    // Створюємо категорію (без user_id)
    const result = await query(
      `INSERT INTO categories (name, type) 
       VALUES ($1, $2) 
       RETURNING id, name, type, created_at`,
      [name, type]
    );

    res.status(201).json({
      success: true,
      message: 'Category created successfully',
      data: {
        category: result.rows[0]
      }
    });

  } catch (error) {
    console.error('Create category error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create category'
    });
  }
});

/**
 * @route   PUT /api/categories/:id
 * @desc    Оновити категорію
 * @access  Admin only
 */
router.put('/:id', authenticate, requireAdmin, createCategoryValidation, async (req, res) => {
  try {
    const { id } = req.params;
    
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { name, type } = req.body;

    // Перевіряємо чи категорія існує
    const categoryCheck = await query(
      'SELECT id FROM categories WHERE id = $1',
      [id]
    );

    if (categoryCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    // Перевіряємо чи нова назва вже існує
    const existing = await query(
      'SELECT id FROM categories WHERE name = $1 AND id != $2',
      [name, id]
    );

    if (existing.rows.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Category with this name already exists'
      });
    }

    // Оновлюємо
    let updateQuery = 'UPDATE categories SET name = $1';
    let params = [name];
    let paramIndex = 2;

    if (type) {
      updateQuery += `, type = $${paramIndex}`;
      params.push(type);
      paramIndex++;
    }

    updateQuery += ` WHERE id = $${paramIndex} RETURNING id, name, type, created_at`;
    params.push(id);

    const result = await query(updateQuery, params);

    res.json({
      success: true,
      message: 'Category updated successfully',
      data: {
        category: result.rows[0]
      }
    });

  } catch (error) {
    console.error('Update category error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update category'
    });
  }
});

/**
 * @route   DELETE /api/categories/:id
 * @desc    Видалити категорію
 * @access  Admin only
 */
router.delete('/:id', authenticate, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    // Перевіряємо чи категорія існує
    const categoryCheck = await query(
      'SELECT id FROM categories WHERE id = $1',
      [id]
    );

    if (categoryCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }

    // Видаляємо
    await query('DELETE FROM categories WHERE id = $1', [id]);

    res.json({
      success: true,
      message: 'Category deleted successfully'
    }); 

  } catch (error) {
    console.error('Delete category error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete category'
    });
  }
});

module.exports = router;