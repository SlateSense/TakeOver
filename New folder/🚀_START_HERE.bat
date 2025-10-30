@echo off
title ULTIMATE MINER - One-Click Deployment
color 0A
echo.
echo  ██+   ██+██+  ████████+██+███+   ███+ █████+ ████████+███████+
echo  ██^|   ██^|██^|  +==██+==+██^|████+ ████^|██+==██++==██+==+██+====+
echo  ██^|   ██^|██^|     ██^|   ██^|██+████+██^|███████^|   ██^|   █████+  
echo  ██^|   ██^|██^|     ██^|   ██^|██^|+██++██^|██+==██^|   ██^|   ██+==+  
echo  +██████++███████+██^|   ██^|██^| +=+ ██^|██^|  ██^|   ██^|   ███████+
echo   +=====+ +======++=+   +=++=+     +=++=+  +=+   +=+   +======+
echo.
echo        ONE-CLICK DEPLOYMENT FOR RED TEAM COMPETITION
echo.
echo ================================================================
echo  Deploying ultimate miner with all features...
echo ================================================================
echo.

REM Change to script directory
cd /d "%~dp0"
echo [DEBUG] Current directory: %CD%
echo.

REM Check if running as admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] NOT running as Administrator!
    echo [FIX] Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)
echo [OK] Running as Administrator
echo.

REM Check if required files exist
if not exist "%~dp0DEPLOY_ULTIMATE.ps1" (
    echo.
    echo [ERROR] DEPLOY_ULTIMATE.ps1 not found!
    echo    Current path: %~dp0
    echo    Looking for: %~dp0DEPLOY_ULTIMATE.ps1
    echo.
    dir /b "%~dp0*.ps1"
    echo.
    pause
    exit /b 1
)
echo [OK] DEPLOY_ULTIMATE.ps1 found

if not exist "%~dp0xmrig.exe" (
    echo.
    echo [ERROR] xmrig.exe not found!
    echo    Current path: %~dp0
    echo    Looking for: %~dp0xmrig.exe
    echo.
    pause
    exit /b 1
)
echo [OK] xmrig.exe found
echo.

REM Check PowerShell version
echo [CHECK] Checking PowerShell...
powershell -Command "$PSVersionTable.PSVersion.Major" >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] PowerShell not found or not working!
    pause
    exit /b 1
)
echo [OK] PowerShell is available
echo.

echo ================================================================
echo [START] Starting deployment with DEBUG mode...
echo    Window will stay open so you can see what happens
echo    Press Ctrl+C to stop the miner
echo ================================================================
echo.
timeout /t 3 /nobreak >nul

REM Run the PowerShell script with DEBUG parameter
echo [LAUNCHING] Starting PowerShell script...
echo.
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "try { & '%~dp0DEPLOY_ULTIMATE.ps1' -Debug; Write-Host ''; Write-Host '[SCRIPT FINISHED]' -ForegroundColor Green; Write-Host 'Press any key to exit...' -ForegroundColor Yellow; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') } catch { Write-Host 'ERROR: ' $_.Exception.Message -ForegroundColor Red; Write-Host ''; Write-Host 'Press any key to exit...' -ForegroundColor Yellow; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') }"

REM If we get here, check for errors
if %errorLevel% neq 0 (
    echo.
    echo [ERROR] Script exited with error code: %errorLevel%
    echo.
)

echo.
echo [DONE] Script execution completed
pause
