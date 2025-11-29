# 🎯 ШВИДКИЙ СТАРТ - Finance Backend A

## ✅ Що вже готово

✅ Node.js + Express сервер  
✅ PostgreSQL база даних (схема)  
✅ JWT автентифікація  
✅ Ролі: admin та user  
✅ CRUD для користувачів, категорій, транзакцій  
✅ Валідація даних  
✅ Блокування користувачів  
✅ Статистика для ML  
✅ Docker підтримка  
✅ Готовий для деплою  

## 🚀 Як запустити локально (3 хвилини)

### 1. Встанови PostgreSQL

**macOS:**
```bash
brew install postgresql
brew services start postgresql
createdb finance_db
```

**Ubuntu/Debian:**
```bash
sudo apt-get install postgresql
sudo service postgresql start
sudo -u postgres createdb finance_db
```

**Windows:**
Завантаж з [postgresql.org](https://www.postgresql.org/download/windows/)

### 2. Налаштуй проект

```bash
cd backend-a

# Встанови залежності
npm install

# Скопіюй .env
cp .env.example .env

# Відредагуй .env - встанови DATABASE_URL
nano .env  # або будь-який редактор
```

**Приклад .env:**
```env
DATABASE_URL=postgresql://localhost:5432/finance_db
JWT_SECRET=super-secret-key-change-this-min-32-characters-long
JWT_EXPIRE=7d
PORT=5000
NODE_ENV=development
FRONTEND_URL=http://localhost:3000
```

### 3. Ініціалізуй базу

```bash
npm run init-db
```

Це створить:
- Таблиці (users, categories, transactions)
- Admin користувача: `admin@finance.com` / `admin123`
- Тестового user: `user@finance.com` / `user123`
- Початкові категорії та транзакції

### 4. Запусти сервер

```bash
# Development режим
npm run dev

# Або production
npm start
```

Сервер запуститься на `http://localhost:5000`

### 5. Перевір

```bash
# Health check
curl http://localhost:5000/health

# Login
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@finance.com","password":"user123"}'
```

## 🐳 Або через Docker (ще простіше)

```bash
cd backend-a

# Запусти все (PostgreSQL + Backend)
docker-compose up -d

# Ініціалізуй БД
docker-compose exec backend-a npm run init-db

# Переглянь логи
docker-compose logs -f
```

Готово! Працює на `http://localhost:5000`

## 📡 API Endpoints

Повний список в `API_EXAMPLES.md`, але основні:

```
POST /api/auth/register      - Реєстрація
POST /api/auth/login         - Логін
GET  /api/auth/me            - Поточний користувач

GET  /api/categories         - Категорії
POST /api/categories         - Створити категорію

GET  /api/transactions       - Транзакції
POST /api/transactions       - Створити транзакцію
GET  /api/transactions/stats - Статистика (для ML)

GET  /api/users (admin)      - Список користувачів
PUT  /api/users/:id/block    - Заблокувати
```

## 🌐 Деплой на Render.com (безкоштовно)

Детальні інструкції в `DEPLOYMENT.md`

**Швидкий варіант:**

1. Push код на GitHub
2. Зайди на [render.com](https://render.com)
3. Створи PostgreSQL базу
4. Створи Web Service з GitHub repo
5. Додай environment variables
6. Deploy автоматично!

Твій backend буде на: `https://твоє-ім'я.onrender.com`

## 📁 Структура проекту

```
backend-a/
├── src/
│   ├── config/
│   │   └── database.js          # PostgreSQL підключення
│   ├── middleware/
│   │   ├── auth.js              # JWT перевірка
│   │   └── errorHandler.js      # Обробка помилок
│   ├── routes/
│   │   ├── auth.js              # Реєстрація/логін
│   │   ├── users.js             # CRUD користувачів (admin)
│   │   ├── categories.js        # CRUD категорій
│   │   └── transactions.js      # CRUD транзакцій + stats
│   └── scripts/
│       └── initDatabase.js      # Ініціалізація БД
├── .env.example                 # Приклад конфігурації
├── server.js                    # Головний файл
├── package.json                 # Залежності
├── Dockerfile                   # Docker образ
├── docker-compose.yml           # Локальне тестування
├── README.md                    # Повна документація
├── DEPLOYMENT.md                # Інструкції деплою
└── API_EXAMPLES.md              # Приклади API
```

## 🎓 Для команди

### Frontend розробник
- Використовуй `http://localhost:5000` для API
- Після деплою змінь на `https://твій-backend.onrender.com`
- Всі endpoints в `API_EXAMPLES.md`
- JWT токен зберігай в localStorage
- Додавай токен в header: `Authorization: Bearer TOKEN`

### ML розробник
- Дані для навчання: `GET /api/transactions/stats`
- Отримаєш:
  - Загальну статистику (income/expense)
  - Статистику по категоріях
  - Помісячну статистику (для предикції)
- Формат JSON, легко парсити в Python

### Docker розробник
- `Dockerfile` готовий
- `docker-compose.yml` готовий
- Додай Frontend та ML backend до compose
- Приклад в коментарях файлу

## 🔐 Тестові користувачі

```
Admin:
  Email: admin@finance.com
  Password: admin123
  
User:
  Email: user@finance.com
  Password: user123
```

## ❓ Що далі?

1. **Тестуй API** - використовуй `API_EXAMPLES.md`
2. **Підключи Frontend** - POST/GET запити з токенами
3. **Підключи ML** - візьми дані з `/stats`
4. **Deploy** - використовуй `DEPLOYMENT.md`
5. **Docker** - збери все разом в `docker-compose.yml`

## 🐛 Проблеми?

### Не можу підключитись до БД
```
Error: connect ECONNREFUSED
```
**Рішення:** Перевір чи PostgreSQL запущений і DATABASE_URL правильний

### JWT помилки
```
Error: JWT secret not defined
```
**Рішення:** Додай JWT_SECRET у .env (мінімум 32 символи)

### CORS помилки
```
blocked by CORS policy
```
**Рішення:** Встанови FRONTEND_URL у .env на URL твого фронтенду

## 📞 Контакти

Питання? Пиши в команду або дивись документацію:
- `README.md` - повна документація
- `API_EXAMPLES.md` - приклади запитів
- `DEPLOYMENT.md` - деплой інструкції

## 📝 Чекліст для проекту

- [x] Backend A реалізований
- [ ] Frontend підключений
- [ ] ML Backend підключений
- [ ] BPMN діаграма створена
- [ ] Docker compose для всього
- [ ] Deploy на різні платформи
- [ ] Документація завершена

**Успіхів! 🚀**
