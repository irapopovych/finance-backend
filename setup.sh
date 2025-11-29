#!/bin/bash

echo "🚀 Finance Backend A - Quick Start Script"
echo "=========================================="

# Перевіряємо наявність Node.js
if ! command -v node &> /dev/null
then
    echo "❌ Node.js не встановлений. Завантажте з https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js $(node --version) detected"

# Перевіряємо наявність npm
if ! command -v npm &> /dev/null
then
    echo "❌ npm не встановлений"
    exit 1
fi

echo "✅ npm $(npm --version) detected"

# Встановлюємо залежності
echo ""
echo "📦 Installing dependencies..."
npm install

# Перевіряємо .env файл
if [ ! -f .env ]; then
    echo ""
    echo "⚠️  .env file not found!"
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo "✅ .env file created"
    echo ""
    echo "⚠️  IMPORTANT: Edit .env file and set:"
    echo "   - DATABASE_URL (your PostgreSQL connection string)"
    echo "   - JWT_SECRET (random string, min 32 characters)"
    echo ""
    read -p "Press Enter after you've configured .env file..."
fi

# Пропонуємо ініціалізувати БД
echo ""
read -p "Do you want to initialize the database now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "🔨 Initializing database..."
    npm run init-db
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "To start the server in development mode:"
echo "  npm run dev"
echo ""
echo "To start in production mode:"
echo "  npm start"
echo ""
echo "📖 Check README.md for more information"
echo "🧪 Check API_EXAMPLES.md for API testing examples"
