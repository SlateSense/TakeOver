@echo off
title SIMPLE MINER TEST
color 0E
echo ================================================================
echo  SIMPLE MINER TEST - Direct XMRig Launch
echo ================================================================
echo.

REM Change to script directory
cd /d "%~dp0"
echo Current directory: %CD%
echo.

REM Check for admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] NOT running as Administrator!
    echo Please right-click and "Run as administrator"
    pause
    exit /b
)
echo [OK] Running as Administrator
echo.

REM Check for xmrig.exe
if not exist "xmrig.exe" (
    echo [ERROR] xmrig.exe not found in this folder!
    echo Please make sure xmrig.exe is in: %CD%
    pause
    exit /b
)
echo [OK] xmrig.exe found
echo.

REM Check if already running
tasklist /FI "IMAGENAME eq xmrig.exe" 2>NUL | find /I /N "xmrig.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [WARNING] XMRig is already running!
    echo Killing existing process...
    taskkill /F /IM xmrig.exe >nul 2>&1
    timeout /t 2 >nul
)

echo ================================================================
echo  STARTING MINER (Simple Mode)
echo ================================================================
echo.
echo Pool: gulf.moneroocean.stream:10128
echo Algorithm: RandomX (Monero)
echo.
echo Press Ctrl+C to stop mining
echo ================================================================
echo.
timeout /t 2 >nul

REM Start miner with basic settings
xmrig.exe -o gulf.moneroocean.stream:10128 -u 49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon -p %COMPUTERNAME%-TEST -a rx/0 -k --donate-level 0 --cpu-max-threads-hint=75

REM If we get here, miner stopped
echo.
echo.
echo ================================================================
echo [MINER STOPPED]
echo ================================================================
pause
