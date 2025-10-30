@echo off
title MINER DIAGNOSTIC TOOL
color 0B
echo ================================================================
echo  MINER DIAGNOSTIC TOOL
echo  This will help identify why the miner won't start
echo ================================================================
echo.

cd /d "%~dp0"

echo [CHECK 1] Administrator Privileges
echo ----------------------------------------------------------------
net session >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Running as Administrator
) else (
    echo [FAIL] NOT running as Administrator
    echo [FIX] Right-click this file and select "Run as administrator"
    pause
    exit /b
)
echo.

echo [CHECK 2] Required Files
echo ----------------------------------------------------------------
if exist "DEPLOY_ULTIMATE.ps1" (
    echo [OK] DEPLOY_ULTIMATE.ps1 found
) else (
    echo [FAIL] DEPLOY_ULTIMATE.ps1 NOT found
)

if exist "xmrig.exe" (
    echo [OK] xmrig.exe found
    for %%A in ("xmrig.exe") do echo     Size: %%~zA bytes
) else (
    echo [FAIL] xmrig.exe NOT found
)
echo.

echo [CHECK 3] PowerShell Version
echo ----------------------------------------------------------------
powershell -Command "Write-Host '[OK] PowerShell Version:' $PSVersionTable.PSVersion"
echo.

echo [CHECK 4] PowerShell Execution Policy
echo ----------------------------------------------------------------
powershell -Command "Write-Host 'Current Policy:' (Get-ExecutionPolicy)"
echo.

echo [CHECK 5] Check if miner is already running
echo ----------------------------------------------------------------
tasklist /FI "IMAGENAME eq xmrig.exe" 2>NUL | find /I /N "xmrig.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo [WARNING] XMRig.exe IS ALREADY RUNNING!
    echo.
    tasklist /FI "IMAGENAME eq xmrig.exe"
    echo.
    echo This may prevent new instances from starting.
    echo.
    set /p kill="Kill existing process? (Y/N): "
    if /i "%kill%"=="Y" (
        taskkill /F /IM xmrig.exe
        echo [OK] Process killed
    )
) else (
    echo [OK] XMRig is not currently running
)
echo.

echo [CHECK 6] Test PowerShell script syntax
echo ----------------------------------------------------------------
echo Testing DEPLOY_ULTIMATE.ps1 for syntax errors...
powershell -ExecutionPolicy Bypass -Command "try { $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content '%~dp0DEPLOY_ULTIMATE.ps1' -Raw), [ref]$null); Write-Host '[OK] PowerShell script syntax is valid' -ForegroundColor Green } catch { Write-Host '[FAIL] Syntax error in PowerShell script:' $_.Exception.Message -ForegroundColor Red }"
echo.

echo [CHECK 7] Test simple PowerShell execution
echo ----------------------------------------------------------------
powershell -ExecutionPolicy Bypass -Command "Write-Host '[OK] PowerShell can execute commands' -ForegroundColor Green"
echo.

echo [CHECK 8] Available RAM
echo ----------------------------------------------------------------
powershell -Command "$ram = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB; Write-Host ('Total RAM: {0:N2} GB' -f $ram)"
powershell -Command "$freeRam = (Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory / 1MB; Write-Host ('Free RAM: {0:N2} GB' -f $freeRam)"
echo.

echo [CHECK 9] CPU Information
echo ----------------------------------------------------------------
powershell -Command "$cpu = Get-WmiObject Win32_Processor; Write-Host ('CPU: ' + $cpu.Name); Write-Host ('Cores: ' + $cpu.NumberOfCores); Write-Host ('Threads: ' + $cpu.NumberOfLogicalProcessors)"
echo.

echo [CHECK 10] Windows Defender Status
echo ----------------------------------------------------------------
powershell -Command "try { $status = Get-MpComputerStatus; Write-Host 'Real-time Protection:' $status.RealTimeProtectionEnabled } catch { Write-Host 'Cannot check Defender status' }"
echo.

echo ================================================================
echo  DIAGNOSTIC COMPLETE
echo ================================================================
echo.
echo [OPTIONS]
echo 1. Try TEST_SIMPLE.bat (simple direct miner launch)
echo 2. Try START_HERE.bat (full deployment with optimizations)
echo 3. Exit
echo.
set /p choice="Choose option (1-3): "

if "%choice%"=="1" (
    echo.
    echo Launching TEST_SIMPLE.bat...
    call "%~dp0TEST_SIMPLE.bat"
) else if "%choice%"=="2" (
    echo.
    echo Launching START_HERE.bat...
    call "%~dp0🚀_START_HERE.bat"
)

pause
