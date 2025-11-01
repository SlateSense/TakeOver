@echo off
title CHECK DEPLOYED CONFIG
color 0B

echo ================================================================
echo  CHECKING DEPLOYED CONFIGURATION
echo ================================================================
echo.

set CONFIG="C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json"

if exist %CONFIG% (
    echo Config file found!
    echo.
    echo Contents:
    echo ----------------------------------------------------------------
    type %CONFIG%
    echo ----------------------------------------------------------------
) else (
    echo [ERROR] Config file not found at: %CONFIG%
    echo Run deployment first!
)

echo.
pause
