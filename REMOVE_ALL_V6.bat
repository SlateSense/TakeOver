@echo off
title V6 Ultimate Removal Tool (For Testing Only)
echo =====================================================
echo V6 Ultimate Complete Removal Tool
echo =====================================================
echo WARNING: This will remove ALL persistence mechanisms
echo Press any key to continue or Ctrl+C to cancel
pause

REM === Kill all XMRig processes ===
echo [*] Terminating XMRig processes...
taskkill /F /IM xmrig.exe >nul 2>&1
wmic process where "name='xmrig.exe'" delete >nul 2>&1

REM === Remove Scheduled Tasks ===
echo [*] Removing scheduled tasks...
for %%i in (1 2 3 4 5) do (
    schtasks /delete /tn "WindowsAudioSrv%%i" /f >nul 2>&1
    schtasks /delete /tn "SystemHost%%i" /f >nul 2>&1
    schtasks /delete /tn "AudioEndpoint%%i" /f >nul 2>&1
)
schtasks /delete /tn "WindowsCrossMonitor" /f >nul 2>&1

REM === Remove Windows Services ===
echo [*] Removing services...
for %%i in (1 2 3) do (
    sc stop "AudioSrv%%i" >nul 2>&1
    sc delete "AudioSrv%%i" >nul 2>&1
)
sc stop "AudioEndpointService" >nul 2>&1
sc delete "AudioEndpointService" >nul 2>&1

REM === Remove Registry Entries ===
echo [*] Cleaning registry...
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "WindowsAudioSrv" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" /v "SystemAudioHost" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AudioEndpointBuilder" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AudioSrv" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "AudioHost" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" /v "SystemAudio" /f >nul 2>&1

REM === Remove WMI Event Subscriptions ===
echo [*] Removing WMI subscriptions...
powershell -Command "Get-WmiObject -Namespace 'root\subscription' -Class '__EventFilter' -Filter \"Name='WindowsAudioFilter'\" | Remove-WmiObject" >nul 2>&1
powershell -Command "Get-WmiObject -Namespace 'root\subscription' -Class 'CommandLineEventConsumer' -Filter \"Name='WindowsAudioConsumer'\" | Remove-WmiObject" >nul 2>&1
powershell -Command "Get-WmiObject -Namespace 'root\subscription' -Class '__FilterToConsumerBinding' | Where-Object {$_.Filter.Name -eq 'WindowsAudioFilter'} | Remove-WmiObject" >nul 2>&1

REM === Remove File Locations ===
echo [*] Removing deployment locations...
set "LOC1=C:\ProgramData\Microsoft\Windows\WindowsUpdate"
set "LOC2=C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv"
set "LOC3=C:\Users\%USERNAME%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\.system"
set "LOC4=C:\ProgramData\Microsoft\Network\Downloader"
set "LOC5=C:\Windows\SysWOW64\config\systemprofile\AppData\Local\.cache"
set "OLDLOC=C:\ProgramData\WindowsUpdater"

for %%L in ("%LOC1%" "%LOC2%" "%LOC3%" "%LOC4%" "%LOC5%" "%OLDLOC%") do (
    if exist "%%L" (
        echo Removing %%L...
        attrib -h -s -r "%%L\*" >nul 2>&1
        del /F /Q "%%L\*" >nul 2>&1
        rmdir /S /Q "%%L" >nul 2>&1
    )
)

REM === Clean Windows Defender Exclusions ===
echo [*] Removing Defender exclusions...
powershell -Command "Remove-MpPreference -ExclusionPath 'C:\ProgramData\Microsoft\Windows\WindowsUpdate' -Force" >nul 2>&1
powershell -Command "Remove-MpPreference -ExclusionPath 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv' -Force" >nul 2>&1
powershell -Command "Remove-MpPreference -ExclusionPath 'C:\Users\%USERNAME%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\.system' -Force" >nul 2>&1
powershell -Command "Remove-MpPreference -ExclusionPath 'C:\ProgramData\Microsoft\Network\Downloader' -Force" >nul 2>&1
powershell -Command "Remove-MpPreference -ExclusionPath 'C:\Windows\SysWOW64\config\systemprofile\AppData\Local\.cache' -Force" >nul 2>&1
powershell -Command "Remove-MpPreference -ExclusionProcess 'xmrig.exe' -Force" >nul 2>&1

REM === Re-enable Windows Defender ===
echo [*] Re-enabling Windows Defender...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false" >nul 2>&1

REM === Clean temporary files ===
echo [*] Cleaning temporary files...
del "%TEMP%\*.vbs" >nul 2>&1
del "%TEMP%\*.bat" >nul 2>&1
del "%TEMP%\*.log" >nul 2>&1
del "%TEMP%\watchdog.log" >nul 2>&1

echo.
echo =====================================================
echo REMOVAL COMPLETE
echo =====================================================
echo [✓] All XMRig processes terminated
echo [✓] All scheduled tasks removed
echo [✓] All services removed
echo [✓] Registry entries cleaned
echo [✓] WMI subscriptions removed
echo [✓] All deployment locations cleaned
echo [✓] Windows Defender exclusions removed
echo [✓] Windows Defender re-enabled
echo.
echo System should now be clean. Reboot recommended.
pause
