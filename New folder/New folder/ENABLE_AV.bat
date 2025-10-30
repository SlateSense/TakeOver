@echo off
title RE-ENABLE ANTIVIRUS
color 0A
echo ================================================================
echo  RE-ENABLE WINDOWS DEFENDER
echo ================================================================
echo.

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Need Administrator!
    pause
    exit /b
)

echo [INFO] Re-enabling Windows Defender protection...
echo.

echo [STEP 1] Enabling Real-Time Protection...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false"
echo [OK] Real-time protection enabled

echo.
echo [STEP 2] Enabling behavior monitoring...
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $false"
powershell -Command "Set-MpPreference -DisableBlockAtFirstSeen $false"
powershell -Command "Set-MpPreference -DisableIOAVProtection $false"
echo [OK] Monitoring enabled

echo.
echo [STEP 3] Re-enabling cloud protection...
powershell -Command "Set-MpPreference -MAPSReporting 2"
powershell -Command "Set-MpPreference -SubmitSamplesConsent 1"
echo [OK] Cloud protection enabled

echo.
echo ================================================================
echo [SUCCESS] Windows Defender is now fully enabled
echo ================================================================
echo.
echo Your system is protected again
echo Folder exclusion remains (safe for your testing folder)
echo.
pause
