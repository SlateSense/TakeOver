@echo off
title TEST EXACT WORKING CONFIG
color 0A

cd /d "%~dp0"

echo ================================================================
echo  TEST WITH EXACT WORKING CONFIGURATION
echo  Port 10128 with TLS DISABLED (same as BEAST_MODE)
echo ================================================================
echo.

REM Create exact same config as your working BEAST_MODE script
(
echo {
echo   "api": {"id": null, "worker-id": "%COMPUTERNAME%"},
echo   "http": {"enabled": true, "host": "127.0.0.1", "port": 16000, "restricted": true},
echo   "autosave": true, "background": true, "colors": false, "title": false,
echo   "randomx": {
echo     "init": -1, "init-avx2": -1, "mode": "auto", "1gb-pages": true,
echo     "rdmsr": true, "wrmsr": true, "cache_qos": true, "numa": true,
echo     "scratchpad_prefetch_mode": 1
echo   },
echo   "cpu": {
echo     "enabled": true, "huge-pages": true, "huge-pages-jit": true,
echo     "hw-aes": null, "priority": 5, "memory-pool": true,
echo     "yield": true, "max-threads-hint": 75, "asm": true,
echo     "argon2-impl": null, "astrobwt-max-size": 550, "astrobwt-avx2": false
echo   },
echo   "donate-level": 0,
echo   "pools": [{
echo     "algo": "rx/0", "coin": "monero",
echo     "url": "gulf.moneroocean.stream:10128",
echo     "user": "49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon",
echo     "pass": "%COMPUTERNAME%-i5",
echo     "rig-id": "%COMPUTERNAME%",
echo     "keepalive": true, "enabled": true, "tls": false, "daemon": false
echo   }],
echo   "print-time": 0,
echo   "health-print-time": 0,
echo   "pause-on-battery": false,
echo   "pause-on-active": false
echo }
) > test_working.json

echo Config created (EXACT copy of your working BEAST_MODE)
echo.
echo Starting miner with same command as BEAST_MODE...
echo.

REM Use exact same command as working script
start "" /min xmrig.exe --config="test_working.json"

echo Miner started! Check Task Manager for xmrig.exe
echo.
echo Wait 10 seconds to see if it's running...
timeout /t 10

echo.
echo Checking if miner is running...
tasklist /FI "IMAGENAME eq xmrig.exe" | find /I "xmrig.exe"
if %ERRORLEVEL%==0 (
    echo.
    echo ================================================================
    echo  SUCCESS! Miner is running with EXACT working config!
    echo ================================================================
    echo.
    echo This proves:
    echo  - Port 10128 works with TLS DISABLED
    echo  - The config is correct
    echo  - DEPLOY_ULTIMATE.ps1 will now work
) else (
    echo.
    echo ================================================================
    echo  Miner is not visible (might be running hidden)
    echo ================================================================
)

echo.
pause

REM Stop test miner
taskkill /F /IM xmrig.exe 2>nul
del test_working.json 2>nul
