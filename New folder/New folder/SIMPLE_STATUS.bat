@echo off
setlocal enabledelayedexpansion
title MINER STATUS
color 0A

cls
echo ================================================================
echo  SIMPLE MINER STATUS CHECK
echo ================================================================
echo.

echo Checking for miner process...
echo.

REM Check for audiodg.exe (disguised miner)
set FOUND=0
for /f "tokens=2,5" %%a in ('tasklist /FI "IMAGENAME eq audiodg.exe" /FO CSV /NH 2^>nul') do (
    set PID=%%a
    set MEM=%%b
    set PID=!PID:"=!
    set MEM=!MEM:"=!
    echo [FOUND] audiodg.exe
    echo   Process ID: !PID!
    echo   Memory: !MEM!
    set FOUND=1
)

if !FOUND!==0 (
    echo [NOT RUNNING] Miner not found
    echo.
    echo Run START_ULTIMATE_FIXED.bat to deploy the miner
)

echo.
echo ================================================================

REM Check CPU usage
echo.
echo Overall CPU Usage:
wmic cpu get loadpercentage | findstr /V "LoadPercentage"

echo.
echo ================================================================
echo.
echo Press any key to exit...
pause >nul
