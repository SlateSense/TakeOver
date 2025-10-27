@echo off
REM ================================================================================================
REM COMPLETE MINER REMOVAL - Nuclear Option
REM ================================================================================================
REM This script COMPLETELY removes the miner and ALL traces
REM Use this if you need to clean up after competition or testing
REM ================================================================================================

title Complete Miner Removal
color 0C

echo.
echo +==============================================================+
echo |                                                              |
echo |             🗑  COMPLETE MINER REMOVAL 🗑                   |
echo |                                                              |
echo +==============================================================+
echo.
echo This will COMPLETELY remove the miner and ALL traces:
echo.
echo   • Stop all miner processes
echo   • Remove 30+ persistence mechanisms
echo   • Delete all miner files
echo   • Clean registry entries
echo   • Restore Windows Defender
echo   • Re-enable disabled services
echo   • Remove exclusions
echo   • Clear all logs and traces
echo.
echo [!]  WARNING: This cannot be undone!
echo.
set /p confirm="Type YES to confirm complete removal: "

if /i not "%confirm%"=="YES" (
    echo.
    echo Removal cancelled.
    pause
    exit /b
)

REM Check admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [X] ERROR: Administrator rights required!
    echo    Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

cls
echo.
echo +==============================================================+
echo |              COMPLETE REMOVAL IN PROGRESS...                 |
echo +==============================================================+
echo.

REM Run PowerShell removal script
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0COMPLETE_UNINSTALL.ps1"

if %errorLevel% equ 0 (
    echo.
    echo +==============================================================+
    echo |                 [OK] REMOVAL COMPLETED                         |
    echo +==============================================================+
    echo.
    echo All miner components have been removed.
    echo System has been restored to original state.
    echo.
    echo RECOMMENDATION: Restart PC to complete cleanup.
    echo.
) else (
    echo.
    echo +==============================================================+
    echo |                 [!]  REMOVAL HAD ISSUES                      |
    echo +==============================================================+
    echo.
    echo Some components may not have been removed.
    echo Check the log above for details.
    echo.
)

pause
