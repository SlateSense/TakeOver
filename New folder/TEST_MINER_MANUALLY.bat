@echo off
title TEST MINER MANUALLY
color 0B

cd /d "%~dp0"

echo ================================================================
echo  TEST IF XMRIG CAN RUN
echo  This will test if Windows Defender is blocking the miner
echo ================================================================
echo.
echo STEP 1: First, add Defender exclusions
echo Run ADD_EXCLUSIONS_FIRST.bat before this test
echo.
pause

echo.
echo STEP 2: Testing miner startup...
echo.

REM Try to run miner directly
echo Starting xmrig.exe for 10 seconds...
echo If it crashes immediately, Defender is blocking it.
echo.

start /B xmrig.exe --version

timeout /t 3

echo.
echo Checking if xmrig.exe is running...
tasklist /FI "IMAGENAME eq xmrig.exe" | find /I "xmrig.exe"

if %ERRORLEVEL%==0 (
    echo.
    echo ================================================================
    echo  SUCCESS! The miner is running!
    echo ================================================================
    echo.
    echo This means:
    echo  - Windows Defender is NOT blocking it
    echo  - The miner binary works correctly
    echo  - You can proceed with deployment
    echo.
    echo Killing test miner...
    taskkill /F /IM xmrig.exe >nul 2>&1
) else (
    echo.
    echo ================================================================
    echo  FAILED! The miner is NOT running!
    echo ================================================================
    echo.
    echo This means:
    echo  - Windows Defender is probably blocking it
    echo  - OR the miner crashed due to missing dependencies
    echo.
    echo SOLUTIONS:
    echo  1. Run ADD_EXCLUSIONS_FIRST.bat
    echo  2. Temporarily disable Windows Defender real-time protection
    echo  3. Install Visual C++ Redistributable (if missing)
    echo.
)

echo.
pause
