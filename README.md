# 💰 Finance Management Backend

A robust RESTful API backend for personal finance management, built with Node.js, Express, and PostgreSQL. Features JWT authentication, role-based access control, and comprehensive transaction management.

[![Node.js](https://img.shields.io/badge/Node.js-18+-green.svg)](https://nodejs.org/)
[![Express](https://img.shields.io/badge/Express-4.18-blue.svg)](https://expressjs.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-blue.svg)](https://www.postgresql.org/)

## ✨ Features

- 🔐 **JWT Authentication** - Secure user authentication with JSON Web Tokens
- 👥 **Role-Based Access Control** - Admin and User roles with different permissions
- 💳 **Transaction Management** - Full CRUD operations for income and expenses
- 📊 **Statistics & Analytics** - Ready for ML integration with detailed financial statistics
- 🏷️ **Category Management** - Organize transactions by custom categories
- 🔒 **User Management** - Admin panel for user blocking/unblocking
- 🌐 **CORS Enabled** - Ready for frontend integration
- 🐳 **Docker Ready** - Easy deployment with Docker support
- 📝 **Comprehensive API Documentation** - Well-documented endpoints

## 🛠️ Tech Stack

- **Runtime:** Node.js 18+
- **Framework:** Express.js
- **Database:** PostgreSQL (Neon serverless)
- **Authentication:** JWT + bcrypt
- **Validation:** express-validator
- **Security:** helmet, cors
- **Logging:** morgan

## 📋 Prerequisites

- Node.js 18 or higher
- PostgreSQL database (or Neon account)
- npm or yarn

## 🚀 Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/irapopovych/finance-backend.git
cd finance-backend
```

### 2. Install dependencies

```bash
npm install
```

### 3. Environment Setup

Create `.env` file in the root directory:

```env
DATABASE_URL=postgresql://user:password@host:5432/database
JWT_SECRET=your-super-secret-jwt-key-change-this
JWT_EXPIRE=7d
NODE_ENV=development
PORT=5000
FRONTEND_URL=http://localhost:3000
```

### 4. Initialize Database

```bash
npm run init-db
```

This will:
- Create all necessary tables (users, categories, transactions)
- Insert test data (2 users, 12 categories, 85 transactions)
- Set up indexes for optimization

### 5. Start the server

**Development:**
```bash
npm run dev
```

**Production:**
```bash
npm start
```

Server will run on `http://localhost:5000`

## 📊 Database Schema

### Users Table
```sql
- id (SERIAL PRIMARY KEY)
- email (VARCHAR UNIQUE)
- password_hash (TEXT)
- role (VARCHAR) - 'admin' or 'user'
- is_blocked (BOOLEAN)
- created_at (TIMESTAMP)
```

### Categories Table
```sql
- id (SERIAL PRIMARY KEY)
- name (VARCHAR)
- user_id (INTEGER FK → users.id)
- created_at (TIMESTAMP)
```

### Transactions Table
```sql
- id (SERIAL PRIMARY KEY)
- amount (NUMERIC)
- type (VARCHAR) - 'income' or 'expense'
- description (TEXT)
- date (DATE)
- user_id (INTEGER FK → users.id)
- category_id (INTEGER FK → categories.id)
- created_at (TIMESTAMP)
```

## 🧪 Test Credentials

The database is initialized with test data:

**User Account:**
- Email: `user@test.com`
- Password: `user123`
- Role: `user`

**Test Data:**
- 12 categories (Salary, Rent, Food, Transport, etc.)
- 85 realistic transactions spanning 3 months (Nov 2024 - Jan 2025)

## 📖 API Documentation

Full API documentation available in [API_REFERENCE.md](API_REFERENCE.md)

**Quick Overview:**

- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login and get JWT token
- `GET /api/auth/me` - Get current user info
- `GET /api/categories` - Get all categories
- `POST /api/categories` - Create category
- `GET /api/transactions` - Get all transactions (with filters)
- `POST /api/transactions` - Create transaction
- `GET /api/transactions/stats` - Get statistics for ML
- `GET /api/users` - Get all users (admin only)
- `PUT /api/users/:id/block` - Block/unblock user (admin only)

## 🔒 Security Features

- ✅ Password hashing with bcrypt (10 rounds)
- ✅ JWT token-based authentication
- ✅ Token expiration (7 days default)
- ✅ CORS protection
- ✅ Helmet security headers
- ✅ SQL injection prevention
- ✅ Input validation and sanitization
- ✅ Role-based access control

## 📈 Statistics Endpoint (ML Ready)

The `/api/transactions/stats` endpoint provides comprehensive financial data perfect for ML predictions:

```json
{
  "overall": {
    "total_income": 10270,
    "total_expense": 4991,
    "balance": 5279,
    "transaction_count": 85
  },
  "by_category": [
    {"category": "Salary", "total": 8600, "count": 3},
    {"category": "Rent", "total": 1590, "count": 3}
  ],
  "monthly": [
    {"month": "2024-11", "income": 3250, "expense": 1428, "balance": 1822},
    {"month": "2024-12", "income": 3550, "expense": 1851, "balance": 1699}
  ]
}
```

## 🌐 Deployment

### Render.com (Recommended)

1. Push code to GitHub
2. Connect repository to Render
3. Set environment variables
4. Deploy!

**Environment Variables on Render:**
- `DATABASE_URL` - Your Neon PostgreSQL URL
- `JWT_SECRET` - Your secret key
- `NODE_ENV` - `production`
- `FRONTEND_URL` - Your frontend URL

### Other Platforms

- Railway.app
- Fly.io
- Heroku
- AWS/Azure/GCP

## 🧪 Testing

```bash
# Test health endpoint
curl http://localhost:5000/health

# Test login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"user123"}'

# Run full test suite (requires backend running)
./test-backend.sh
```

## 📁 Project Structure

```
backend-a/
├── src/
│   ├── config/
│   │   └── database.js          # Database connection
│   ├── middleware/
│   │   ├── auth.js              # JWT authentication
│   │   └── errorHandler.js      # Error handling
│   ├── routes/
│   │   ├── auth.js              # Authentication routes
│   │   ├── categories.js        # Category routes
│   │   ├── transactions.js      # Transaction routes
│   │   └── users.js             # User management routes
│   └── scripts/
│       └── initDatabase.js      # Database initialization
├── server.js                    # Entry point
├── package.json
├── Dockerfile
├── docker-compose.yml
└── .env.example
```

## 🙏 Acknowledgments

- Built with ❤️ using Node.js and Express
- Database hosted on [Neon](https://neon.tech)
- Deployed on [Render](https://render.com)


**God bless! 🙏**
