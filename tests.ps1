# ============================================
# Comprehensive API Test Suite
# Positive & Negative Scenarios
# ============================================

$API_URL = "https://finance-backend-32gc.onrender.com"
$passedTests = 0
$failedTests = 0

function Write-TestResult {
    param($Name, $Expected, $Actual, $Passed)
    
    if ($Passed) {
        Write-Host "PASS: $Name" -ForegroundColor Green
        $script:passedTests++
    } else {
        Write-Host "FAIL: $Name" -ForegroundColor Red
        Write-Host "   Expected: $Expected, Got: $Actual" -ForegroundColor Red
        $script:failedTests++
    }
}

function Test-Endpoint {
    param($Name, $Method, $Path, $Body, $Headers, $ExpectedStatus)
    
    try {
        $params = @{
            Uri = "$API_URL$Path"
            Method = $Method
            Headers = $Headers
            ContentType = "application/json"
            ErrorAction = "Stop"
        }
        
        if ($Body) {
            $params.Body = ($Body | ConvertTo-Json)
        }
        
        $response = Invoke-RestMethod @params
        Write-TestResult -Name $Name -Expected $ExpectedStatus -Actual 200 -Passed ($ExpectedStatus -eq 200 -or $ExpectedStatus -eq 201)
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.Value__
        Write-TestResult -Name $Name -Expected $ExpectedStatus -Actual $statusCode -Passed ($statusCode -eq $ExpectedStatus)
        return $null
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "   COMPREHENSIVE API TEST SUITE" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# ============================================
# 1. HEALTH AND CONNECTIVITY
# ============================================
Write-Host "`n=== 1. HEALTH AND CONNECTIVITY ===`n" -ForegroundColor Yellow

Test-Endpoint -Name "Health check works" `
    -Method "GET" -Path "/health" -ExpectedStatus 200

# ============================================
# 2. AUTHENTICATION - POSITIVE SCENARIOS
# ============================================
Write-Host "`n=== 2. AUTHENTICATION - POSITIVE ===`n" -ForegroundColor Yellow

# 2.1 Register new user
$randomEmail = "test$(Get-Random -Min 10000 -Max 99999)@test.com"
$newUserData = @{
    email = $randomEmail
    password = "Test123!"
}
$registerResult = Test-Endpoint -Name "Register new user" `
    -Method "POST" -Path "/api/auth/register" `
    -Body $newUserData -ExpectedStatus 201

# 2.2 Login with valid credentials (USER)
$loginResult = Test-Endpoint -Name "Login with valid credentials (USER)" `
    -Method "POST" -Path "/api/auth/login" `
    -Body @{ email = "user@test.com"; password = "user123" } `
    -ExpectedStatus 200
$userToken = $loginResult.data.token

# 2.3 Login with valid credentials (ADMIN)
$adminLoginResult = Test-Endpoint -Name "Login with valid credentials (ADMIN)" `
    -Method "POST" -Path "/api/auth/login" `
    -Body @{ email = "admin@pf.com"; password = "admin123" } `
    -ExpectedStatus 200
$adminToken = $adminLoginResult.data.token

# 2.4 Get current user with valid token
$userHeaders = @{ "Authorization" = "Bearer $userToken" }
Test-Endpoint -Name "Get current user (authenticated)" `
    -Method "GET" -Path "/api/auth/me" `
    -Headers $userHeaders -ExpectedStatus 200

# 2.5 Logout
Test-Endpoint -Name "Logout successfully" `
    -Method "POST" -Path "/api/auth/logout" `
    -Headers $userHeaders -ExpectedStatus 200

# ============================================
# 3. AUTHENTICATION - NEGATIVE SCENARIOS
# ============================================
Write-Host "`n=== 3. AUTHENTICATION - NEGATIVE ===`n" -ForegroundColor Yellow

# 3.1 Register with existing email
Test-Endpoint -Name "Register duplicate email (should fail)" `
    -Method "POST" -Path "/api/auth/register" `
    -Body @{ email = "user@test.com"; password = "Test123!" } `
    -ExpectedStatus 409

# 3.2 Register with invalid email
Test-Endpoint -Name "Register with invalid email (should fail)" `
    -Method "POST" -Path "/api/auth/register" `
    -Body @{ email = "notanemail"; password = "Test123!" } `
    -ExpectedStatus 400

# 3.3 Register with short password
Test-Endpoint -Name "Register with short password (should fail)" `
    -Method "POST" -Path "/api/auth/register" `
    -Body @{ email = "new@test.com"; password = "123" } `
    -ExpectedStatus 400

# 3.4 Login with wrong password
Test-Endpoint -Name "Login with wrong password (should fail)" `
    -Method "POST" -Path "/api/auth/login" `
    -Body @{ email = "user@test.com"; password = "wrongpassword" } `
    -ExpectedStatus 401

# 3.5 Login with non-existent user
Test-Endpoint -Name "Login with non-existent user (should fail)" `
    -Method "POST" -Path "/api/auth/login" `
    -Body @{ email = "nobody@test.com"; password = "password" } `
    -ExpectedStatus 401

# 3.6 Access protected route without token
Test-Endpoint -Name "Access protected route without token (should fail)" `
    -Method "GET" -Path "/api/auth/me" `
    -ExpectedStatus 401

# 3.7 Access with invalid token
$invalidHeaders = @{ "Authorization" = "Bearer invalidtoken123" }
Test-Endpoint -Name "Access with invalid token (should fail)" `
    -Method "GET" -Path "/api/auth/me" `
    -Headers $invalidHeaders -ExpectedStatus 401

# ============================================
# 4. CATEGORIES - POSITIVE SCENARIOS
# ============================================
Write-Host "`n=== 4. CATEGORIES - POSITIVE ===`n" -ForegroundColor Yellow

# 4.1 Get all categories
$categoriesResult = Test-Endpoint -Name "Get all categories" `
    -Method "GET" -Path "/api/categories" `
    -Headers $userHeaders -ExpectedStatus 200

# 4.2 Get categories in /all format
$allCategoriesResult = Test-Endpoint -Name "Get categories (/all endpoint)" `
    -Method "GET" -Path "/api/categories/all" `
    -Headers $userHeaders -ExpectedStatus 200

# 4.3 Get specific category by ID
if ($allCategoriesResult -and $allCategoriesResult.data.Count -gt 0) {
    $categoryId = $allCategoriesResult.data[0].id
    Test-Endpoint -Name "Get category by ID" `
        -Method "GET" -Path "/api/categories/$categoryId" `
        -Headers $userHeaders -ExpectedStatus 200
}

# ============================================
# 5. CATEGORIES - NEGATIVE SCENARIOS
# ============================================
Write-Host "`n=== 5. CATEGORIES - NEGATIVE ===`n" -ForegroundColor Yellow

# 5.1 Get categories without authentication
Test-Endpoint -Name "Get categories without auth (should fail)" `
    -Method "GET" -Path "/api/categories" `
    -ExpectedStatus 401

# 5.2 Get non-existent category
Test-Endpoint -Name "Get non-existent category (should fail)" `
    -Method "GET" -Path "/api/categories/99999" `
    -Headers $userHeaders -ExpectedStatus 404

# ============================================
# 6. TRANSACTIONS - POSITIVE SCENARIOS
# ============================================
Write-Host "`n=== 6. TRANSACTIONS - POSITIVE ===`n" -ForegroundColor Yellow

# Get a valid category ID for transactions
$incomeCategory = $allCategoriesResult.data | Where-Object { $_.type -eq "income" } | Select-Object -First 1
$expenseCategory = $allCategoriesResult.data | Where-Object { $_.type -eq "expense" } | Select-Object -First 1

# 6.1 Create income transaction
$incomeTransaction = @{
    amount = 5000
    type = "income"
    category_id = $incomeCategory.id
    description = "Test salary"
    date = (Get-Date -Format "yyyy-MM-dd")
}
$createIncomeResult = Test-Endpoint -Name "Create income transaction" `
    -Method "POST" -Path "/api/transactions" `
    -Body $incomeTransaction -Headers $userHeaders -ExpectedStatus 201
$incomeTransactionId = $createIncomeResult.data.transaction.id

# 6.2 Create expense transaction
$expenseTransaction = @{
    amount = 150.50
    type = "expense"
    category_id = $expenseCategory.id
    description = "Test groceries"
    date = (Get-Date -Format "yyyy-MM-dd")
}
$createExpenseResult = Test-Endpoint -Name "Create expense transaction" `
    -Method "POST" -Path "/api/transactions" `
    -Body $expenseTransaction -Headers $userHeaders -ExpectedStatus 201
$expenseTransactionId = $createExpenseResult.data.transaction.id

# 6.3 Get all transactions
Test-Endpoint -Name "Get all transactions" `
    -Method "GET" -Path "/api/transactions" `
    -Headers $userHeaders -ExpectedStatus 200

# 6.4 Get transactions with filters (by type)
Test-Endpoint -Name "Get income transactions (filtered)" `
    -Method "GET" -Path "/api/transactions?type=income" `
    -Headers $userHeaders -ExpectedStatus 200

Test-Endpoint -Name "Get expense transactions (filtered)" `
    -Method "GET" -Path "/api/transactions?type=expense" `
    -Headers $userHeaders -ExpectedStatus 200

# 6.5 Get transactions with date filter
$dateFrom = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")
$dateTo = (Get-Date).ToString("yyyy-MM-dd")
$dateFilterPath = "/api/transactions?date_from=$dateFrom" + "&date_to=$dateTo"
Test-Endpoint -Name "Get transactions (date filtered)" `
    -Method "GET" -Path $dateFilterPath `
    -Headers $userHeaders -ExpectedStatus 200

# 6.6 Get transaction by ID
Test-Endpoint -Name "Get transaction by ID" `
    -Method "GET" -Path "/api/transactions/$incomeTransactionId" `
    -Headers $userHeaders -ExpectedStatus 200

# 6.7 Update transaction
$updateTransaction = @{
    amount = 200.00
    type = "expense"
    category_id = $expenseCategory.id
    description = "Updated test transaction"
    date = (Get-Date -Format "yyyy-MM-dd")
}
Test-Endpoint -Name "Update transaction" `
    -Method "PUT" -Path "/api/transactions/$expenseTransactionId" `
    -Body $updateTransaction -Headers $userHeaders -ExpectedStatus 200

# 6.8 Get statistics
Test-Endpoint -Name "Get transaction statistics" `
    -Method "GET" -Path "/api/transactions/stats" `
    -Headers $userHeaders -ExpectedStatus 200

# ============================================
# 7. TRANSACTIONS - NEGATIVE SCENARIOS
# ============================================
Write-Host "`n=== 7. TRANSACTIONS - NEGATIVE ===`n" -ForegroundColor Yellow

# 7.1 Get transactions without auth
Test-Endpoint -Name "Get transactions without auth (should fail)" `
    -Method "GET" -Path "/api/transactions" `
    -ExpectedStatus 401

# 7.2 Create transaction without required fields
Test-Endpoint -Name "Create transaction without amount (should fail)" `
    -Method "POST" -Path "/api/transactions" `
    -Body @{ type = "expense"; date = (Get-Date -Format "yyyy-MM-dd") } `
    -Headers $userHeaders -ExpectedStatus 400

# 7.3 Create transaction with negative amount
Test-Endpoint -Name "Create transaction with negative amount (should fail)" `
    -Method "POST" -Path "/api/transactions" `
    -Body @{ amount = -100; type = "expense"; date = (Get-Date -Format "yyyy-MM-dd") } `
    -Headers $userHeaders -ExpectedStatus 400

# 7.4 Create transaction with invalid type
Test-Endpoint -Name "Create transaction with invalid type (should fail)" `
    -Method "POST" -Path "/api/transactions" `
    -Body @{ amount = 100; type = "invalid"; date = (Get-Date -Format "yyyy-MM-dd") } `
    -Headers $userHeaders -ExpectedStatus 400

# 7.5 Create transaction with invalid date
Test-Endpoint -Name "Create transaction with invalid date (should fail)" `
    -Method "POST" -Path "/api/transactions" `
    -Body @{ amount = 100; type = "expense"; date = "not-a-date" } `
    -Headers $userHeaders -ExpectedStatus 400

# 7.6 Create transaction with non-existent category
Test-Endpoint -Name "Create transaction with fake category (should fail)" `
    -Method "POST" -Path "/api/transactions" `
    -Body @{ amount = 100; type = "expense"; category_id = 99999; date = (Get-Date -Format "yyyy-MM-dd") } `
    -Headers $userHeaders -ExpectedStatus 400

# 7.7 Create expense transaction with income category (type mismatch)
Test-Endpoint -Name "Create expense with income category (should fail)" `
    -Method "POST" -Path "/api/transactions" `
    -Body @{ amount = 100; type = "expense"; category_id = $incomeCategory.id; date = (Get-Date -Format "yyyy-MM-dd") } `
    -Headers $userHeaders -ExpectedStatus 400

# 7.8 Get non-existent transaction
Test-Endpoint -Name "Get non-existent transaction (should fail)" `
    -Method "GET" -Path "/api/transactions/99999" `
    -Headers $userHeaders -ExpectedStatus 404

# 7.9 Update non-existent transaction
Test-Endpoint -Name "Update non-existent transaction (should fail)" `
    -Method "PUT" -Path "/api/transactions/99999" `
    -Body @{ amount = 100; type = "expense"; category_id = $expenseCategory.id; date = (Get-Date -Format "yyyy-MM-dd") } `
    -Headers $userHeaders -ExpectedStatus 404

# 7.10 Delete non-existent transaction
Test-Endpoint -Name "Delete non-existent transaction (should fail)" `
    -Method "DELETE" -Path "/api/transactions/99999" `
    -Headers $userHeaders -ExpectedStatus 404

# ============================================
# 8. ADMIN ROUTES - POSITIVE SCENARIOS
# ============================================
Write-Host "`n=== 8. ADMIN ROUTES - POSITIVE ===`n" -ForegroundColor Yellow

$adminHeaders = @{ "Authorization" = "Bearer $adminToken" }

# 8.1 Get all users (as admin)
Test-Endpoint -Name "Get all users (as admin)" `
    -Method "GET" -Path "/api/users" `
    -Headers $adminHeaders -ExpectedStatus 200

# 8.2 Get user by ID (as admin)
Test-Endpoint -Name "Get user by ID (as admin)" `
    -Method "GET" -Path "/api/users/2" `
    -Headers $adminHeaders -ExpectedStatus 200

# ============================================
# 9. ADMIN ROUTES - NEGATIVE SCENARIOS
# ============================================
Write-Host "`n=== 9. ADMIN ROUTES - NEGATIVE ===`n" -ForegroundColor Yellow

# 9.1 Access admin routes as regular user
Test-Endpoint -Name "Get all users as USER (should fail)" `
    -Method "GET" -Path "/api/users" `
    -Headers $userHeaders -ExpectedStatus 403

# 9.2 Block user as regular user
Test-Endpoint -Name "Block user as USER (should fail)" `
    -Method "PUT" -Path "/api/users/2/block" `
    -Body @{ is_blocked = $true } `
    -Headers $userHeaders -ExpectedStatus 403

# 9.3 Delete user as regular user
Test-Endpoint -Name "Delete user as USER (should fail)" `
    -Method "DELETE" -Path "/api/users/2" `
    -Headers $userHeaders -ExpectedStatus 403

# 9.4 Get non-existent user (as admin)
Test-Endpoint -Name "Get non-existent user (should fail)" `
    -Method "GET" -Path "/api/users/99999" `
    -Headers $adminHeaders -ExpectedStatus 404

# 9.5 Block with invalid data
Test-Endpoint -Name "Block user with invalid data (should fail)" `
    -Method "PUT" -Path "/api/users/2/block" `
    -Body @{ is_blocked = "not-a-boolean" } `
    -Headers $adminHeaders -ExpectedStatus 400

# ============================================
# 10. EDGE CASES AND BOUNDARY TESTS
# ============================================
Write-Host "`n=== 10. EDGE CASES AND BOUNDARY ===`n" -ForegroundColor Yellow

# 10.1 Very large amount
Test-Endpoint -Name "Create transaction with very large amount" `
    -Method "POST" -Path "/api/transactions" `
    -Body @{ amount = 999999999.99; type = "income"; category_id = $incomeCategory.id; date = (Get-Date -Format "yyyy-MM-dd") } `
    -Headers $userHeaders -ExpectedStatus 201

# 10.2 Very small amount
Test-Endpoint -Name "Create transaction with very small amount" `
    -Method "POST" -Path "/api/transactions" `
    -Body @{ amount = 0.01; type = "expense"; category_id = $expenseCategory.id; date = (Get-Date -Format "yyyy-MM-dd") } `
    -Headers $userHeaders -ExpectedStatus 201

# 10.3 Transaction without description (optional field)
Test-Endpoint -Name "Create transaction without description" `
    -Method "POST" -Path "/api/transactions" `
    -Body @{ amount = 50; type = "expense"; category_id = $expenseCategory.id; date = (Get-Date -Format "yyyy-MM-dd") } `
    -Headers $userHeaders -ExpectedStatus 201

# 10.4 Very long description
$longDesc = "A" * 1000
Test-Endpoint -Name "Create transaction with very long description" `
    -Method "POST" -Path "/api/transactions" `
    -Body @{ amount = 50; type = "expense"; category_id = $expenseCategory.id; description = $longDesc; date = (Get-Date -Format "yyyy-MM-dd") } `
    -Headers $userHeaders -ExpectedStatus 201

# 10.5 Future date
$futureDate = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")
Test-Endpoint -Name "Create transaction with future date" `
    -Method "POST" -Path "/api/transactions" `
    -Body @{ amount = 100; type = "expense"; category_id = $expenseCategory.id; date = $futureDate } `
    -Headers $userHeaders -ExpectedStatus 201

# 10.6 Very old date
$oldDate = "2000-01-01"
Test-Endpoint -Name "Create transaction with old date" `
    -Method "POST" -Path "/api/transactions" `
    -Body @{ amount = 100; type = "income"; category_id = $incomeCategory.id; date = $oldDate } `
    -Headers $userHeaders -ExpectedStatus 201

# ============================================
# 11. CLEANUP - Delete test transactions
# ============================================
Write-Host "`n=== 11. CLEANUP ===`n" -ForegroundColor Yellow

if ($incomeTransactionId) {
    Test-Endpoint -Name "Delete income transaction" `
        -Method "DELETE" -Path "/api/transactions/$incomeTransactionId" `
        -Headers $userHeaders -ExpectedStatus 200
}

if ($expenseTransactionId) {
    Test-Endpoint -Name "Delete expense transaction" `
        -Method "DELETE" -Path "/api/transactions/$expenseTransactionId" `
        -Headers $userHeaders -ExpectedStatus 200
}

# ============================================
# FINAL RESULTS
# ============================================
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "          TEST RESULTS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$total = $passedTests + $failedTests
$percentage = if ($total -gt 0) { [math]::Round(($passedTests / $total) * 100, 2) } else { 0 }

Write-Host "`nTotal Tests:  $total" -ForegroundColor White
Write-Host "Passed:       $passedTests" -ForegroundColor Green
Write-Host "Failed:       $failedTests" -ForegroundColor Red
Write-Host "Success Rate: $percentage%" -ForegroundColor $(if ($percentage -ge 90) {"Green"} elseif ($percentage -ge 70) {"Yellow"} else {"Red"})

if ($failedTests -eq 0) {
    Write-Host "`nALL TESTS PASSED! API is working perfectly!" -ForegroundColor Green
} elseif ($percentage -ge 90) {
    Write-Host "`nEXCELLENT! Most tests passed." -ForegroundColor Yellow
} elseif ($percentage -ge 70) {
    Write-Host "`nGOOD, but some issues need attention." -ForegroundColor Yellow
} else {
    Write-Host "`nCRITICAL ISSUES DETECTED!" -ForegroundColor Red
}

Write-Host "`n"