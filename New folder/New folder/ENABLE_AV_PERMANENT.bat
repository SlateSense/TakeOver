@echo off
title RE-ENABLE WINDOWS DEFENDER PROTECTION
color 0A
setlocal enabledelayedexpansion

:: ================================================================
::  RE-ENABLE WINDOWS DEFENDER
::  Restores all protection after testing
:: ================================================================

echo.
echo ================================================================
echo  RE-ENABLE WINDOWS DEFENDER PROTECTION
echo ================================================================
echo.
echo This will restore all Windows Defender protection settings
echo and re-enable automatic updates.
echo.
set /p confirm="Continue? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Operation cancelled.
    pause
    exit /b
)

:: Check admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [ERROR] Administrator rights required!
    echo Right-click this script and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo.
echo ================================================================
echo  RESTORING WINDOWS DEFENDER PROTECTION
echo ================================================================

:: ================================================================
:: STEP 1: Re-enable Windows Defender via Registry
:: ================================================================
echo.
echo [1/7] Re-enabling Defender features via registry...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiVirus /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableScanOnRealtimeEnable /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v DisableEnhancedNotifications /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet" /v DisableBlockAtFirstSeen /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet" /v SpynetReporting /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet" /v SubmitSamplesConsent /t REG_DWORD /d 1 /f >nul 2>&1
echo      [OK] Defender features re-enabled

:: ================================================================
:: STEP 2: Re-enable Tamper Protection
:: ================================================================
echo.
echo [2/7] Re-enabling Tamper Protection...
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v TamperProtection /t REG_DWORD /d 1 /f >nul 2>&1
echo      [OK] Tamper Protection enabled

:: ================================================================
:: STEP 3: Re-enable Windows Defender Services
:: ================================================================
echo.
echo [3/7] Re-enabling Windows Defender services...
sc config WinDefend start=auto >nul 2>&1
sc start WinDefend >nul 2>&1
sc config WdNisSvc start=auto >nul 2>&1
sc start WdNisSvc >nul 2>&1
sc config WdNisDrv start=auto >nul 2>&1
sc start WdNisDrv >nul 2>&1
sc config WdFilter start=auto >nul 2>&1
sc start WdFilter >nul 2>&1
sc config SgrmBroker start=auto >nul 2>&1
sc start SgrmBroker >nul 2>&1
echo      [OK] Services enabled

:: ================================================================
:: STEP 4: Re-enable Security Center Service
:: ================================================================
echo.
echo [4/7] Re-enabling Security Center...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v DisableNotifications /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SecurityHealthService" /v Start /t REG_DWORD /d 2 /f >nul 2>&1
sc config SecurityHealthService start=auto >nul 2>&1
sc start SecurityHealthService >nul 2>&1
echo      [OK] Security Center enabled

:: ================================================================
:: STEP 5: Re-enable Windows Defender Scheduled Tasks
:: ================================================================
echo.
echo [5/7] Re-enabling Windows Defender scheduled tasks...
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Enable >nul 2>&1
echo      [OK] Scheduled tasks enabled

:: ================================================================
:: STEP 6: Re-enable Windows Update
:: ================================================================
echo.
echo [6/7] Re-enabling Windows Update...
sc config wuauserv start=auto >nul 2>&1
sc start wuauserv >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f >nul 2>&1
echo      [OK] Windows Update enabled

:: ================================================================
:: STEP 7: Re-enable Real-Time Protection via PowerShell
:: ================================================================
echo.
echo [7/7] Re-enabling real-time protection...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false" >nul 2>&1
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $false" >nul 2>&1
powershell -Command "Set-MpPreference -DisableBlockAtFirstSeen $false" >nul 2>&1
powershell -Command "Set-MpPreference -DisableIOAVProtection $false" >nul 2>&1
powershell -Command "Set-MpPreference -DisablePrivacyMode $false" >nul 2>&1
powershell -Command "Set-MpPreference -DisableArchiveScanning $false" >nul 2>&1
powershell -Command "Set-MpPreference -DisableIntrusionPreventionSystem $false" >nul 2>&1
powershell -Command "Set-MpPreference -DisableScriptScanning $false" >nul 2>&1
powershell -Command "Set-MpPreference -SubmitSamplesConsent 1" >nul 2>&1
powershell -Command "Set-MpPreference -MAPSReporting 2" >nul 2>&1
echo      [OK] Real-time protection enabled

:: ================================================================
:: FINAL STEP: Update Definitions and Quick Scan
:: ================================================================
echo.
echo [FINAL] Updating definitions and running quick scan...
powershell -Command "Update-MpSignature" >nul 2>&1
echo      [OK] Definitions updated

echo.
echo ================================================================
echo  WINDOWS DEFENDER FULLY RESTORED
echo ================================================================
echo.
echo [SUCCESS] Windows Defender protection is now fully enabled.
echo           Your system is now protected against threats.
echo.
echo A system restart is recommended to ensure all changes take effect.
echo.
set /p restart="Restart computer now? (Y/N): "
if /i "%restart%"=="Y" shutdown /r /t 10 /c "Restarting to complete Defender restoration"
echo.
pause
