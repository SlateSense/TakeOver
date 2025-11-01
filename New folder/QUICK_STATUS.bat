@echo off
setlocal enabledelayedexpansion
title QUICK STATUS CHECK
color 0B

:loop
cls
echo ================================================================
echo  MINER STATUS - Real-time Monitor
echo  Press Ctrl+C to exit
echo ================================================================
echo.
echo Time: %date% %time%
echo.

REM Check for miner process
tasklist /FI "IMAGENAME eq xmrig.exe" 2>NUL | find /I "xmrig.exe" >NUL
if %ERRORLEVEL%==0 (
    echo [RUNNING] xmrig.exe
    for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq xmrig.exe" /FO LIST ^| findstr "PID:"') do set PID=%%a
    for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq xmrig.exe" /FO LIST ^| findstr "Mem"') do set MEM=%%a
    echo   PID: !PID!
    echo   Memory: !MEM!
) else (
    tasklist /FI "IMAGENAME eq audiodg.exe" 2>NUL | find /I "audiodg.exe" >NUL
    if %ERRORLEVEL%==0 (
        echo [RUNNING] audiodg.exe (stealth mode)
        for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq audiodg.exe" /FO LIST ^| findstr "PID:"') do set PID=%%a
        for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq audiodg.exe" /FO LIST ^| findstr "Mem"') do set MEM=%%a
        echo   PID: !PID!
        echo   Memory: !MEM!
    ) else (
        echo [NOT RUNNING] Miner not found
    )
)

echo.
wmic cpu get loadpercentage | findstr /V "LoadPercentage" > temp_cpu.txt
set /p CPULOAD=<temp_cpu.txt
del temp_cpu.txt
echo CPU Usage: %CPULOAD%%%

echo.
echo Expected on your i5-6500:
echo  Safe mode: ~35%% CPU, ~1500-2000 H/s
echo  Full mode: ~75%% CPU, ~3500-4500 H/s

echo.
echo Checking again in 5 seconds...
timeout /t 5 /nobreak >nul
goto loop
