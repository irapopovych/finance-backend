# 📖 Finance Management API Reference

Complete API documentation for Finance Management Backend.

---

## 📑 Quick Navigation

### Authentication
- [Register](#register) - `POST /api/auth/register`
- [Login](#login) - `POST /api/auth/login`
- [Get Current User](#get-current-user) - `GET /api/auth/me`
- [Logout](#logout) - `POST /api/auth/logout`

### Categories
- [Get All Categories](#get-all-categories) - `GET /api/categories`
- [Get Category by ID](#get-category-by-id) - `GET /api/categories/:id`
- [Create Category](#create-category) - `POST /api/categories`
- [Update Category](#update-category) - `PUT /api/categories/:id`
- [Delete Category](#delete-category) - `DELETE /api/categories/:id`

### Transactions
- [Get All Transactions](#get-all-transactions) - `GET /api/transactions`
- [Get Transaction by ID](#get-transaction-by-id) - `GET /api/transactions/:id`
- [Create Transaction](#create-transaction) - `POST /api/transactions`
- [Update Transaction](#update-transaction) - `PUT /api/transactions/:id`
- [Delete Transaction](#delete-transaction) - `DELETE /api/transactions/:id`
- [Get Statistics](#get-statistics) - `GET /api/transactions/stats` ⭐ **ML Ready**

### Admin (Admin Role Required)
- [Get All Users](#get-all-users) - `GET /api/users`
- [Get User by ID](#get-user-by-id) - `GET /api/users/:id`
- [Block/Unblock User](#blockunblock-user) - `PUT /api/users/:id/block`
- [Delete User](#delete-user) - `DELETE /api/users/:id`

### Utility
- [Health Check](#health-check) - `GET /health`

---

## 🔐 Authentication

**How to authenticate:**
1. Call `/api/auth/login` with credentials
2. Receive JWT token in response
3. Add token to all subsequent requests:
   ```
   Headers: Authorization: Bearer {your-token}
   ```

**Token expires in:** 7 days

**Test Credentials:**
- **User:** `user@test.com` / `user123`

---

## 🚀 Endpoints

---

## Health Check

### GET /health

Check if API is running (no authentication required)

**Response:**
```json
{
  "status": "OK",
  "timestamp": "2025-11-29T18:30:00.000Z",
  "service": "Backend A - Finance Management"
}
```

---

## 🔐 AUTHENTICATION

---

### Register

**`POST /api/auth/register`**

Create a new user account

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Validation:**
- Email: valid format, unique
- Password: minimum 6 characters

**Success Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": 3,
      "email": "user@example.com",
      "role": "user"
    }
  }
}
```

**Error (400):**
```json
{
  "success": false,
  "message": "User with this email already exists"
}
```

---

### Login

**`POST /api/auth/login`**

Login and receive JWT token

**Request:**
```json
{
  "email": "user@test.com",
  "password": "user123"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 2,
      "email": "user@test.com",
      "role": "user"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error (401):**
```json
{
  "success": false,
  "message": "Invalid email or password"
}
```

**Error (403 - Blocked User):**
```json
{
  "success": false,
  "message": "Your account has been blocked. Please contact administrator."
}
```

---

### Get Current User

**`GET /api/auth/me`**

Get authenticated user information

**Headers:**
```
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 2,
      "email": "user@test.com",
      "role": "user",
      "is_blocked": false,
      "created_at": "2025-01-15T10:00:00.000Z"
    }
  }
}
```

---

### Logout

**`POST /api/auth/logout`**

Logout user

**Headers:**
```
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## 📂 CATEGORIES

All category endpoints require authentication.

---

### Get All Categories

**`GET /api/categories`**

Get all categories for authenticated user

**Headers:**
```
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "categories": [
      {
        "id": 1,
        "name": "Salary",
        "user_id": 2,
        "created_at": "2025-01-15T10:00:00.000Z"
      },
      {
        "id": 2,
        "name": "Rent",
        "user_id": 2,
        "created_at": "2025-01-15T10:00:00.000Z"
      }
    ]
  }
}
```

---

### Get Category by ID

**`GET /api/categories/:id`**

Get specific category

**URL Params:**
- `id` - Category ID

**Headers:**
```
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "category": {
      "id": 1,
      "name": "Salary",
      "user_id": 2,
      "created_at": "2025-01-15T10:00:00.000Z"
    }
  }
}
```

---

### Create Category

**`POST /api/categories`**

Create new category

**Headers:**
```
Authorization: Bearer {token}
```

**Request:**
```json
{
  "name": "Groceries"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Category created successfully",
  "data": {
    "category": {
      "id": 13,
      "name": "Groceries",
      "user_id": 2,
      "created_at": "2025-01-15T10:30:00.000Z"
    }
  }
}
```

---

### Update Category

**`PUT /api/categories/:id`**

Update category

**URL Params:**
- `id` - Category ID

**Headers:**
```
Authorization: Bearer {token}
```

**Request:**
```json
{
  "name": "Updated Name"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Category updated successfully",
  "data": {
    "category": {
      "id": 13,
      "name": "Updated Name",
      "user_id": 2,
      "created_at": "2025-01-15T10:30:00.000Z"
    }
  }
}
```

---

### Delete Category

**`DELETE /api/categories/:id`**

Delete category

**URL Params:**
- `id` - Category ID

**Headers:**
```
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Category deleted successfully"
}
```

---

## 💰 TRANSACTIONS

All transaction endpoints require authentication.

---

### Get All Transactions

**`GET /api/transactions`**

Get all transactions with optional filters

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters (Optional):**

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `type` | string | Filter by type | `expense` or `income` |
| `category_id` | integer | Filter by category | `1` |
| `date_from` | date | Start date (YYYY-MM-DD) | `2024-11-01` |
| `date_to` | date | End date (YYYY-MM-DD) | `2024-11-30` |

**Examples:**
```
GET /api/transactions
GET /api/transactions?type=expense
GET /api/transactions?date_from=2024-11-01&date_to=2024-11-30
GET /api/transactions?category_id=1&type=income
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "id": 1,
        "amount": "3000.00",
        "type": "income",
        "description": "Monthly salary",
        "date": "2025-01-01",
        "user_id": 2,
        "category_id": 1,
        "category_name": "Salary",
        "created_at": "2025-01-15T10:00:00.000Z"
      }
    ]
  }
}
```

---

### Get Transaction by ID

**`GET /api/transactions/:id`**

Get specific transaction

**URL Params:**
- `id` - Transaction ID

**Headers:**
```
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "transaction": {
      "id": 1,
      "amount": "3000.00",
      "type": "income",
      "description": "Monthly salary",
      "date": "2025-01-01",
      "user_id": 2,
      "category_id": 1,
      "category_name": "Salary",
      "created_at": "2025-01-15T10:00:00.000Z"
    }
  }
}
```

---

### Create Transaction

**`POST /api/transactions`**

Create new transaction

**Headers:**
```
Authorization: Bearer {token}
```

**Request:**
```json
{
  "amount": 150.50,
  "type": "expense",
  "description": "Grocery shopping",
  "date": "2025-01-15",
  "category_id": 3
}
```

**Field Validation:**

| Field | Required | Type | Rules |
|-------|----------|------|-------|
| `amount` | ✅ Yes | number | Must be positive |
| `type` | ✅ Yes | string | `income` or `expense` |
| `description` | ❌ No | string | Any text |
| `date` | ✅ Yes | string | Format: YYYY-MM-DD |
| `category_id` | ✅ Yes | integer | Must exist |

**Success Response (201):**
```json
{
  "success": true,
  "message": "Transaction created successfully",
  "data": {
    "transaction": {
      "id": 86,
      "amount": "150.50",
      "type": "expense",
      "description": "Grocery shopping",
      "date": "2025-01-15",
      "user_id": 2,
      "category_id": 3,
      "created_at": "2025-01-15T11:00:00.000Z"
    }
  }
}
```

---

### Update Transaction

**`PUT /api/transactions/:id`**

Update transaction

**URL Params:**
- `id` - Transaction ID

**Headers:**
```
Authorization: Bearer {token}
```

**Request:**
```json
{
  "amount": 200.00,
  "type": "expense",
  "description": "Updated description",
  "date": "2025-01-16",
  "category_id": 3
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Transaction updated successfully",
  "data": {
    "transaction": {
      "id": 86,
      "amount": "200.00",
      "type": "expense",
      "description": "Updated description",
      "date": "2025-01-16",
      "user_id": 2,
      "category_id": 3,
      "created_at": "2025-01-15T11:00:00.000Z"
    }
  }
}
```

---

### Delete Transaction

**`DELETE /api/transactions/:id`**

Delete transaction

**URL Params:**
- `id` - Transaction ID

**Headers:**
```
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Transaction deleted successfully"
}
```

---

### Get Statistics

**`GET /api/transactions/stats`** ⭐ **Perfect for ML!**

Get comprehensive financial statistics

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters (Optional):**

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `date_from` | date | Start date (YYYY-MM-DD) | `2024-11-01` |
| `date_to` | date | End date (YYYY-MM-DD) | `2024-12-31` |

**Examples:**
```
GET /api/transactions/stats
GET /api/transactions/stats?date_from=2024-11-01&date_to=2024-12-31
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "overall": {
      "total_income": "10270.00",
      "total_expense": "4991.00",
      "balance": "5279.00",
      "transaction_count": 85
    },
    "by_category": [
      {
        "category_id": 1,
        "category_name": "Salary",
        "total_amount": "8600.00",
        "transaction_count": 3,
        "percentage": 83.75
      },
      {
        "category_id": 4,
        "category_name": "Rent",
        "total_amount": "1590.00",
        "transaction_count": 3,
        "percentage": 31.82
      }
    ],
    "monthly": [
      {
        "month": "2024-11",
        "total_income": "3250.00",
        "total_expense": "1428.00",
        "balance": "1822.00",
        "transaction_count": 24
      },
      {
        "month": "2024-12",
        "total_income": "3550.00",
        "total_expense": "1851.00",
        "balance": "1699.00",
        "transaction_count": 28
      },
      {
        "month": "2025-01",
        "total_income": "3520.00",
        "total_expense": "1712.00",
        "balance": "1808.00",
        "transaction_count": 33
      }
    ]
  }
}
```

**Use Cases:**
- 📈 ML predictions and forecasting
- 📊 Budget analysis
- 📉 Trend visualization
- 📑 Financial reports

---

## 👨‍💼 ADMIN ENDPOINTS

**⚠️ All admin endpoints require admin role**

---

### Get All Users

**`GET /api/users`**

Get list of all users (admin only)

**Headers:**
```
Authorization: Bearer {admin-token}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": 1,
        "email": "admin@pf.com",
        "role": "admin",
        "is_blocked": false,
        "created_at": "2025-01-15T10:00:00.000Z"
      },
      {
        "id": 2,
        "email": "user@test.com",
        "role": "user",
        "is_blocked": false,
        "created_at": "2025-01-15T10:00:00.000Z"
      }
    ]
  }
}
```

**Error (403):**
```json
{
  "success": false,
  "message": "Access denied. Admin role required."
}
```

---

### Get User by ID

**`GET /api/users/:id`**

Get specific user details (admin only)

**URL Params:**
- `id` - User ID

**Headers:**
```
Authorization: Bearer {admin-token}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 2,
      "email": "user@test.com",
      "role": "user",
      "is_blocked": false,
      "created_at": "2025-01-15T10:00:00.000Z"
    }
  }
}
```

---

### Block/Unblock User

**`PUT /api/users/:id/block`**

Block or unblock a user (admin only)

**URL Params:**
- `id` - User ID

**Headers:**
```
Authorization: Bearer {admin-token}
```

**Request:**
```json
{
  "is_blocked": true
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "User blocked successfully",
  "data": {
    "user": {
      "id": 2,
      "email": "user@test.com",
      "is_blocked": true
    }
  }
}
```

**Note:** Blocked users cannot login. Existing tokens remain valid until expiration.

---

### Delete User

**`DELETE /api/users/:id`**

Delete a user (admin only)

**URL Params:**
- `id` - User ID

**Headers:**
```
Authorization: Bearer {admin-token}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "User deleted successfully"
}
```

**⚠️ Warning:** Deleting a user also deletes all their categories and transactions (CASCADE).

---

## ⚠️ Error Responses

### Standard Error Format

```json
{
  "success": false,
  "message": "Error description"
}
```

### HTTP Status Codes

| Code | Meaning | When |
|------|---------|------|
| 200 | OK | Request successful |
| 201 | Created | Resource created |
| 400 | Bad Request | Validation error |
| 401 | Unauthorized | Missing/invalid token |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 500 | Server Error | Internal error |

### Common Errors

**No Token:**
```json
{
  "success": false,
  "message": "No token provided"
}
```

**Invalid Token:**
```json
{
  "success": false,
  "message": "Invalid token"
}
```

**Expired Token:**
```json
{
  "success": false,
  "message": "Token expired"
}
```

**Not Admin:**
```json
{
  "success": false,
  "message": "Access denied. Admin role required."
}
```

**Blocked User:**
```json
{
  "success": false,
  "message": "Your account has been blocked. Please contact administrator."
}
```

**Validation Error:**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Email must be a valid email address"
    }
  ]
}
```

---

## 📌 Important Notes

### Date Format
All dates must be in **YYYY-MM-DD** format
- ✅ Correct: `2025-01-15`
- ❌ Wrong: `15/01/2025`, `01-15-2025`

### Amount Format
All amounts are numbers with 2 decimal places
- ✅ Correct: `150.50`, `1000.00`, `99.99`
- ❌ Wrong: `"150.50"` (string), `150` (no decimals)

### Token Expiration
JWT tokens expire after **7 days**. After expiration, user must login again.

### CORS
CORS is configured for: `http://localhost:3000`

For production frontend, update `FRONTEND_URL` environment variable.

### Cascade Deletion
- Deleting a **user** → deletes all their categories and transactions
- Deleting a **category** → sets `category_id` to NULL in transactions

---

## 🧪 Testing Tools

Recommended tools for testing:
- **Postman** - Visual API client
- **Thunder Client** - VS Code extension
- **curl** - Command line
- **Insomnia** - API client

### Quick Test with curl

```bash
# Health check
curl http://localhost:5000/health

# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"user123"}'

# Get transactions (replace TOKEN)
curl http://localhost:5000/api/transactions \
  -H "Authorization: Bearer TOKEN"
```


---

**Happy coding! 🚀**

**God bless! 🙏**
