# API Testing Examples

Використовуй curl або Postman/Insomnia для тестування.

## 1. Health Check

```bash
curl http://localhost:5000/health
```

## 2. AUTH - Реєстрація

```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "password": "securepass123"
  }'
```

## 3. AUTH - Логін

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@finance.com",
    "password": "user123"
  }'
```

**Збережи токен з відповіді!**

```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

## 4. AUTH - Поточний користувач

```bash
TOKEN="ваш-токен-тут"

curl http://localhost:5000/api/auth/me \
  -H "Authorization: Bearer $TOKEN"
```

## 5. CATEGORIES - Отримати всі

```bash
curl http://localhost:5000/api/categories \
  -H "Authorization: Bearer $TOKEN"
```

## 6. CATEGORIES - Створити нову

```bash
curl -X POST http://localhost:5000/api/categories \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Health"
  }'
```

## 7. CATEGORIES - Видалити

```bash
curl -X DELETE http://localhost:5000/api/categories/7 \
  -H "Authorization: Bearer $TOKEN"
```

## 8. TRANSACTIONS - Створити expense

```bash
curl -X POST http://localhost:5000/api/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 45.99,
    "type": "expense",
    "description": "Dinner at restaurant",
    "date": "2025-01-20",
    "category_id": 1
  }'
```

## 9. TRANSACTIONS - Створити income

```bash
curl -X POST http://localhost:5000/api/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 3500,
    "type": "income",
    "description": "Monthly salary",
    "date": "2025-01-25",
    "category_id": 5
  }'
```

## 10. TRANSACTIONS - Отримати всі

```bash
curl http://localhost:5000/api/transactions \
  -H "Authorization: Bearer $TOKEN"
```

## 11. TRANSACTIONS - Фільтр по типу (тільки витрати)

```bash
curl "http://localhost:5000/api/transactions?type=expense" \
  -H "Authorization: Bearer $TOKEN"
```

## 12. TRANSACTIONS - Фільтр по даті

```bash
curl "http://localhost:5000/api/transactions?date_from=2025-01-01&date_to=2025-01-31" \
  -H "Authorization: Bearer $TOKEN"
```

## 13. TRANSACTIONS - Статистика (для ML)

```bash
curl http://localhost:5000/api/transactions/stats \
  -H "Authorization: Bearer $TOKEN"
```

## 14. TRANSACTIONS - Оновити

```bash
curl -X PUT http://localhost:5000/api/transactions/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 55.00,
    "type": "expense",
    "description": "Updated description",
    "date": "2025-01-20",
    "category_id": 1
  }'
```

## 15. TRANSACTIONS - Видалити

```bash
curl -X DELETE http://localhost:5000/api/transactions/1 \
  -H "Authorization: Bearer $TOKEN"
```

## ADMIN ENDPOINTS

Спочатку залогінься як admin:

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@finance.com",
    "password": "admin123"
  }'
```

## 16. USERS - Список всіх (admin only)

```bash
ADMIN_TOKEN="токен-адміна"

curl http://localhost:5000/api/users \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

## 17. USERS - Заблокувати користувача (admin only)

```bash
curl -X PUT http://localhost:5000/api/users/2/block \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "is_blocked": true
  }'
```

## 18. USERS - Розблокувати користувача (admin only)

```bash
curl -X PUT http://localhost:5000/api/users/2/block \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "is_blocked": false
  }'
```

## 19. USERS - Видалити користувача (admin only)

```bash
curl -X DELETE http://localhost:5000/api/users/3 \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

---

## Очікувані помилки для тестування

### 401 Unauthorized (немає токену)
```bash
curl http://localhost:5000/api/transactions
```

### 401 Unauthorized (невалідний токен)
```bash
curl http://localhost:5000/api/transactions \
  -H "Authorization: Bearer invalid-token"
```

### 403 Forbidden (не admin)
```bash
curl http://localhost:5000/api/users \
  -H "Authorization: Bearer $TOKEN"
```

### 404 Not Found
```bash
curl http://localhost:5000/api/transactions/99999 \
  -H "Authorization: Bearer $TOKEN"
```

### 409 Conflict (duplicate email)
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@finance.com",
    "password": "password123"
  }'
```
