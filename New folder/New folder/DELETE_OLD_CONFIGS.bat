@echo off
title DELETE OLD CONFIG FILES
color 0C

echo ================================================================
echo  DELETE OLD LOCKED CONFIG FILES
echo  This removes corrupted/locked config.json files
echo ================================================================
echo.

echo Deleting old config files from all deployment locations...
echo.

del /f /q "C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json" 2>nul
if %ERRORLEVEL%==0 (echo [OK] Deleted: WindowsUpdate) else (echo [SKIP] WindowsUpdate)

del /f /q "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv\config.json" 2>nul
if %ERRORLEVEL%==0 (echo [OK] Deleted: AudioSrv) else (echo [SKIP] AudioSrv)

del /f /q "C:\ProgramData\Microsoft\Network\Downloader\config.json" 2>nul
if %ERRORLEVEL%==0 (echo [OK] Deleted: Network Downloader) else (echo [SKIP] Network Downloader)

del /f /q "C:\Users\%USERNAME%\AppData\Local\Microsoft\Windows\PowerShell\config.json" 2>nul
if %ERRORLEVEL%==0 (echo [OK] Deleted: PowerShell) else (echo [SKIP] PowerShell)

del /f /q "C:\Users\%USERNAME%\AppData\Local\Microsoft\Windows\Defender\config.json" 2>nul
if %ERRORLEVEL%==0 (echo [OK] Deleted: Defender) else (echo [SKIP] Defender)

del /f /q "C:\Users\%USERNAME%\AppData\Roaming\Microsoft\Windows\Templates\config.json" 2>nul
if %ERRORLEVEL%==0 (echo [OK] Deleted: Templates) else (echo [SKIP] Templates)

del /f /q "C:\Users\%USERNAME%\AppData\Local\Temp\WindowsUpdateCache\config.json" 2>nul
if %ERRORLEVEL%==0 (echo [OK] Deleted: Temp) else (echo [SKIP] Temp)

echo.
echo ================================================================
echo  Old config files deleted!
echo ================================================================
echo.
echo Now run: START_ULTIMATE_FIXED.bat
echo.
pause
