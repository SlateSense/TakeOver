@echo off
title TEST POOL CONNECTION
color 0B

cd /d "%~dp0"

echo ================================================================
echo  TEST POOL CONNECTION
echo  This will test if miner can connect to the pool
echo ================================================================
echo.
echo Creating a verified working config with TLS...
echo.

REM Create a known-good config with TLS EXPLICITLY set
(
echo {
echo   "autosave": true,
echo   "background": false,
echo   "colors": true,
echo   "title": true,
echo   "donate-level": 1,
echo   "cpu": {
echo     "enabled": true,
echo     "huge-pages": false,
echo     "max-threads-hint": 50,
echo     "priority": 2
echo   },
echo   "opencl": {
echo     "enabled": false
echo   },
echo   "cuda": {
echo     "enabled": false
echo   },
echo   "pools": [
echo     {
echo       "algo": "rx/0",
echo       "coin": "monero",
echo       "url": "gulf.moneroocean.stream:10128",
echo       "user": "49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon",
echo       "pass": "%COMPUTERNAME%-test",
echo       "rig-id": "%COMPUTERNAME%",
echo       "keepalive": true,
echo       "enabled": true,
echo       "tls": true,
echo       "nicehash": false
echo     }
echo   ]
echo }
) > pool_test.json

echo [OK] Test config created with TLS enabled
echo.
echo Starting miner for 30 seconds...
echo Watch for these GOOD signs:
echo  - "[green] new job" (connected to pool)
echo  - "speed 10s/60s/15m" (mining working)
echo  - "[green] accepted" (shares accepted)
echo.
echo Watch for BAD signs:
echo  - "[red] read error: end of file" (TLS/connection issue)
echo  - "[red] connect error" (can't reach pool)
echo.
timeout /t 3

echo Starting miner in new window...
start "Pool Connection Test" cmd /k "xmrig.exe --config=pool_test.json & echo. & echo Test complete. Check output above. & pause"

echo.
echo ================================================================
echo Miner started in new window!
echo ================================================================
echo.
echo Watch the new window for 30 seconds:
echo.
echo IF YOU SEE: "[green] new job" and "speed..."
echo   → SUCCESS! Pool connection works!
echo   → TLS is working properly
echo   → The problem was in the deployment config
echo.
echo IF YOU SEE: "[red] read error: end of file" repeatedly
echo   → Pool connection fails
echo   → Possible causes:
echo     1. Firewall blocking outbound connections
echo     2. Network/ISP blocking crypto mining
echo     3. Antivirus blocking network access
echo.
pause

REM Cleanup
taskkill /F /IM xmrig.exe 2>nul
del pool_test.json 2>nul

echo.
echo Miner stopped and cleaned up.
pause
