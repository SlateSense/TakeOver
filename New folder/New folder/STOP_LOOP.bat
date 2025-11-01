@echo off
title STOP THE RESTART LOOP
color 0C

echo ================================================================
echo  STOPPING RESTART LOOP
echo ================================================================
echo.
echo Killing all miner processes and PowerShell watchdogs...
echo.

REM Kill miner
taskkill /F /IM xmrig.exe 2>nul
taskkill /F /IM audiodg.exe 2>nul

REM Kill PowerShell processes (watchdog)
echo Stopping watchdog...
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq powershell.exe" /FO LIST ^| findstr "PID:"') do (
    taskkill /F /PID %%a 2>nul
)

echo.
echo [DONE] All processes stopped!
echo.
echo The restart loop is now stopped.
echo.
pause
