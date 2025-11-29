# Backend A - Finance Management System

Головний backend для системи управління особистими фінансами.

## 🚀 Технології

- **Node.js** + Express.js
- **PostgreSQL** - база даних
- **JWT** - автентифікація
- **bcrypt** - хешування паролів

## 📋 Функціонал

### Автентифікація
- Реєстрація користувачів
- Вхід/вихід (JWT токени)
- Дві ролі: `admin` і `user`
- Блокування користувачів (admin)

### Управління даними
- **Користувачі**: CRUD операції для admin
- **Категорії**: створення, читання, оновлення, видалення
- **Транзакції**: повний CRUD + статистика для ML

### Безпека
- Хешування паролів (bcrypt)
- JWT токени
- Валідація даних
- CORS налаштування
- Helmet для HTTP заголовків

## 🛠️ Встановлення

### 1. Клонуй репозиторій
```bash
git clone <your-repo>
cd backend-a
```

### 2. Встанови залежності
```bash
npm install
```

### 3. Налаштуй базу даних PostgreSQL

**Локально:**
```bash
# Встанови PostgreSQL
# macOS:
brew install postgresql
brew services start postgresql

# Ubuntu:
sudo apt-get install postgresql
sudo service postgresql start

# Створи базу даних
psql postgres
CREATE DATABASE finance_db;
\q
```

**Або використай безкоштовні онлайн сервіси:**
- [Render PostgreSQL](https://render.com) - безкоштовно
- [Supabase](https://supabase.com) - безкоштовно
- [ElephantSQL](https://www.elephantsql.com) - безкоштовно

### 4. Налаштуй .env файл

Скопіюй `.env.example` → `.env`:
```bash
cp .env.example .env
```

Відредагуй `.env`:
```env
DATABASE_URL=postgresql://username:password@host:5432/finance_db
JWT_SECRET=твій-секретний-ключ-мінімум-32-символи
JWT_EXPIRE=7d
PORT=5000
NODE_ENV=development
FRONTEND_URL=https://example.z1.web.core.windows.net
```

### 5. Ініціалізуй базу даних

```bash
npm run init-db
```

Це створить таблиці та додасть тестові дані:
- **Admin**: `admin@finance.com` / `admin123`
- **User**: `user@finance.com` / `user123`

### 6. Запусти сервер

```bash
# Development режим (з автоперезавантаженням)
npm run dev

# Production режим
npm start
```

Сервер запуститься на `http://localhost:5000`

## 📡 API Endpoints

### Auth (`/api/auth`)
```
POST   /register      - Реєстрація
POST   /login         - Вхід
GET    /me            - Поточний користувач
POST   /logout        - Вихід
```

### Users (`/api/users`) - Admin only
```
GET    /              - Список користувачів
GET    /:id           - Один користувач
PUT    /:id/block     - Блокувати/розблокувати
DELETE /:id           - Видалити користувача
```

### Categories (`/api/categories`)
```
GET    /              - Всі категорії користувача
GET    /:id           - Одна категорія
POST   /              - Створити категорію
PUT    /:id           - Оновити категорію
DELETE /:id           - Видалити категорію
```

### Transactions (`/api/transactions`)
```
GET    /              - Всі транзакції (з фільтрами)
GET    /stats         - Статистика для ML
GET    /:id           - Одна транзакція
POST   /              - Створити транзакцію
PUT    /:id           - Оновити транзакцію
DELETE /:id           - Видалити транзакцію
```

## 🧪 Приклади використання

### 1. Реєстрація
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### 2. Логін
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@finance.com",
    "password": "user123"
  }'
```

Відповідь:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 2,
      "email": "user@finance.com",
      "role": "user"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### 3. Використання токену

Додай токен до кожного запиту:
```bash
curl -X GET http://localhost:5000/api/transactions \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 4. Створити транзакцію
```bash
curl -X POST http://localhost:5000/api/transactions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 150.50,
    "type": "expense",
    "description": "Grocery shopping",
    "date": "2025-01-15",
    "category_id": 1
  }'
```

### 5. Отримати статистику (для ML)
```bash
curl -X GET "http://localhost:5000/api/transactions/stats?date_from=2025-01-01" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🐳 Docker (опціонально)

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 5000
CMD ["node", "server.js"]
```

Запуск:
```bash
docker build -t finance-backend-a .
docker run -p 5000:5000 --env-file .env finance-backend-a
```

## 🚀 Деплой

### Render.com (РЕКОМЕНДОВАНО - безкоштовно)

1. Зареєструйся на [Render.com](https://render.com)
2. Створи **PostgreSQL** базу даних
3. Створи **Web Service**:
   - Build Command: `npm install`
   - Start Command: `npm start`
4. Додай Environment Variables:
   - `DATABASE_URL` (з Render PostgreSQL)
   - `JWT_SECRET`
   - `FRONTEND_URL`
   - `NODE_ENV=production`

### Railway.app (альтернатива)

1. Зареєструйся на [Railway.app](https://railway.app)
2. Створи новий проект
3. Додай PostgreSQL plugin
4. Підключи GitHub репозиторій
5. Додай змінні середовища

## 🔒 Безпека

- ✅ Паролі хешовані (bcrypt, 10 rounds)
- ✅ JWT токени з expiration
- ✅ SQL injection захист (параметризовані запити)
- ✅ CORS налаштований
- ✅ Helmet middleware
- ✅ Валідація вхідних даних
- ✅ Блокування користувачів
- ✅ Role-based access control

## 📊 Структура бази даних

```sql
users
├── id (SERIAL)
├── email (VARCHAR UNIQUE)
├── password_hash (TEXT)
├── role (VARCHAR: 'admin' | 'user')
├── is_blocked (BOOLEAN)
└── created_at (TIMESTAMP)

categories
├── id (SERIAL)
├── name (VARCHAR)
├── user_id (FK → users.id)
└── created_at (TIMESTAMP)

transactions
├── id (SERIAL)
├── amount (NUMERIC)
├── type (VARCHAR: 'income' | 'expense')
├── description (TEXT)
├── date (DATE)
├── user_id (FK → users.id)
├── category_id (FK → categories.id)
└── created_at (TIMESTAMP)
```

## 🐛 Troubleshooting

### Помилка підключення до БД
```
Error: connect ECONNREFUSED 127.0.0.1:5432
```
**Рішення**: Переконайся, що PostgreSQL запущений і `DATABASE_URL` правильний.

### JWT помилки
```
Error: JWT secret not defined
```
**Рішення**: Додай `JWT_SECRET` у `.env` файл.

### CORS помилки
```
Access to fetch at ... has been blocked by CORS policy
```
**Рішення**: Переконайся, що `FRONTEND_URL` у `.env` відповідає твоєму frontend URL.

## 📝 TODO для проекту

- [ ] Rate limiting (захист від DDoS)
- [ ] Email підтвердження
- [ ] Забули пароль?
- [ ] Експорт даних (CSV, PDF)
- [ ] Більше статистики
- [ ] WebSockets для real-time оновлень

## 👥 Автор

Твоя команда - Backend A developer

## 📄 Ліцензія

MIT
