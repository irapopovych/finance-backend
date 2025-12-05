require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

// Routes
const authRoutes = require('./src/routes/auth');
const userRoutes = require('./src/routes/users');
const categoryRoutes = require('./src/routes/categories');
const transactionRoutes = require('./src/routes/transactions');
const predictionsRoutes = require('./src/routes/predictions');

// Middleware
const errorHandler = require('./src/middleware/errorHandler');

const app = express();

// Security middleware
app.use(helmet());

// CORS - дозволяємо запити з кількох origins
const allowedOrigins = [
  'http://localhost:5173',  // для локальної розробки
  'http://localhost:5174',  // на всяк випадок
  process.env.FRONTEND_URL,  // твій реальний фронтенд
  process.env.ML_BACKEND_URL // ML backend для отримання даних
].filter(Boolean); // видаляє undefined якщо не встановлена

app.use(cors({
  origin: function (origin, callback) {
    // Дозволяємо запити без origin (наприклад, Postman)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true
}));

// Body parser
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'Backend A - Finance Management'
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/predict', predictionsRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ 
    success: false, 
    message: 'Route not found' 
  });
});

// Error handler (має бути останнім)
app.use(errorHandler);

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`🚀 Backend A running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV}`);
  console.log(`🔗 Allowed origins:`, allowedOrigins);
});