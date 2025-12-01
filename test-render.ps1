# Quick Render Backend Test
# Usage: .\test-render.ps1 https://your-backend.onrender.com

param(
    [Parameter(Mandatory=$true)]
    [string]$API_URL
)

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "🧪 TESTING RENDER BACKEND" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "URL: $API_URL" -ForegroundColor Cyan
Write-Host ""

$TESTS_PASSED = 0
$TESTS_FAILED = 0

function Test-Endpoint {
    param([string]$TestName, [string]$Response, [string]$Expected)
    
    if ($Response -like "*$Expected*") {
        Write-Host "✅ PASS - $TestName" -ForegroundColor Green
        $script:TESTS_PASSED++
    } else {
        Write-Host "❌ FAIL - $TestName" -ForegroundColor Red
        Write-Host "   Got: $Response" -ForegroundColor Yellow
        $script:TESTS_FAILED++
    }
}

# 1. Health Check
Write-Host "`n📡 HEALTH CHECK" -ForegroundColor Blue
try {
    $response = Invoke-RestMethod -Uri "$API_URL/health" -Method Get -TimeoutSec 60
    Test-Endpoint "Health endpoint responds" ($response | ConvertTo-Json) '"status":"OK"'
} catch {
    Write-Host "❌ FAIL - Health check (Backend might be sleeping, wait 30-60 sec)" -ForegroundColor Red
    $script:TESTS_FAILED++
}

# 2. Login as User
Write-Host "`n🔐 LOGIN TESTS" -ForegroundColor Blue
$body = @{email = "user@test.com"; password = "user123"} | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri "$API_URL/api/auth/login" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
    Test-Endpoint "Login as user" ($response | ConvertTo-Json) '"token"'
    $USER_TOKEN = $response.data.token
    Write-Host "   Token: $($USER_TOKEN.Substring(0,20))..." -ForegroundColor Gray
} catch {
    Write-Host "❌ FAIL - Login as user" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
    $script:TESTS_FAILED++
}

# 3. Login as Admin
$body = @{email = "admin@pf.com"; password = "admin123"} | ConvertTo-Json
try {
    $response = Invoke-RestMethod -Uri "$API_URL/api/auth/login" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
    Test-Endpoint "Login as admin" ($response | ConvertTo-Json) '"role":"admin"'
    $ADMIN_TOKEN = $response.data.token
} catch {
    Write-Host "❌ FAIL - Login as admin" -ForegroundColor Red
    $script:TESTS_FAILED++
}

# 4. Get Current User
Write-Host "`n👤 CURRENT USER" -ForegroundColor Blue
if ($USER_TOKEN) {
    try {
        $headers = @{Authorization = "Bearer $USER_TOKEN"}
        $response = Invoke-RestMethod -Uri "$API_URL/api/auth/me" -Method Get -Headers $headers -TimeoutSec 30
        Test-Endpoint "Get current user" ($response | ConvertTo-Json) '"email":"user@test.com"'
    } catch {
        Write-Host "❌ FAIL - Get current user" -ForegroundColor Red
        $script:TESTS_FAILED++
    }
}

# 5. Categories
Write-Host "`n📂 CATEGORIES" -ForegroundColor Blue
if ($USER_TOKEN) {
    try {
        $headers = @{Authorization = "Bearer $USER_TOKEN"}
        $response = Invoke-RestMethod -Uri "$API_URL/api/categories" -Method Get -Headers $headers -TimeoutSec 30
        Test-Endpoint "Get all categories" ($response | ConvertTo-Json) '"categories"'
        $categoryCount = $response.data.categories.Count
        Write-Host "   Found $categoryCount categories" -ForegroundColor Gray
    } catch {
        Write-Host "❌ FAIL - Get categories" -ForegroundColor Red
        $script:TESTS_FAILED++
    }
}

# 6. Transactions
Write-Host "`n💰 TRANSACTIONS" -ForegroundColor Blue
if ($USER_TOKEN) {
    try {
        $headers = @{Authorization = "Bearer $USER_TOKEN"}
        $response = Invoke-RestMethod -Uri "$API_URL/api/transactions" -Method Get -Headers $headers -TimeoutSec 30
        Test-Endpoint "Get all transactions" ($response | ConvertTo-Json) '"transactions"'
        $transCount = $response.data.transactions.Count
        Write-Host "   Found $transCount transactions" -ForegroundColor Gray
    } catch {
        Write-Host "❌ FAIL - Get transactions" -ForegroundColor Red
        $script:TESTS_FAILED++
    }
}

# 7. Statistics
Write-Host "`n📊 STATISTICS (ML)" -ForegroundColor Blue
if ($USER_TOKEN) {
    try {
        $headers = @{Authorization = "Bearer $USER_TOKEN"}
        $response = Invoke-RestMethod -Uri "$API_URL/api/transactions/stats" -Method Get -Headers $headers -TimeoutSec 30
        Test-Endpoint "Get statistics" ($response | ConvertTo-Json) '"overall"'
        Test-Endpoint "Statistics has by_category" ($response | ConvertTo-Json) '"by_category"'
        Test-Endpoint "Statistics has monthly" ($response | ConvertTo-Json) '"monthly"'
    } catch {
        Write-Host "❌ FAIL - Get statistics" -ForegroundColor Red
        $script:TESTS_FAILED += 3
    }
}

# 8. Create Transaction
Write-Host "`n➕ CREATE TRANSACTION" -ForegroundColor Blue
if ($USER_TOKEN) {
    $body = @{
        amount = 99.99
        type = "expense"
        description = "Test transaction from automated test"
        date = (Get-Date -Format "yyyy-MM-dd")
        category_id = 1
    } | ConvertTo-Json
    
    try {
        $headers = @{Authorization = "Bearer $USER_TOKEN"}
        $response = Invoke-RestMethod -Uri "$API_URL/api/transactions" -Method Post -Body $body -ContentType "application/json" -Headers $headers -TimeoutSec 30
        Test-Endpoint "Create transaction" ($response | ConvertTo-Json) '"success":true'
    } catch {
        Write-Host "❌ FAIL - Create transaction" -ForegroundColor Red
        $script:TESTS_FAILED++
    }
}

# 9. Admin Functions
Write-Host "`n👨‍💼 ADMIN FUNCTIONS" -ForegroundColor Blue
if ($ADMIN_TOKEN) {
    try {
        $headers = @{Authorization = "Bearer $ADMIN_TOKEN"}
        $response = Invoke-RestMethod -Uri "$API_URL/api/users" -Method Get -Headers $headers -TimeoutSec 30
        Test-Endpoint "Admin gets all users" ($response | ConvertTo-Json) '"users"'
    } catch {
        Write-Host "❌ FAIL - Admin get users" -ForegroundColor Red
        $script:TESTS_FAILED++
    }
}

# Summary
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "📊 ПІДСУМОК" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue

$TOTAL = $TESTS_PASSED + $TESTS_FAILED
if ($TOTAL -gt 0) {
    $SUCCESS_RATE = [math]::Round(($TESTS_PASSED / $TOTAL) * 100, 1)
} else {
    $SUCCESS_RATE = 0
}

Write-Host "✅ Passed: $TESTS_PASSED" -ForegroundColor Green
Write-Host "❌ Failed: $TESTS_FAILED" -ForegroundColor Red
Write-Host "📈 Total:  $TOTAL" -ForegroundColor Blue
Write-Host "🎯 Success Rate: $SUCCESS_RATE%" -ForegroundColor Blue
Write-Host ""

if ($TESTS_FAILED -eq 0) {
    Write-Host "🎉 ВСІ ТЕСТИ ПРОЙШЛИ!" -ForegroundColor Green
    Write-Host "Render Backend готовий до використання! 🚀" -ForegroundColor Green
} else {
    Write-Host "⚠️  Деякі тести не пройшли." -ForegroundColor Yellow
    if ($TESTS_FAILED -eq $TOTAL) {
        Write-Host "💡 Можливо backend ще засинає? Спробуй через 30-60 сек." -ForegroundColor Cyan
    }
}
