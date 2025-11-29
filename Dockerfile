FROM node:18-alpine

# Встановлюємо робочу директорію
WORKDIR /app

# Копіюємо package files
COPY package*.json ./

# Встановлюємо залежності
RUN npm ci --only=production

# Копіюємо весь код
COPY . .

# Відкриваємо порт
EXPOSE 5000

# Запускаємо сервер
CMD ["node", "server.js"]
