@echo off
title TEST PORT 80 (ALMOST NEVER BLOCKED)
color 0A

cd /d "%~dp0"

echo ================================================================
echo  TEST PORT 80 - HTTP PORT (Works on 99% of networks)
echo ================================================================
echo.
echo Port 80 is the standard HTTP port - almost never blocked!
echo If this works, your miner will work.
echo.
pause

echo.
echo Creating test config with Port 80...

(
echo {
echo   "autosave": false,
echo   "background": false,
echo   "colors": true,
echo   "cpu": {
echo     "enabled": true,
echo     "huge-pages": false,
echo     "max-threads-hint": 50
echo   },
echo   "pools": [
echo     {
echo       "url": "gulf.moneroocean.stream:80",
echo       "user": "49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon",
echo       "pass": "%COMPUTERNAME%",
echo       "keepalive": true,
echo       "tls": false
echo     }
echo   ]
echo }
) > port80_test.json

echo [OK] Config created for Port 80
echo.
echo Starting miner...
echo.

start "Port 80 Test" cmd /k "xmrig.exe --config=port80_test.json & echo. & echo Test complete. & pause"

echo.
echo ================================================================
echo WATCH THE NEW WINDOW!
echo ================================================================
echo.
echo IF YOU SEE: "new job" and hashrate
echo   → SUCCESS! Port 80 works!
echo   → The updated script will use this automatically
echo.
echo IF IT STILL FAILS:
echo   → Your network blocks ALL crypto mining
echo   → You need a VPN or different network
echo.
pause

taskkill /F /IM xmrig.exe 2>nul
del port80_test.json 2>nul

echo.
echo Cleaned up.
pause
