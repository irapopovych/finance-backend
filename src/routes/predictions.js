const express = require('express');
const axios = require('axios');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

const ML_BACKEND_URL = process.env.ML_BACKEND_URL || 'https://finalfinallll-bkfqhebrgubjf5d7.italynorth-01.azurewebsites.net';

/**
 * @route   POST /api/predict
 * @desc    Отримати ML прогноз для користувача
 * @access  Private
 */
router.post('/', authenticate, async (req, res) => {
  try {
    const { model_type = 'linear' } = req.body;
    
    console.log(`Requesting prediction for user ${req.user.id} with model ${model_type}`);
    
    // Викликаємо ML backend (передаємо тільки user_id в URL)
    const mlResponse = await axios.post(
      `${ML_BACKEND_URL}/predict/${req.user.id}?model_type=${model_type}`,
      {}, // порожній body
      { 
        timeout: 30000, // 30 секунд
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    console.log(`Prediction successful for user ${req.user.id}`);

    res.json({
      success: true,
      data: mlResponse.data
    });

  } catch (error) {
    console.error('ML prediction error:', error.response?.data || error.message);
    
    // ML backend повернув 400 (не вистачає даних)
    if (error.response?.status === 400) {
      return res.status(400).json({
        success: false,
        message: error.response.data.detail || 'Not enough transaction history for prediction'
      });
    }
    
    // ML backend повернув 502 (не може підключитись до твого API)
    if (error.response?.status === 502) {
      return res.status(502).json({
        success: false,
        message: 'ML service cannot connect to transaction service. Please try again later.'
      });
    }
    
    // Timeout
    if (error.code === 'ECONNABORTED') {
      return res.status(504).json({
        success: false,
        message: 'ML prediction timeout. Please try again.'
      });
    }
    
    // ML backend не доступний
    if (error.code === 'ECONNREFUSED' || error.code === 'ETIMEDOUT') {
      return res.status(503).json({
        success: false,
        message: 'ML service temporarily unavailable'
      });
    }

    // Інша помилка
    res.status(500).json({
      success: false,
      message: 'Failed to generate prediction'
    });
  }
});

/**
 * @route   GET /api/predict/history
 * @desc    Отримати історію прогнозів користувача
 * @access  Private
 */
router.get('/history', authenticate, async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    
    console.log(`Fetching prediction history for user ${req.user.id}`);
    
    const mlResponse = await axios.get(
      `${ML_BACKEND_URL}/predictions/${req.user.id}?limit=${limit}`,
      { 
        timeout: 10000,
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    res.json({
      success: true,
      data: mlResponse.data
    });

  } catch (error) {
    console.error('ML history error:', error.message);
    
    if (error.code === 'ECONNREFUSED' || error.code === 'ETIMEDOUT') {
      return res.status(503).json({
        success: false,
        message: 'ML service temporarily unavailable'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Failed to fetch prediction history'
    });
  }
});

module.exports = router;