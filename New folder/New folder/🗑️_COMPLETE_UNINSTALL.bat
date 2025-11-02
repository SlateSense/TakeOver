@echo off
title ULTIMATE MINER REMOVAL TOOL
color 0C
setlocal enabledelayedexpansion

:: ================================================================
::  ULTIMATE MINER REMOVAL TOOL
::  Completely removes all miner components
:: ================================================================

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [X] ERROR: Administrator rights required!
    echo     Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo.
echo ================================================================
echo  ULTIMATE MINER REMOVAL TOOL
echo  This will completely remove all miner components
echo ================================================================
echo.
echo MAKE SURE TO RUN AS ADMINISTRATOR!
echo.
pause

:: ================================================================
:: 1. KILL ALL MINER PROCESSES (MULTIPLE METHODS)
:: ================================================================
echo.
echo [1/6] Terminating all miner processes...

:kill_loop
set killed=0

:: Method 1: Standard taskkill
taskkill /f /im audiodg.exe >nul 2>&1 && set killed=1
taskkill /f /im xmrig.exe >nul 2>&1 && set killed=1

:: Method 2: WMIC process termination
wmic process where "name='audiodg.exe'" delete >nul 2>&1 && set killed=1
wmic process where "name='xmrig.exe'" delete >nul 2>&1 && set killed=1

:: Method 3: TASKKILL with filter
taskkill /f /fi "IMAGENAME eq audiodg.exe" >nul 2>&1 && set killed=1
taskkill /f /fi "IMAGENAME eq xmrig.exe" >nul 2>&1 && set killed=1

:: If we killed something, check again
if %killed% equ 1 (
    timeout /t 1 >nul
    tasklist | findstr /i "audiodg.exe xmrig.exe" >nul && goto :kill_loop
)

:: ================================================================
:: 2. DISABLE AND REMOVE SCHEDULED TASKS
:: ================================================================
echo.
echo [2/6] Removing scheduled tasks and persistence...

for /f "tokens=*" %%a in ('schtasks /query /fo list 2^>nul ^| find "TaskName:"') do (
    for /f "tokens=2 delims=:" %%b in ("%%a") do (
        set "task=%%b"
        set "task=!task: =!"
        echo !task! | findstr /i "Windows Audio System Maintenanc" >nul && (
            echo Disabling task: !task!
            schtasks /change /tn "!task!" /disable >nul 2>&1
            schtasks /delete /tn "!task!" /f >nul 2>&1
        )
    )
)

:: ================================================================
:: 3. REMOVE FILES AND FOLDERS
:: ================================================================
echo.
echo [3/6] Removing miner files...

set "locations=(
    "C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe"
    "C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json"
    "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv"
    "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsAudioService.vbs"
    "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\WindowsAudioService.vbs"
    "%USERPROFILE%\AppData\Local\Temp\watchdog.log"
    "%TEMP%\watchdog.log"
    "%TEMP%\*.ps1"
    "%TEMP%\*.vbs"
    "%TEMP%\*.bat"
)"

:: Take ownership and remove files
for %%i in (%locations%) do (
    if exist "%%~i" (
        echo Removing: %%~i
        takeown /f "%%~i" /r /d y >nul 2>&1
        icacls "%%~i" /grant administrators:F /t /c /q >nul 2>&1
        if exist "%%~i\" (
            rd /s /q "%%~i" 2>nul
        ) else (
            del /f /q "%%~i" 2>nul
        )
    )
)

:: ================================================================
:: 4. REMOVE REGISTRY ENTRIES
:: ================================================================
echo.
echo [4/6] Cleaning registry...

set "reg_keys=(
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
    "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run"
)"

for %%k in %reg_keys% do (
    for /f "tokens=2*" %%a in ('reg query "%%~k" 2^>nul ^| findstr /i "AudioSvc WindowsUpdate SystemMaintenance"') do (
        echo Removing registry entry: %%~k\%%a
        reg delete "%%~k" /v "%%a" /f >nul 2>&1
    )
)

:: ================================================================
:: 5. KILL EXPLORER.EXE TO PREVENT RESTART
:: ================================================================
echo.
echo [5/6] Preventing auto-restart...

taskkill /f /im explorer.exe >nul 2>&1
start "" "explorer.exe"

:: ================================================================
:: 6. FINAL CLEANUP
:: ================================================================
echo.
echo [6/6] Final cleanup...

:: Flush DNS and reset network
ipconfig /flushdns >nul 2>&1
netsh winsock reset >nul 2>&1

:: Final check for any remaining processes
tasklist | findstr /i "audiodg xmrig" >nul
if errorlevel 1 (
    echo.
    echo [SUCCESS] All miner components have been removed!
) else (
    echo.
    echo [WARNING] Some miner processes are still running.
    echo           Please restart your computer to complete the removal.
)

echo.
echo ================================================================
echo  REMOVAL COMPLETE
echo ================================================================
echo.
echo For best results, please restart your computer.
echo.
pause