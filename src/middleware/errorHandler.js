// Глобальний обробник помилок
const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  // Помилка валідації від express-validator
  if (err.array) {
    return res.status(400).json({
      success: false,
      message: 'Validation error',
      errors: err.array()
    });
  }

  // PostgreSQL помилки
  if (err.code) {
    // Duplicate entry
    if (err.code === '23505') {
      return res.status(409).json({
        success: false,
        message: 'Resource already exists',
        // detail: err.detail
      });
    }
    
    // Foreign key violation
    if (err.code === '23503') {
      return res.status(400).json({
        success: false,
        message: 'Referenced resource does not exist'
      });
    }
  }

  // Стандартна помилка
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

module.exports = errorHandler;
