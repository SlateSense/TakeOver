@echo off
title Miner Status Checker
color 0A

REM Quick status check - just run this!
powershell.exe -ExecutionPolicy Bypass -File "%~dp0CHECK_MINER_STATUS.ps1"

echo.
echo Press any key to exit...
pause >nul
