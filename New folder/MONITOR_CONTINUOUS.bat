@echo off
title Miner Continuous Monitor - Updates Every 10s
color 0A

echo Starting continuous monitoring...
echo Press Ctrl+C to stop
echo.

REM Continuous monitoring - updates every 10 seconds
powershell.exe -ExecutionPolicy Bypass -File "%~dp0CHECK_MINER_STATUS.ps1" -Loop
