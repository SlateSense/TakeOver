@echo off
title TEST ALL MONEROOCEAN PORTS
color 0B

cd /d "%~dp0"

echo ================================================================
echo  TEST ALL AVAILABLE PORTS
echo  This will find which port works on your network
echo ================================================================
echo.
pause

echo.
echo Creating test configs for all ports...

REM Test Port 10128 (TLS)
(
echo {
echo   "autosave": false,
echo   "background": false,
echo   "cpu": {"enabled": true, "huge-pages": false, "max-threads-hint": 50},
echo   "pools": [{
echo     "url": "gulf.moneroocean.stream:10128",
echo     "user": "49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon",
echo     "pass": "test", "keepalive": true, "tls": true
echo   }]
echo }
) > test_10128.json

REM Test Port 20128 (non-TLS)
(
echo {
echo   "autosave": false,
echo   "background": false,
echo   "cpu": {"enabled": true, "huge-pages": false, "max-threads-hint": 50},
echo   "pools": [{
echo     "url": "gulf.moneroocean.stream:20128",
echo     "user": "49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon",
echo     "pass": "test", "keepalive": true, "tls": false
echo   }]
echo }
) > test_20128.json

REM Test Port 80 (HTTP)
(
echo {
echo   "autosave": false,
echo   "background": false,
echo   "cpu": {"enabled": true, "huge-pages": false, "max-threads-hint": 50},
echo   "pools": [{
echo     "url": "gulf.moneroocean.stream:80",
echo     "user": "49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon",
echo     "pass": "test", "keepalive": true, "tls": false
echo   }]
echo }
) > test_80.json

echo.
echo ================================================================
echo TEST 1: Port 10128 (TLS - Same as your previous miner)
echo ================================================================
timeout /t 2 >nul
xmrig.exe --config=test_10128.json --print-time=1 --no-color > port_10128.txt 2>&1 & timeout /t 5 >nul & taskkill /F /IM xmrig.exe >nul 2>&1
findstr /C:"new job" port_10128.txt >nul
if %ERRORLEVEL%==0 (
    echo [SUCCESS] Port 10128 WORKS!
    set WORKING_PORT=10128
) else (
    echo [FAILED] Port 10128 doesn't work
)

echo.
echo ================================================================
echo TEST 2: Port 20128 (Non-TLS)
echo ================================================================
timeout /t 2 >nul
xmrig.exe --config=test_20128.json --print-time=1 --no-color > port_20128.txt 2>&1 & timeout /t 5 >nul & taskkill /F /IM xmrig.exe >nul 2>&1
findstr /C:"new job" port_20128.txt >nul
if %ERRORLEVEL%==0 (
    echo [SUCCESS] Port 20128 WORKS!
    set WORKING_PORT=20128
) else (
    echo [FAILED] Port 20128 doesn't work
)

echo.
echo ================================================================
echo TEST 3: Port 80 (HTTP)
echo ================================================================
timeout /t 2 >nul
xmrig.exe --config=test_80.json --print-time=1 --no-color > port_80.txt 2>&1 & timeout /t 5 >nul & taskkill /F /IM xmrig.exe >nul 2>&1
findstr /C:"new job" port_80.txt >nul
if %ERRORLEVEL%==0 (
    echo [SUCCESS] Port 80 WORKS!
    set WORKING_PORT=80
) else (
    echo [FAILED] Port 80 doesn't work
)

echo.
echo ================================================================
echo  TEST RESULTS
echo ================================================================
echo.

if defined WORKING_PORT (
    echo SUCCESS! Port %WORKING_PORT% works on your network!
    echo.
    echo The script is configured correctly and will work.
    echo Just run: START_ULTIMATE_FIXED.bat
) else (
    echo ERROR: No ports are working!
    echo.
    echo This means:
    echo  1. Your network blocks ALL crypto mining
    echo  2. OR you need to add firewall exceptions
    echo  3. OR you need a VPN
    echo.
    echo Try running: ADD_FIREWALL_EXCEPTION.bat first
)

echo.
pause

REM Cleanup
del test_*.json port_*.txt 2>nul
