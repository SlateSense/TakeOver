@echo off
setlocal enabledelayedexpansion

:: ================================
:: PerfBoost V5 – Ultimate Tuner
:: For Intel i5-14400 (Monero Mining)
:: ================================

:: === Paths ===
set "XTU_DIR=%ProgramFiles(x86)%\Intel\Intel(R) Extreme Tuning Utility"
set "XTU_PROFILE=C:\ProgramData\WindowsUpdater\xtu_profile.xml"
set "LOG_FILE=%TEMP%\perfboost_v5.log"
set "XTU_INSTALLER=%TEMP%\XTUSetup.exe"

:: === Logging ===
echo [*] PerfBoost V5 run at %date% %time% >> "%LOG_FILE%"

:: === Admin Check ===
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' neq '0' (
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\elevate.vbs"
    echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%temp%\elevate.vbs"
    "%temp%\elevate.vbs"
    del "%temp%\elevate.vbs"
    exit /b
)

:: === Install Intel XTU if Missing ===
if not exist "%XTU_DIR%\XtuService.exe" (
    echo [*] Installing Intel XTU... >> "%LOG_FILE%"
    powershell -Command ^
      "Invoke-WebRequest -Uri 'https://downloadmirror.intel.com/29183/eng/XTUSetup.exe' -OutFile '%XTU_INSTALLER%'"
    start /wait "" "%XTU_INSTALLER%" /quiet /norestart
    del "%XTU_INSTALLER%"
)

:: === Apply Intel XTU Profile ===
if exist "%XTU_PROFILE%" (
    "%XTU_DIR%\XtuCli.exe" -importSettings "%XTU_PROFILE%"
    echo [*] Intel XTU Profile Applied >> "%LOG_FILE%"
)

:: === Power Plan ===
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul
powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul

:: === Core Parking & Throttling ===
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "CsEnabled" /t REG_DWORD /d 0 /f >nul
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul

:: === HPET Off ===
bcdedit /deletevalue useplatformclock >nul 2>&1

:: === Memory Tweaks ===
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 1 /f >nul

:: === Lock Pages in Memory (Safe Attempt) ===
set "ACCOUNT=%USERDOMAIN%\%USERNAME%"
secedit /export /cfg "%TEMP%\secpol.cfg"
powershell -Command ^
  "(Get-Content '%TEMP%\secpol.cfg') -replace 'SeLockMemoryPrivilege = .*', 'SeLockMemoryPrivilege = %ACCOUNT%' | Set-Content '%TEMP%\secpol.cfg'"
secedit /import /cfg "%TEMP%\secpol.cfg" /db secedit.sdb /overwrite
echo [*] Lock Pages in Memory applied for %ACCOUNT% >> "%LOG_FILE%"

:: === RAM Optimization Reminder ===
echo [!] Ensure XMP is enabled in BIOS for max RAM speed >> "%LOG_FILE%"

:: === Exit ===
echo [*] PerfBoost V5 complete. Ready to mine. >> "%LOG_FILE%"
exit /b
