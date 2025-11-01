@echo off
title ENHANCED MINER - Works Everywhere
color 0A

REM Change to script directory
cd /d "%~dp0"

cls
echo ================================================================
echo  ENHANCED MINER DEPLOYMENT
echo  Works on ALL PCs - Handles permission issues gracefully
echo ================================================================
echo.
echo This enhanced version:
echo  - Tries multiple deployment locations
echo  - Falls back to user folders if admin fails
echo  - Only installs persistence that works
echo  - Shows clear status for everything
echo  - Includes working watchdog
echo.
echo Safe Mode: 40%% CPU, 2 threads
echo.
pause

echo.
echo Starting enhanced deployment...
echo.

REM Set test mode for safety
set SAFE_TEST_MODE=1

powershell -NoExit -ExecutionPolicy Bypass -File "DEPLOY_ENHANCED.ps1" -TestMode -Debug

pause
