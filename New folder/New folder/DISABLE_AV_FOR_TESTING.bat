@echo off
title DISABLE ANTIVIRUS FOR TESTING
color 0C
echo ================================================================
echo  DISABLE ANTIVIRUS TEMPORARILY FOR TESTING
echo ================================================================
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Need Administrator!
    pause
    exit /b
)

echo [WARNING] This will temporarily disable Windows Defender
echo.
set /p confirm="Continue? (Y/N): "
if /i not "%confirm%"=="Y" exit /b

echo.
echo [STEP 1] Adding folder exclusion...
powershell -Command "Add-MpPreference -ExclusionPath 'C:\Users\OM\Desktop\xmrig-6.22.2'"
echo [OK] Folder excluded

echo.
echo [STEP 2] Disabling Real-Time Protection...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true"
echo [OK] Real-time protection disabled

echo.
echo [STEP 3] Disabling behavior monitoring...
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $true"
powershell -Command "Set-MpPreference -DisableBlockAtFirstSeen $true"
powershell -Command "Set-MpPreference -DisableIOAVProtection $true"
echo [OK] Monitoring disabled

echo.
echo ================================================================
echo [SUCCESS] Defender disabled - You can now test FULL script
echo ================================================================
echo.
echo Run START_HERE.bat or START_HERE_VERBOSE.bat now
echo After testing, run ENABLE_AV.bat to re-enable
echo.
pause
