require('dotenv').config();
const { pool } = require('../config/database');
const bcrypt = require('bcrypt');

async function initDatabase() {
  const client = await pool.connect();
  
  try {
    console.log('🔨 Starting database initialization...');

    // Видаляємо старі таблиці
    await client.query(`
      DROP TABLE IF EXISTS transactions CASCADE;
      DROP TABLE IF EXISTS categories CASCADE;
      DROP TABLE IF EXISTS users CASCADE;
    `);
    console.log('✅ Old tables dropped');

    // Створюємо таблицю users
    await client.query(`
      CREATE TABLE users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('admin', 'user')),
        is_blocked BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT NOW()
      );
    `);
    console.log('✅ Table "users" created');

    // Створюємо таблицю categories
    await client.query(`
      CREATE TABLE categories (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(name, user_id)
      );
    `);
    console.log('✅ Table "categories" created');

    // Створюємо таблицю transactions
    await client.query(`
      CREATE TABLE transactions (
        id SERIAL PRIMARY KEY,
        amount NUMERIC(10,2) NOT NULL,
        type VARCHAR(10) NOT NULL CHECK (type IN ('income', 'expense')),
        description TEXT,
        date DATE NOT NULL,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT NOW()
      );
    `);
    console.log('✅ Table "transactions" created');

    // Додаємо індекси
    await client.query(`
      CREATE INDEX idx_transactions_user ON transactions(user_id);
      CREATE INDEX idx_transactions_date ON transactions(date);
      CREATE INDEX idx_categories_user ON categories(user_id);
    `);
    console.log('✅ Indexes created');

    // Створюємо admin користувача
    const adminPassword = await bcrypt.hash('admin123', 10);
    await client.query(`
      INSERT INTO users (email, password_hash, role) 
      VALUES ($1, $2, $3)
    `, ['admin@pf.com', adminPassword, 'admin']);
    console.log('✅ Admin user created (email: admin@pf.com, password: admin123)');

    // Створюємо тестового користувача
    const userPassword = await bcrypt.hash('user123', 10);
    const userResult = await client.query(`
      INSERT INTO users (email, password_hash, role) 
      VALUES ($1, $2, $3) RETURNING id
    `, ['user@test.com', userPassword, 'user']);
    const userId = userResult.rows[0].id;
    console.log('✅ Test user created (email: user@test.com, password: user123)');

    // Створюємо категорії (розширений список)
    const categories = [
      'Salary', 'Freelance', 'Other Income',  // Income categories
      'Rent', 'Utilities', 'Food', 'Transport', 'Entertainment', 
      'Healthcare', 'Shopping', 'Education', 'Other'  // Expense categories
    ];
    
    for (const category of categories) {
      await client.query(`
        INSERT INTO categories (name, user_id) 
        VALUES ($1, $2)
      `, [category, userId]);
    }
    console.log(`✅ ${categories.length} categories created`);

    // Реалістичні транзакції за 3 місяці (листопад 2024 - січень 2025)
    
    // === ЛИСТОПАД 2024 ===
    const novemberTransactions = [
      // Income
      { amount: 2800, type: 'income', desc: 'Monthly salary', date: '2024-11-01', cat: 'Salary' },
      { amount: 450, type: 'income', desc: 'Freelance project', date: '2024-11-15', cat: 'Freelance' },
      
      // Fixed expenses
      { amount: 520, type: 'expense', desc: 'Rent payment', date: '2024-11-02', cat: 'Rent' },
      { amount: 85, type: 'expense', desc: 'Electricity bill', date: '2024-11-05', cat: 'Utilities' },
      { amount: 45, type: 'expense', desc: 'Internet', date: '2024-11-05', cat: 'Utilities' },
      { amount: 32, type: 'expense', desc: 'Water bill', date: '2024-11-05', cat: 'Utilities' },
      
      // Food
      { amount: 85.50, type: 'expense', desc: 'Grocery shopping', date: '2024-11-03', cat: 'Food' },
      { amount: 67.20, type: 'expense', desc: 'Supermarket', date: '2024-11-10', cat: 'Food' },
      { amount: 92.80, type: 'expense', desc: 'Weekly groceries', date: '2024-11-17', cat: 'Food' },
      { amount: 73.40, type: 'expense', desc: 'Food shopping', date: '2024-11-24', cat: 'Food' },
      { amount: 28.50, type: 'expense', desc: 'Restaurant lunch', date: '2024-11-12', cat: 'Food' },
      { amount: 42.00, type: 'expense', desc: 'Pizza delivery', date: '2024-11-19', cat: 'Food' },
      
      // Transport
      { amount: 45.00, type: 'expense', desc: 'Gas station', date: '2024-11-06', cat: 'Transport' },
      { amount: 38.50, type: 'expense', desc: 'Fuel', date: '2024-11-20', cat: 'Transport' },
      { amount: 15.00, type: 'expense', desc: 'Bus tickets', date: '2024-11-14', cat: 'Transport' },
      
      // Entertainment
      { amount: 65.00, type: 'expense', desc: 'Concert tickets', date: '2024-11-08', cat: 'Entertainment' },
      { amount: 23.50, type: 'expense', desc: 'Cinema', date: '2024-11-16', cat: 'Entertainment' },
      { amount: 18.00, type: 'expense', desc: 'Netflix subscription', date: '2024-11-01', cat: 'Entertainment' },
      
      // Shopping
      { amount: 120.00, type: 'expense', desc: 'Winter jacket', date: '2024-11-11', cat: 'Shopping' },
      { amount: 45.90, type: 'expense', desc: 'Shoes', date: '2024-11-22', cat: 'Shopping' },
      
      // Healthcare
      { amount: 35.00, type: 'expense', desc: 'Pharmacy', date: '2024-11-13', cat: 'Healthcare' },
      
      // Other
      { amount: 25.00, type: 'expense', desc: 'Phone credit', date: '2024-11-07', cat: 'Other' },
    ];

    // === ГРУДЕНЬ 2024 ===
    const decemberTransactions = [
      // Income
      { amount: 2800, type: 'income', desc: 'Monthly salary', date: '2024-12-01', cat: 'Salary' },
      { amount: 650, type: 'income', desc: 'Freelance web project', date: '2024-12-18', cat: 'Freelance' },
      { amount: 100, type: 'income', desc: 'Christmas bonus', date: '2024-12-20', cat: 'Other Income' },
      
      // Fixed expenses
      { amount: 520, type: 'expense', desc: 'Rent payment', date: '2024-12-02', cat: 'Rent' },
      { amount: 92, type: 'expense', desc: 'Electricity bill', date: '2024-12-05', cat: 'Utilities' },
      { amount: 45, type: 'expense', desc: 'Internet', date: '2024-12-05', cat: 'Utilities' },
      { amount: 28, type: 'expense', desc: 'Water bill', date: '2024-12-05', cat: 'Utilities' },
      
      // Food
      { amount: 98.60, type: 'expense', desc: 'Grocery shopping', date: '2024-12-04', cat: 'Food' },
      { amount: 112.30, type: 'expense', desc: 'Supermarket', date: '2024-12-11', cat: 'Food' },
      { amount: 88.90, type: 'expense', desc: 'Weekly groceries', date: '2024-12-18', cat: 'Food' },
      { amount: 125.40, type: 'expense', desc: 'Christmas food shopping', date: '2024-12-23', cat: 'Food' },
      { amount: 35.00, type: 'expense', desc: 'Restaurant', date: '2024-12-07', cat: 'Food' },
      { amount: 48.50, type: 'expense', desc: 'Dinner out', date: '2024-12-14', cat: 'Food' },
      { amount: 62.00, type: 'expense', desc: 'Christmas dinner', date: '2024-12-25', cat: 'Food' },
      
      // Transport
      { amount: 50.00, type: 'expense', desc: 'Gas station', date: '2024-12-08', cat: 'Transport' },
      { amount: 42.30, type: 'expense', desc: 'Fuel', date: '2024-12-22', cat: 'Transport' },
      { amount: 18.00, type: 'expense', desc: 'Parking', date: '2024-12-15', cat: 'Transport' },
      
      // Entertainment
      { amount: 85.00, type: 'expense', desc: 'New Year party tickets', date: '2024-12-28', cat: 'Entertainment' },
      { amount: 18.00, type: 'expense', desc: 'Netflix', date: '2024-12-01', cat: 'Entertainment' },
      { amount: 45.00, type: 'expense', desc: 'Theater', date: '2024-12-10', cat: 'Entertainment' },
      
      // Shopping (Christmas!)
      { amount: 180.00, type: 'expense', desc: 'Christmas gifts for family', date: '2024-12-16', cat: 'Shopping' },
      { amount: 95.50, type: 'expense', desc: 'Christmas decorations', date: '2024-12-06', cat: 'Shopping' },
      { amount: 67.00, type: 'expense', desc: 'Secret Santa gift', date: '2024-12-19', cat: 'Shopping' },
      
      // Healthcare
      { amount: 28.50, type: 'expense', desc: 'Vitamins', date: '2024-12-09', cat: 'Healthcare' },
      
      // Other
      { amount: 25.00, type: 'expense', desc: 'Phone credit', date: '2024-12-03', cat: 'Other' },
    ];

    // === СІЧЕНЬ 2025 ===
    const januaryTransactions = [
      // Income
      { amount: 3000, type: 'income', desc: 'Monthly salary (raise!)', date: '2025-01-02', cat: 'Salary' },
      { amount: 520, type: 'income', desc: 'Freelance logo design', date: '2025-01-20', cat: 'Freelance' },
      
      // Fixed expenses
      { amount: 550, type: 'expense', desc: 'Rent payment (increased)', date: '2025-01-03', cat: 'Rent' },
      { amount: 78, type: 'expense', desc: 'Electricity bill', date: '2025-01-06', cat: 'Utilities' },
      { amount: 45, type: 'expense', desc: 'Internet', date: '2025-01-06', cat: 'Utilities' },
      { amount: 30, type: 'expense', desc: 'Water bill', date: '2025-01-06', cat: 'Utilities' },
      
      // Food
      { amount: 82.40, type: 'expense', desc: 'Grocery shopping', date: '2025-01-05', cat: 'Food' },
      { amount: 95.70, type: 'expense', desc: 'Supermarket', date: '2025-01-12', cat: 'Food' },
      { amount: 78.30, type: 'expense', desc: 'Weekly groceries', date: '2025-01-19', cat: 'Food' },
      { amount: 88.60, type: 'expense', desc: 'Food shopping', date: '2025-01-26', cat: 'Food' },
      { amount: 32.50, type: 'expense', desc: 'Lunch', date: '2025-01-10', cat: 'Food' },
      { amount: 28.00, type: 'expense', desc: 'Coffee & cake', date: '2025-01-17', cat: 'Food' },
      
      // Transport
      { amount: 48.00, type: 'expense', desc: 'Gas station', date: '2025-01-08', cat: 'Transport' },
      { amount: 52.50, type: 'expense', desc: 'Fuel', date: '2025-01-23', cat: 'Transport' },
      { amount: 12.00, type: 'expense', desc: 'Car wash', date: '2025-01-15', cat: 'Transport' },
      
      // Entertainment
      { amount: 18.00, type: 'expense', desc: 'Netflix', date: '2025-01-01', cat: 'Entertainment' },
      { amount: 35.00, type: 'expense', desc: 'Cinema', date: '2025-01-11', cat: 'Entertainment' },
      { amount: 55.00, type: 'expense', desc: 'Bowling with friends', date: '2025-01-25', cat: 'Entertainment' },
      
      // Shopping
      { amount: 89.90, type: 'expense', desc: 'New headphones', date: '2025-01-14', cat: 'Shopping' },
      { amount: 45.00, type: 'expense', desc: 'Books', date: '2025-01-21', cat: 'Shopping' },
      
      // Healthcare
      { amount: 42.00, type: 'expense', desc: 'Doctor visit', date: '2025-01-13', cat: 'Healthcare' },
      { amount: 18.50, type: 'expense', desc: 'Pharmacy', date: '2025-01-13', cat: 'Healthcare' },
      
      // Education
      { amount: 150.00, type: 'expense', desc: 'Online course subscription', date: '2025-01-07', cat: 'Education' },
      
      // Other
      { amount: 25.00, type: 'expense', desc: 'Phone credit', date: '2025-01-04', cat: 'Other' },
    ];

    // Об'єднуємо всі транзакції
    const allTransactions = [
      ...novemberTransactions,
      ...decemberTransactions,
      ...januaryTransactions
    ];

    // Вставляємо транзакції
    for (const trans of allTransactions) {
      await client.query(`
        INSERT INTO transactions (amount, type, description, date, user_id, category_id)
        VALUES ($1, $2, $3, $4, $5, (SELECT id FROM categories WHERE name=$6 AND user_id=$5))
      `, [trans.amount, trans.type, trans.desc, trans.date, userId, trans.cat]);
    }
    
    console.log(`✅ ${allTransactions.length} realistic transactions created (Nov 2024 - Jan 2025)`);

    console.log('\n🎉 Database initialization completed successfully!\n');
    console.log('📝 Login credentials:');
    console.log('   Admin: admin@pf.com / admin123');
    console.log('   User:  user@test.com / user123\n');
    console.log('📊 Test data statistics:');
    console.log(`   • Users: 2`);
    console.log(`   • Categories: ${categories.length}`);
    console.log(`   • Transactions: ${allTransactions.length} (3 months)`);
    console.log(`   • Date range: Nov 2024 - Jan 2025\n`);

  } catch (error) {
    console.error('❌ Database initialization error:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

// Запускаємо
initDatabase()
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });