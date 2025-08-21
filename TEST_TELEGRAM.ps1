# Test Telegram Monitoring Functionality
# Run this to verify your Telegram setup works

param(
    [string]$TelegramToken = "7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE",
    [string]$ChatID = "8112985977"
)

Write-Host "Testing Telegram Bot Configuration..." -ForegroundColor Yellow

# Test message
$testMessage = @"
<b>🧪 TELEGRAM TEST</b>
<b>PC</b>: $env:COMPUTERNAME
<b>Time</b>: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
<b>Status</b>: ✅ Telegram monitoring is working!

This is a test message from your V6 Ultimate monitoring system.
"@

try {
    $uri = "https://api.telegram.org/bot$TelegramToken/sendMessage"
    $body = @{
        chat_id = $ChatID
        text = $testMessage
        parse_mode = "HTML"
    } | ConvertTo-Json
    
    Write-Host "Sending test message..." -ForegroundColor Cyan
    
    $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json"
    
    if ($response.ok) {
        Write-Host "✅ SUCCESS: Test message sent successfully!" -ForegroundColor Green
        Write-Host "Check your Telegram app for the test message." -ForegroundColor Green
        Write-Host ""
        Write-Host "Telegram Configuration:" -ForegroundColor Yellow
        Write-Host "Bot Token: $TelegramToken" -ForegroundColor White
        Write-Host "Chat ID: $ChatID" -ForegroundColor White
    } else {
        Write-Host "❌ ERROR: Failed to send message" -ForegroundColor Red
        Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ ERROR: Exception occurred" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "1. Invalid bot token" -ForegroundColor White
    Write-Host "2. Invalid chat ID" -ForegroundColor White
    Write-Host "3. Bot not started in Telegram" -ForegroundColor White
    Write-Host "4. Internet connection issues" -ForegroundColor White
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
