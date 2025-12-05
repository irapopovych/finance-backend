# ============================================
# ML PREDICTIONS INTEGRATION TESTS
# ============================================

$API_URL = "https://finance-backend-32gc.onrender.com"
$ML_URL = "https://finalfinallll-bkfqhebrgubjf5d7.italynorth-01.azurewebsites.net"
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
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
        }
        
        $response = Invoke-RestMethod @params
        Write-TestResult -Name $Name -Expected $ExpectedStatus -Actual 200 `
            -Passed ($ExpectedStatus -eq 200 -or $ExpectedStatus -eq 201)
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.Value__
        Write-TestResult -Name $Name -Expected $ExpectedStatus -Actual $statusCode `
            -Passed ($statusCode -eq $ExpectedStatus)
        return $null
    }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "   ML PREDICTIONS INTEGRATION TESTS" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# ============================================
# 1. SETUP - Login
# ============================================
Write-Host "`n=== 1. SETUP ===`n" -ForegroundColor Yellow

$loginResult = Test-Endpoint -Name "Login as USER" `
    -Method "POST" -Path "/api/auth/login" `
    -Body @{ email = "user@test.com"; password = "user123" } `
    -ExpectedStatus 200

if (-not $loginResult) {
    Write-Host "`nERROR: Cannot login! Stopping tests." -ForegroundColor Red
    exit 1
}

$userToken = $loginResult.data.token
$userHeaders = @{ "Authorization" = "Bearer $userToken" }

Write-Host "User ID: $($loginResult.data.user.id)" -ForegroundColor Cyan
Write-Host "Token obtained successfully`n" -ForegroundColor Green

# ============================================
# 2. ML BACKEND HEALTH CHECK
# ============================================
Write-Host "`n=== 2. ML BACKEND HEALTH CHECK ===`n" -ForegroundColor Yellow

try {
    $mlHealth = Invoke-RestMethod -Uri "$ML_URL/" -Method GET -ErrorAction Stop
    Write-Host "ML Backend Status: $($mlHealth.status)" -ForegroundColor Green
    Write-TestResult -Name "ML backend is accessible" -Expected "OK" -Actual "OK" -Passed $true
}
catch {
    Write-Host "ML Backend is NOT accessible!" -ForegroundColor Red
    Write-TestResult -Name "ML backend is accessible" -Expected "OK" -Actual "FAIL" -Passed $false
}

# ============================================
# 3. CHECK IF USER HAS ENOUGH TRANSACTIONS
# ============================================
Write-Host "`n=== 3. CHECK TRANSACTION HISTORY ===`n" -ForegroundColor Yellow

$statsResult = Test-Endpoint -Name "Get transaction statistics" `
    -Method "GET" -Path "/api/transactions/stats" `
    -Headers $userHeaders -ExpectedStatus 200

if ($statsResult) {
    $monthlyData = $statsResult.data.monthly
    Write-Host "User has $($monthlyData.Count) months of data" -ForegroundColor Cyan
    
    if ($monthlyData.Count -ge 2) {
        Write-TestResult -Name "User has enough data for prediction (2+ months)" `
            -Expected ">=2" -Actual $monthlyData.Count -Passed $true
    } else {
        Write-TestResult -Name "User has enough data for prediction (2+ months)" `
            -Expected ">=2" -Actual $monthlyData.Count -Passed $false
        Write-Host "`nWARNING: User doesn't have enough transaction history for ML prediction!" -ForegroundColor Yellow
        Write-Host "Creating sample transactions...`n" -ForegroundColor Yellow
        
        # Create sample transactions for testing
        $categories = Invoke-RestMethod -Uri "$API_URL/api/categories/all" -Headers $userHeaders
        $expenseCat = $categories.data | Where-Object { $_.type -eq "expense" } | Select-Object -First 1
        
        $dates = @("2024-10-15", "2024-11-15", "2024-12-15")
        foreach ($date in $dates) {
            Invoke-RestMethod -Uri "$API_URL/api/transactions" -Method POST `
                -Headers $userHeaders -ContentType "application/json" `
                -Body (@{
                    amount = Get-Random -Min 100 -Max 500
                    type = "expense"
                    category_id = $expenseCat.id
                    description = "Test transaction for ML"
                    date = $date
                } | ConvertTo-Json) -ErrorAction SilentlyContinue | Out-Null
        }
        
        Write-Host "Sample transactions created!`n" -ForegroundColor Green
    }
}

# ============================================
# 4. PREDICTIONS - POSITIVE SCENARIOS
# ============================================
Write-Host "`n=== 4. PREDICTIONS - POSITIVE ===`n" -ForegroundColor Yellow

# 4.1 Get prediction with default model (linear)
$prediction1 = Test-Endpoint -Name "Get prediction (default linear model)" `
    -Method "POST" -Path "/api/predict" `
    -Headers $userHeaders -ExpectedStatus 200

if ($prediction1) {
    Write-Host "  Predicted Month: $($prediction1.data.predicted_month)" -ForegroundColor Cyan
    Write-Host "  Predicted Amount: $($prediction1.data.predicted_amount)" -ForegroundColor Cyan
    Write-Host "  Model Type: $($prediction1.data.model_type)" -ForegroundColor Cyan
}

# 4.2 Get prediction with random forest model
$prediction2 = Test-Endpoint -Name "Get prediction (random forest model)" `
    -Method "POST" -Path "/api/predict" `
    -Body @{ model_type = "rf" } `
    -Headers $userHeaders -ExpectedStatus 200

if ($prediction2) {
    Write-Host "  Predicted Month: $($prediction2.data.predicted_month)" -ForegroundColor Cyan
    Write-Host "  Predicted Amount: $($prediction2.data.predicted_amount)" -ForegroundColor Cyan
    Write-Host "  Model Type: $($prediction2.data.model_type)" -ForegroundColor Cyan
}

# 4.3 Get prediction history
$history = Test-Endpoint -Name "Get prediction history" `
    -Method "GET" -Path "/api/predict/history" `
    -Headers $userHeaders -ExpectedStatus 200

if ($history) {
    $predictions = $history.data.predictions
    Write-Host "  Found $($predictions.Count) predictions in history" -ForegroundColor Cyan
    
    if ($predictions.Count -gt 0) {
        Write-Host "  Latest prediction:" -ForegroundColor Cyan
        Write-Host "    Month: $($predictions[0].month)" -ForegroundColor Gray
        Write-Host "    Amount: $($predictions[0].amount)" -ForegroundColor Gray
        Write-Host "    Model: $($predictions[0].model)" -ForegroundColor Gray
    }
}

# 4.4 Get prediction history with limit
Test-Endpoint -Name "Get prediction history with limit=3" `
    -Method "GET" -Path "/api/predict/history?limit=3" `
    -Headers $userHeaders -ExpectedStatus 200

# ============================================
# 5. PREDICTIONS - NEGATIVE SCENARIOS
# ============================================
Write-Host "`n=== 5. PREDICTIONS - NEGATIVE ===`n" -ForegroundColor Yellow

# 5.1 Predict without authentication
Test-Endpoint -Name "Predict without auth (should fail)" `
    -Method "POST" -Path "/api/predict" `
    -ExpectedStatus 401

# 5.2 Predict with invalid token
$invalidHeaders = @{ "Authorization" = "Bearer invalidtoken123" }
Test-Endpoint -Name "Predict with invalid token (should fail)" `
    -Method "POST" -Path "/api/predict" `
    -Headers $invalidHeaders -ExpectedStatus 401

# 5.3 Predict with invalid model type
Test-Endpoint -Name "Predict with invalid model type (should fail)" `
    -Method "POST" -Path "/api/predict" `
    -Body @{ model_type = "invalid_model" } `
    -Headers $userHeaders -ExpectedStatus 400

# 5.4 History without authentication
Test-Endpoint -Name "Get history without auth (should fail)" `
    -Method "GET" -Path "/api/predict/history" `
    -ExpectedStatus 401

# ============================================
# 6. EDGE CASES
# ============================================
Write-Host "`n=== 6. EDGE CASES ===`n" -ForegroundColor Yellow

# 6.1 Predict with explicit linear model
Test-Endpoint -Name "Predict with explicit model_type=linear" `
    -Method "POST" -Path "/api/predict" `
    -Body @{ model_type = "linear" } `
    -Headers $userHeaders -ExpectedStatus 200

# 6.2 History with limit=0
Test-Endpoint -Name "Get history with limit=0" `
    -Method "GET" -Path "/api/predict/history?limit=0" `
    -Headers $userHeaders -ExpectedStatus 200

# 6.3 History with large limit
Test-Endpoint -Name "Get history with limit=100" `
    -Method "GET" -Path "/api/predict/history?limit=100" `
    -Headers $userHeaders -ExpectedStatus 200

# ============================================
# 7. INTEGRATION FLOW TEST
# ============================================
Write-Host "`n=== 7. FULL INTEGRATION FLOW ===`n" -ForegroundColor Yellow

Write-Host "Testing complete user flow..." -ForegroundColor Cyan

# Step 1: User has transactions
$transCount = (Invoke-RestMethod -Uri "$API_URL/api/transactions" -Headers $userHeaders).data.count
Write-Host "  1. User has $transCount transactions" -ForegroundColor Gray

# Step 2: Request prediction
Write-Host "  2. Requesting ML prediction..." -ForegroundColor Gray
$flowPrediction = Invoke-RestMethod -Uri "$API_URL/api/predict" -Method POST `
    -Headers $userHeaders -ContentType "application/json" `
    -Body (@{ model_type = "linear" } | ConvertTo-Json) -ErrorAction SilentlyContinue

if ($flowPrediction) {
    Write-Host "  3. Received prediction: $($flowPrediction.data.predicted_amount) for $($flowPrediction.data.predicted_month)" -ForegroundColor Gray
    Write-TestResult -Name "Complete integration flow works" -Expected "OK" -Actual "OK" -Passed $true
} else {
    Write-Host "  3. Prediction failed!" -ForegroundColor Red
    Write-TestResult -Name "Complete integration flow works" -Expected "OK" -Actual "FAIL" -Passed $false
}

# ============================================
# 8. PERFORMANCE TEST
# ============================================
Write-Host "`n=== 8. PERFORMANCE TEST ===`n" -ForegroundColor Yellow

Write-Host "Measuring prediction response time..." -ForegroundColor Cyan

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $perfTest = Invoke-RestMethod -Uri "$API_URL/api/predict" -Method POST `
        -Headers $userHeaders -ContentType "application/json" `
        -Body (@{ model_type = "linear" } | ConvertTo-Json)
    $stopwatch.Stop()
    
    $responseTime = $stopwatch.ElapsedMilliseconds
    Write-Host "  Response time: $responseTime ms" -ForegroundColor Cyan
    
    if ($responseTime -lt 5000) {
        Write-TestResult -Name "Prediction response time < 5s" `
            -Expected "<5000ms" -Actual "${responseTime}ms" -Passed $true
    } else {
        Write-TestResult -Name "Prediction response time < 5s" `
            -Expected "<5000ms" -Actual "${responseTime}ms" -Passed $false
    }
}
catch {
    $stopwatch.Stop()
    Write-TestResult -Name "Prediction response time < 5s" `
        -Expected "<5000ms" -Actual "ERROR" -Passed $false
}

# ============================================
# 9. TOKEN VERIFICATION
# ============================================
Write-Host "`n=== 9. TOKEN FOR YULIA ===`n" -ForegroundColor Yellow

Write-Host "Generating service token for ML backend..." -ForegroundColor Cyan
Write-Host "`nYulia needs this token in her .env:" -ForegroundColor Yellow
Write-Host "BACKEND_A_URL=https://finance-backend-32gc.onrender.com" -ForegroundColor White
Write-Host "BACKEND_A_TOKEN=$userToken" -ForegroundColor White

# Test if token works for stats endpoint
Write-Host "`nVerifying token works for /api/transactions/stats..." -ForegroundColor Cyan
try {
    $statsTest = Invoke-RestMethod -Uri "$API_URL/api/transactions/stats" `
        -Headers $userHeaders -ErrorAction Stop
    Write-Host "Token verification: SUCCESS" -ForegroundColor Green
    Write-TestResult -Name "Token works for stats endpoint" `
        -Expected "OK" -Actual "OK" -Passed $true
}
catch {
    Write-Host "Token verification: FAILED" -ForegroundColor Red
    Write-TestResult -Name "Token works for stats endpoint" `
        -Expected "OK" -Actual "FAIL" -Passed $false
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

Write-Host "`n=== NEXT STEPS ===`n" -ForegroundColor Yellow

if ($failedTests -eq 0) {
    Write-Host "ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "`n1. Send token to Yulia (shown above)" -ForegroundColor White
    Write-Host "2. Yulia adds to her .env on Azure" -ForegroundColor White
    Write-Host "3. Test from frontend!" -ForegroundColor White
} elseif ($percentage -ge 80) {
    Write-Host "Most tests passed, but check failures above." -ForegroundColor Yellow
} else {
    Write-Host "CRITICAL: Several tests failed. Check configuration!" -ForegroundColor Red
}

Write-Host "`n"