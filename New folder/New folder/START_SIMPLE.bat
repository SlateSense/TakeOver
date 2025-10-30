@echo off
title SIMPLE MINER DEPLOYMENT (No Stealth)
color 0A
echo ================================================================
echo  SIMPLE MINER DEPLOYMENT
echo  This version skips complex stealth features for testing
echo ================================================================
echo.

REM Change to script directory
cd /d "%~dp0"

REM Check admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Need Administrator!
    pause
    exit /b
)
echo [OK] Running as Administrator
echo.

REM Kill any existing xmrig
taskkill /F /IM xmrig.exe >nul 2>&1
timeout /t 2 >nul

echo [STEP 1] Applying Windows performance optimizations...
echo ----------------------------------------------------------------

REM Power plan - High Performance
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
echo [OK] High Performance power plan activated

REM Disable CPU throttling
powercfg /setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 100 >nul 2>&1
echo [OK] CPU throttling disabled

REM Memory optimizations
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f >nul 2>&1
echo [OK] Memory optimizations applied

REM Gaming priority
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f >nul 2>&1
echo [OK] Windows gaming priority set

REM Network optimization
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
echo [OK] Network latency optimized

echo.
echo [STEP 2] Enabling Huge Pages...
echo ----------------------------------------------------------------
powershell -ExecutionPolicy Bypass -Command "$userName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name; secedit /export /cfg $env:TEMP\secpol.cfg | Out-Null; $line = Get-Content $env:TEMP\secpol.cfg | Select-String 'SeLockMemoryPrivilege'; if ($line) { (Get-Content $env:TEMP\secpol.cfg) -replace 'SeLockMemoryPrivilege\s*=.*', 'SeLockMemoryPrivilege = *S-1-5-32-544,*S-1-5-32-545' | Set-Content $env:TEMP\secpol_new.cfg } else { (Get-Content $env:TEMP\secpol.cfg) -replace '\[Privilege Rights\]', '[Privilege Rights]`r`nSeLockMemoryPrivilege = *S-1-5-32-544,*S-1-5-32-545' | Set-Content $env:TEMP\secpol_new.cfg }; secedit /configure /db secedit.sdb /cfg $env:TEMP\secpol_new.cfg | Out-Null; Remove-Item $env:TEMP\secpol*.cfg -Force" 2>nul
echo [OK] Huge Pages privilege granted
echo.

echo [STEP 3] Creating optimized config.json...
echo ----------------------------------------------------------------

REM Create config file
(
echo {
echo   "api": {
echo     "worker-id": "%COMPUTERNAME%-simple"
echo   },
echo   "http": {
echo     "enabled": true,
echo     "host": "127.0.0.1",
echo     "port": 16000
echo   },
echo   "autosave": true,
echo   "background": false,
echo   "colors": true,
echo   "randomx": {
echo     "init": 4,
echo     "init-avx2": 4,
echo     "mode": "fast",
echo     "1gb-pages": true,
echo     "rdmsr": true,
echo     "wrmsr": true,
echo     "wrmsr-presets": ["intel"],
echo     "cache_qos": true,
echo     "numa": true,
echo     "scratchpad_prefetch_mode": 2
echo   },
echo   "cpu": {
echo     "enabled": true,
echo     "huge-pages": true,
echo     "huge-pages-jit": true,
echo     "priority": 5,
echo     "memory-pool": 4096,
echo     "yield": false,
echo     "max-threads-hint": 75,
echo     "asm": true
echo   },
echo   "opencl": {"enabled": false},
echo   "cuda": {"enabled": false},
echo   "donate-level": 0,
echo   "pools": [
echo     {
echo       "algo": "rx/0",
echo       "coin": "monero",
echo       "url": "gulf.moneroocean.stream:10128",
echo       "user": "49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon",
echo       "pass": "%COMPUTERNAME%-optimized",
echo       "keepalive": true,
echo       "tls": false
echo     }
echo   ],
echo   "print-time": 60,
echo   "pause-on-battery": false
echo }
) > config.json

echo [OK] Config file created with optimizations
echo.

echo ================================================================
echo [STEP 4] STARTING MINER
echo ================================================================
echo.
echo Pool: gulf.moneroocean.stream:10128
echo Worker: %COMPUTERNAME%-optimized
echo.
echo Performance optimizations applied:
echo  - High priority CPU scheduling
echo  - Huge pages enabled
echo  - Intel MSR optimizations
echo  - Enhanced RandomX settings
echo  - Network latency reduced
echo.
echo Press Ctrl+C to stop mining
echo ================================================================
echo.
timeout /t 2 >nul

REM Start miner with high priority using config file
start /HIGH /B xmrig.exe --config=config.json

REM Wait a moment then set process priority
timeout /t 3 /nobreak >nul
wmic process where name="xmrig.exe" CALL setpriority "high priority" >nul 2>&1

REM Keep window open and monitor
echo.
echo [OK] Miner started with high priority
echo [*] Monitoring... (this window will stay open)
echo [*] Check the XMRig window for hashrate
echo.
echo Press any key to stop the miner...
pause >nul

REM Stop miner on exit
taskkill /F /IM xmrig.exe >nul 2>&1
echo.
echo [STOPPED] Miner has been stopped
timeout /t 2 >nul
