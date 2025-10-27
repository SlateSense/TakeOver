@echo off
title ULTIMATE MINER - One-Click Deployment
echo.
echo  ██+   ██+██+  ████████+██+███+   ███+ █████+ ████████+███████+
echo  ██|   ██|██|  +==██+==+██|████+ ████|██+==██++==██+==+██+====+
echo  ██|   ██|██|     ██|   ██|██+████+██|███████|   ██|   █████+  
echo  ██|   ██|██|     ██|   ██|██|+██++██|██+==██|   ██|   ██+==+  
echo  +██████++███████+██|   ██|██| +=+ ██|██|  ██|   ██|   ███████+
echo   +=====+ +======++=+   +=++=+     +=++=+  +=+   +=+   +======+
echo.
echo        ONE-CLICK DEPLOYMENT FOR RED TEAM COMPETITION
echo.
echo ================================================================
echo  Deploying ultimate miner with all features...
echo ================================================================
echo.

REM Check if required files exist
if not exist "%~dp0DEPLOY_ULTIMATE.ps1" (
    echo.
    echo [ERROR] DEPLOY_ULTIMATE.ps1 not found!
    echo    Make sure all files are in the same folder.
    echo.
    pause
    exit /b 1
)

if not exist "%~dp0xmrig.exe" (
    echo.
    echo [ERROR] xmrig.exe not found!
    echo    Make sure xmrig.exe is in the same folder.
    echo.
    pause
    exit /b 1
)

echo.
echo [START] Starting deployment with DEBUG mode...
echo    (Window will stay visible so you can see what happens)
echo.
pause

REM Run the PowerShell script with DEBUG parameter (shows window and errors)
powershell.exe -ExecutionPolicy Bypass -NoExit -Command "& '%~dp0DEPLOY_ULTIMATE.ps1' -Debug"

REM Note: Window stays open in debug mode
REM You'll see all logs and any errors
REM Close the window when you're done checking
