# 🚀 Безкоштовний деплой Backend A на Render.com

Render.com дає безкоштовно:
- PostgreSQL базу даних (до 1GB)
- Web Service (завмирає після 15 хв неактивності, але пробуджується за 30 сек)

## Крок 1: Підготовка коду

1. Створи GitHub репозиторій
2. Завантаж туди весь код з `/backend-a`

```bash
cd backend-a
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/твій-username/finance-backend-a.git
git push -u origin main
```

## Крок 2: Створи PostgreSQL базу

1. Зайди на [https://render.com](https://render.com)
2. Натисни **"New +"** → **"PostgreSQL"**
3. Заповни:
   - **Name**: `finance-db`
   - **Database**: `finance_db`
   - **User**: `finance_user`
   - **Region**: `Frankfurt (EU Central)` (найближче до України)
   - **Instance Type**: **Free**
4. Натисни **"Create Database"**
5. Дочекайся створення (1-2 хв)
6. **ЗБЕРЕЖИ** `Internal Database URL` - він виглядає так:
   ```
   postgresql://finance_user:password@dpg-xxxxx.frankfurt-postgres.render.com/finance_db
   ```

## Крок 3: Створи Web Service

1. Натисни **"New +"** → **"Web Service"**
2. Підключи свій GitHub репозиторій
3. Заповни:
   - **Name**: `finance-backend-a`
   - **Region**: `Frankfurt (EU Central)`
   - **Branch**: `main`
   - **Root Directory**: (залиш порожнім)
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Instance Type**: **Free**

## Крок 4: Додай Environment Variables

В розділі **Environment** додай:

```
DATABASE_URL = postgresql://... (твій Internal Database URL з кроку 2)
JWT_SECRET = придумай-випадковий-рядок-мінімум-32-символи
JWT_EXPIRE = 7d
NODE_ENV = production
FRONTEND_URL = https://example.z1.web.core.windows.net
PORT = 5000
```

**Як згенерувати JWT_SECRET:**
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## Крок 5: Deploy

1. Натисни **"Create Web Service"**
2. Дочекайся білду (2-3 хв)
3. Твій backend буде доступний на: `https://finance-backend-a.onrender.com`

## Крок 6: Ініціалізуй базу даних

Після першого деплою потрібно створити таблиці.

### Варіант A: Через Render Shell

1. В Render Dashboard → твій Web Service → вкладка **"Shell"**
2. Запусти:
```bash
npm run init-db
```

### Варіант B: Локально через psql

1. Встанови PostgreSQL client
2. Підключись до бази:
```bash
psql "postgresql://finance_user:password@dpg-xxxxx.frankfurt-postgres.render.com/finance_db"
```
3. Скопіюй і вставь SQL з `/src/scripts/initDatabase.js`

## Крок 7: Перевірка

```bash
# Health check
curl https://finance-backend-a.onrender.com/health

# Login
curl -X POST https://finance-backend-a.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@finance.com",
    "password": "user123"
  }'
```

## 🎉 Готово!

Твій Backend A тепер доступний на:
```
https://finance-backend-a.onrender.com
```

**Важливо для фронтенду:**
- Використовуй цей URL як `REACT_APP_API_URL`
- Перший запит після неактивності займе ~30 сек (пробудження)

---

## 📊 Додатково: Моніторинг

В Render Dashboard можеш побачити:
- **Logs** - всі console.log
- **Metrics** - CPU, RAM, requests
- **Events** - історія деплоїв

---

## 🔄 Оновлення коду

Просто push в GitHub - Render автоматично задеплоїть:

```bash
git add .
git commit -m "Update backend"
git push
```

---

## 🐛 Troubleshooting

### Backend не стартує
**Перевірка:**
1. Logs → чи є помилки?
2. Environment Variables → чи всі встановлені?
3. DATABASE_URL → чи правильний?

### База даних не підключається
**Перевірка:**
1. Використай **Internal Database URL**, не External
2. Перевір, що БД створена
3. Перевір username/password

### CORS помилки
**Рішення:**
Переконайся, що `FRONTEND_URL` в Environment Variables відповідає твоєму фронтенду.

---

## 💰 Безкоштовні ліміти Render

- **PostgreSQL**: 1GB storage, 90 днів backup
- **Web Service**: 
  - 750 годин/місяць
  - Засинає після 15 хв неактивності
  - Пробудження ~30 сек

**Tip**: Якщо треба щоб не засинав, можна додати cron job, який пінгує `/health` кожні 10 хвилин.

---

## 🔐 Безпека

✅ Завжди використовуй:
- Складний `JWT_SECRET`
- `NODE_ENV=production`
- HTTPS (Render дає автоматично)
- Правильний `FRONTEND_URL` для CORS

❌ Ніколи не:
- Комітуй `.env` файл
- Шарь `JWT_SECRET`
- Використовуй слабкі паролі для admin

---

## 📞 Контакти

Питання? Звертайся до команди або дивись [Render Docs](https://render.com/docs).
