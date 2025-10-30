@echo off
title ULTIMATE MINER - VERBOSE DEBUG MODE
color 0E
echo ================================================================
echo  ULTIMATE MINER - VERBOSE DEBUG MODE
echo  This will show EXACTLY what's happening
echo ================================================================
echo.

cd /d "%~dp0"

REM Check admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Need Administrator!
    pause
    exit /b
)
echo [OK] Running as Administrator
echo.

REM Check files
if not exist "DEPLOY_ULTIMATE.ps1" (
    echo [ERROR] DEPLOY_ULTIMATE.ps1 not found!
    pause
    exit /b
)
echo [OK] DEPLOY_ULTIMATE.ps1 found

if not exist "xmrig.exe" (
    echo [ERROR] xmrig.exe not found!
    pause
    exit /b
)
echo [OK] xmrig.exe found
echo.

echo ================================================================
echo [LAUNCHING] PowerShell with MAXIMUM VERBOSITY
echo ================================================================
echo.
echo You will see EVERY step the script takes
echo If it fails, you'll see the exact error
echo.
timeout /t 3 >nul

REM Launch with maximum debugging
powershell.exe -NoExit -ExecutionPolicy Bypass -Command "$VerbosePreference = 'Continue'; $DebugPreference = 'Continue'; $ErrorActionPreference = 'Continue'; Write-Host '========================================' -ForegroundColor Cyan; Write-Host 'VERBOSE MODE - All output will be shown' -ForegroundColor Cyan; Write-Host '========================================' -ForegroundColor Cyan; Write-Host ''; try { Write-Host '[1] Loading script...' -ForegroundColor Yellow; Write-Host '[2] Executing DEPLOY_ULTIMATE.ps1 with -Debug...' -ForegroundColor Yellow; Write-Host ''; & '%~dp0DEPLOY_ULTIMATE.ps1' -Debug; Write-Host ''; Write-Host '========================================' -ForegroundColor Green; Write-Host '[COMPLETED] Script finished' -ForegroundColor Green; Write-Host '========================================' -ForegroundColor Green; } catch { Write-Host ''; Write-Host '========================================' -ForegroundColor Red; Write-Host '[ERROR] Script failed!' -ForegroundColor Red; Write-Host '========================================' -ForegroundColor Red; Write-Host 'Error Message: ' $_.Exception.Message -ForegroundColor Red; Write-Host 'At Line: ' $_.InvocationInfo.ScriptLineNumber -ForegroundColor Red; Write-Host 'Full Error: ' $_ -ForegroundColor Red; Write-Host '========================================' -ForegroundColor Red; } Write-Host ''; Write-Host 'Press any key to exit...' -ForegroundColor Yellow; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')"

echo.
echo [DONE] Check the output above
pause
