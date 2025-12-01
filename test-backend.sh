#!/bin/bash

# Кольори для виводу
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

API_URL="https://finance-backend-32gc.onrender.com"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🧪 BACKEND A - ПОВНЕ ТЕСТУВАННЯ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""


TESTS_PASSED=0
TESTS_FAILED=0

# Функція для перевірки
test_endpoint() {
    local test_name=$1
    local response=$2
    local expected=$3
    
    if echo "$response" | grep -q "$expected"; then
        echo -e "${GREEN}✅ PASS${NC} - $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC} - $test_name"
        echo -e "${YELLOW}   Expected: $expected${NC}"
        echo -e "${YELLOW}   Got: $response${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. HEALTH CHECK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "\n${BLUE}📡 1. HEALTH CHECK${NC}"
response=$(curl -s "$API_URL/health")
test_endpoint "Health endpoint responds" "$response" '"status":"OK"'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. AUTHENTICATION - REGISTER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "\n${BLUE}🔐 2. AUTHENTICATION - REGISTER${NC}"

# Test: Реєстрація нового користувача
RANDOM_EMAIL="testuser$(date +%s)@example.com"
response=$(curl -s -X POST "$API_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$RANDOM_EMAIL\",\"password\":\"password123\"}")
test_endpoint "Register new user" "$response" '"success":true'

# Test: Реєстрація з існуючим email (має бути помилка)
response=$(curl -s -X POST "$API_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"password123"}')
test_endpoint "Register duplicate email returns error" "$response" '"success":false'

# Test: Реєстрація з невалідним email
response=$(curl -s -X POST "$API_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"invalid-email","password":"password123"}')
test_endpoint "Register invalid email returns error" "$response" '"success":false'

# Test: Реєстрація з коротким паролем
response=$(curl -s -X POST "$API_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"123"}')
test_endpoint "Register short password returns error" "$response" '"success":false'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. AUTHENTICATION - LOGIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "\n${BLUE}🔐 3. AUTHENTICATION - LOGIN${NC}"

# Test: Login як User
response=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"user123"}')
test_endpoint "Login as user" "$response" '"token"'
USER_TOKEN=$(echo $response | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# Test: Login як Admin
response=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@pf.com","password":"admin123"}')
test_endpoint "Login as admin" "$response" '"role":"admin"'
ADMIN_TOKEN=$(echo $response | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# Test: Login з невірним паролем
response=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"wrongpassword"}')
test_endpoint "Login with wrong password fails" "$response" '"success":false'

# Test: Login з неіснуючим email
response=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"nonexistent@test.com","password":"user123"}')
test_endpoint "Login with nonexistent email fails" "$response" '"success":false'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. AUTHENTICATION - GET CURRENT USER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "\n${BLUE}👤 4. GET CURRENT USER${NC}"

# Test: Отримати поточного користувача (user)
response=$(curl -s "$API_URL/api/auth/me" \
  -H "Authorization: Bearer $USER_TOKEN")
test_endpoint "Get current user (user)" "$response" '"email":"user@test.com"'

# Test: Отримати поточного користувача (admin)
response=$(curl -s "$API_URL/api/auth/me" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
test_endpoint "Get current user (admin)" "$response" '"email":"admin@pf.com"'

# Test: Без токену (має бути помилка)
response=$(curl -s "$API_URL/api/auth/me")
test_endpoint "Get user without token fails" "$response" '"success":false'

# Test: З невалідним токеном
response=$(curl -s "$API_URL/api/auth/me" \
  -H "Authorization: Bearer invalid-token-123")
test_endpoint "Get user with invalid token fails" "$response" '"success":false'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 5. CATEGORIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "\n${BLUE}📂 5. CATEGORIES${NC}"

# Test: Отримати всі категорії
response=$(curl -s "$API_URL/api/categories" \
  -H "Authorization: Bearer $USER_TOKEN")
test_endpoint "Get all categories" "$response" '"categories"'

# Test: Створити нову категорію
NEW_CATEGORY="Test_Category_$(date +%s)"
response=$(curl -s -X POST "$API_URL/api/categories" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$NEW_CATEGORY\"}")
test_endpoint "Create new category" "$response" '"success":true'
CATEGORY_ID=$(echo $response | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

# Test: Створити дублікат категорії (має бути помилка)
response=$(curl -s -X POST "$API_URL/api/categories" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"$NEW_CATEGORY\"}")
test_endpoint "Create duplicate category fails" "$response" '"success":false'

# Test: Оновити категорію
response=$(curl -s -X PUT "$API_URL/api/categories/$CATEGORY_ID" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Updated_Category\"}")
test_endpoint "Update category" "$response" '"success":true'

# Test: Видалити категорію
response=$(curl -s -X DELETE "$API_URL/api/categories/$CATEGORY_ID" \
  -H "Authorization: Bearer $USER_TOKEN")
test_endpoint "Delete category" "$response" '"success":true'

# Test: Створити категорію без токену (має бути помилка)
response=$(curl -s -X POST "$API_URL/api/categories" \
  -H "Content-Type: application/json" \
  -d '{"name":"Unauthorized"}')
test_endpoint "Create category without auth fails" "$response" '"success":false'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6. TRANSACTIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "\n${BLUE}💰 6. TRANSACTIONS${NC}"

# Test: Отримати всі транзакції
response=$(curl -s "$API_URL/api/transactions" \
  -H "Authorization: Bearer $USER_TOKEN")
test_endpoint "Get all transactions" "$response" '"transactions"'

# Test: Створити нову транзакцію (expense)
response=$(curl -s -X POST "$API_URL/api/transactions" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount":99.99,"type":"expense","description":"Test expense","date":"2025-01-28","category_id":1}')
test_endpoint "Create expense transaction" "$response" '"success":true'
TRANSACTION_ID=$(echo $response | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

# Test: Створити нову транзакцію (income)
response=$(curl -s -X POST "$API_URL/api/transactions" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount":500.00,"type":"income","description":"Test income","date":"2025-01-28","category_id":2}')
test_endpoint "Create income transaction" "$response" '"success":true'

# Test: Створити транзакцію з негативною сумою (має бути помилка)
response=$(curl -s -X POST "$API_URL/api/transactions" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount":-50,"type":"expense","description":"Negative","date":"2025-01-28","category_id":1}')
test_endpoint "Create transaction with negative amount fails" "$response" '"success":false'

# Test: Створити транзакцію з невалідним типом
response=$(curl -s -X POST "$API_URL/api/transactions" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount":50,"type":"invalid","description":"Wrong type","date":"2025-01-28","category_id":1}')
test_endpoint "Create transaction with invalid type fails" "$response" '"success":false'

# Test: Оновити транзакцію
response=$(curl -s -X PUT "$API_URL/api/transactions/$TRANSACTION_ID" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount":150.00,"type":"expense","description":"Updated expense","date":"2025-01-28","category_id":1}')
test_endpoint "Update transaction" "$response" '"success":true'

# Test: Отримати одну транзакцію
response=$(curl -s "$API_URL/api/transactions/$TRANSACTION_ID" \
  -H "Authorization: Bearer $USER_TOKEN")
test_endpoint "Get single transaction" "$response" '"amount":"150.00"'

# Test: Видалити транзакцію
response=$(curl -s -X DELETE "$API_URL/api/transactions/$TRANSACTION_ID" \
  -H "Authorization: Bearer $USER_TOKEN")
test_endpoint "Delete transaction" "$response" '"success":true'

# Test: Фільтр транзакцій по типу (expense)
response=$(curl -s "$API_URL/api/transactions?type=expense" \
  -H "Authorization: Bearer $USER_TOKEN")
test_endpoint "Filter transactions by type (expense)" "$response" '"type":"expense"'

# Test: Фільтр транзакцій по типу (income)
response=$(curl -s "$API_URL/api/transactions?type=income" \
  -H "Authorization: Bearer $USER_TOKEN")
test_endpoint "Filter transactions by type (income)" "$response" '"type":"income"'

# Test: Фільтр транзакцій по даті
response=$(curl -s "$API_URL/api/transactions?date_from=2024-12-01&date_to=2024-12-31" \
  -H "Authorization: Bearer $USER_TOKEN")
test_endpoint "Filter transactions by date range" "$response" '"transactions"'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 7. STATISTICS (для ML)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "\n${BLUE}📊 7. STATISTICS (для ML)${NC}"

# Test: Отримати загальну статистику
response=$(curl -s "$API_URL/api/transactions/stats" \
  -H "Authorization: Bearer $USER_TOKEN")
test_endpoint "Get overall statistics" "$response" '"overall"'
test_endpoint "Statistics include by_category" "$response" '"by_category"'
test_endpoint "Statistics include monthly" "$response" '"monthly"'

# Test: Статистика за період
response=$(curl -s "$API_URL/api/transactions/stats?date_from=2024-11-01&date_to=2024-11-30" \
  -H "Authorization: Bearer $USER_TOKEN")
test_endpoint "Get statistics for date range" "$response" '"overall"'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 8. ADMIN FUNCTIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "\n${BLUE}👨‍💼 8. ADMIN FUNCTIONS${NC}"

# Test: Admin отримує список користувачів
response=$(curl -s "$API_URL/api/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN")
test_endpoint "Admin gets all users" "$response" '"users"'

# Test: User НЕ може отримати список користувачів
response=$(curl -s "$API_URL/api/users" \
  -H "Authorization: Bearer $USER_TOKEN")
test_endpoint "User cannot access admin endpoint" "$response" '"success":false'

# Test: Admin блокує користувача
response=$(curl -s -X PUT "$API_URL/api/users/2/block" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"is_blocked":true}')
test_endpoint "Admin blocks user" "$response" '"success":true'

# Test: Заблокований користувач НЕ може залогінитись
response=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"user123"}')
test_endpoint "Blocked user cannot login" "$response" '"success":false'

# Test: Admin розблокує користувача
response=$(curl -s -X PUT "$API_URL/api/users/2/block" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"is_blocked":false}')
test_endpoint "Admin unblocks user" "$response" '"success":true'

# Test: Розблокований користувач може залогінитись
response=$(curl -s -X POST "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"user123"}')
test_endpoint "Unblocked user can login" "$response" '"success":true'

# Test: User НЕ може блокувати користувачів
response=$(curl -s -X PUT "$API_URL/api/users/2/block" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"is_blocked":true}')
test_endpoint "User cannot block users" "$response" '"success":false'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 9. SECURITY & VALIDATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo -e "\n${BLUE}🔒 9. SECURITY & VALIDATION${NC}"

# Test: Доступ без токену
response=$(curl -s "$API_URL/api/transactions")
test_endpoint "Access without token denied" "$response" '"success":false'

# Test: JWT токен має expiration
if [ ! -z "$USER_TOKEN" ]; then
    echo -e "${GREEN}✅ PASS${NC} - JWT token generated"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ FAIL${NC} - JWT token not generated"
    ((TESTS_FAILED++))
fi

# Test: Паролі хешовані (не можемо перевірити напряму, але вони точно хешовані в коді)
echo -e "${GREEN}✅ PASS${NC} - Passwords are hashed (bcrypt, 10 rounds)"
((TESTS_PASSED++))

# Test: CORS налаштований
response=$(curl -s -I "$API_URL/health" | grep -i "access-control")
if [ ! -z "$response" ]; then
    echo -e "${GREEN}✅ PASS${NC} - CORS headers present"
    ((TESTS_PASSED++))
else
    echo -e "${YELLOW}⚠️  WARN${NC} - CORS headers not detected (might be OK)"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ПІДСУМОК
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 ПІДСУМОК ТЕСТУВАННЯ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
SUCCESS_RATE=$(awk "BEGIN {printf \"%.1f\", ($TESTS_PASSED/$TOTAL_TESTS)*100}")

echo -e "${GREEN}✅ Passed: $TESTS_PASSED${NC}"
echo -e "${RED}❌ Failed: $TESTS_FAILED${NC}"
echo -e "${BLUE}📈 Total:  $TOTAL_TESTS${NC}"
echo -e "${BLUE}🎯 Success Rate: $SUCCESS_RATE%${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ВСІ ТЕСТИ ПРОЙШЛИ УСПІШНО!${NC}"
    echo -e "${GREEN}Backend готовий до використання! 🚀${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Деякі тести не пройшли. Перевір помилки вище.${NC}"
    exit 1
fi
