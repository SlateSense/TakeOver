@echo off
title RUN MINER MANUALLY (SIMPLE TEST)
color 0A

cd /d "%~dp0"

echo ================================================================
echo  SIMPLE MINER TEST
echo  This runs the miner with minimal config to see if it works
echo ================================================================
echo.
echo This test will:
echo  1. Run xmrig.exe with basic settings
echo  2. Show output in a window (so you can see errors)
echo  3. Run for 60 seconds
echo.
echo If you see a hashrate, the miner works!
echo If it crashes, you'll see the error.
echo.
pause

echo.
echo Creating simple test config...

REM Create minimal working config
(
echo {
echo   "autosave": true,
echo   "cpu": {
echo     "enabled": true,
echo     "huge-pages": false,
echo     "max-threads-hint": 50,
echo     "priority": 2
echo   },
echo   "donate-level": 1,
echo   "pools": [
echo     {
echo       "url": "gulf.moneroocean.stream:10128",
echo       "user": "49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon",
echo       "pass": "%COMPUTERNAME%",
echo       "keepalive": true,
echo       "tls": true
echo     }
echo   ]
echo }
) > simple_test.json

echo [OK] Config created: simple_test.json
echo.
echo Starting miner in NEW WINDOW...
echo Watch the new window for output!
echo.
echo The miner will run for 60 seconds.
echo Look for these good signs:
echo  - "speed 10s/60s/15m" (shows hashrate)
echo  - "accepted" (shares submitted)
echo.
echo If you see these, the miner works!
echo.

timeout /t 3

REM Start miner in a new visible window
start "XMRig Test" cmd /k "xmrig.exe --config=simple_test.json & echo. & echo Miner stopped. Press any key to close... & pause > nul"

echo.
echo ================================================================
echo Miner started in new window!
echo ================================================================
echo.
echo Watch the new window for 60 seconds.
echo.
echo If you see errors like:
echo  - "FAILED TO APPLY MSR" = Ignore (not critical)
echo  - "memory allocation failed" = Need huge pages or less threads
echo  - "socket connect error" = Pool connection issue
echo  - Immediate crash = Missing dependencies
echo.
echo After 60 seconds, close the miner window.
echo.
pause

echo.
echo To stop the miner:
taskkill /F /IM xmrig.exe 2>nul
if %ERRORLEVEL%==0 (
    echo [OK] Miner stopped
) else (
    echo [INFO] Miner was not running
)

echo.
echo Cleaning up...
del simple_test.json 2>nul

echo.
echo ================================================================
echo DID THE MINER WORK?
echo ================================================================
echo.
echo If YES (you saw hashrate):
echo   - The miner binary works fine
echo   - Problem is in the deployment config or startup method
echo   - Try: CHECK_CONFIG.bat to see deployed config
echo.
echo If NO (crashed immediately):
echo   - Run: DIAGNOSE_CRASH.bat
echo   - Likely missing Visual C++ Redistributable
echo   - Download: https://aka.ms/vs/17/release/vc_redist.x64.exe
echo.
pause
