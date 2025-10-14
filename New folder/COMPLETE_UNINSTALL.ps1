# ================================================================================================
# COMPLETE MINER REMOVAL SCRIPT
# ================================================================================================
# Removes ALL traces of the miner deployment
# ================================================================================================

$ErrorActionPreference = "Continue"

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "           COMPLETE MINER REMOVAL SCRIPT" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$removeCount = 0
$errorCount = 0

# ================================================================================================
# STEP 1: STOP ALL MINER PROCESSES
# ================================================================================================

Write-Host "[1/10] Stopping all miner processes..." -ForegroundColor Yellow

$minerProcesses = @("xmrig", "audiodg", "AudioSrv", "dwm", "svchost")
$stoppedCount = 0

foreach ($procName in $minerProcesses) {
    try {
        $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
        foreach ($proc in $procs) {
            # Check if it's our miner by command line
            $cmdLine = (Get-WmiObject Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction SilentlyContinue).CommandLine
            if ($cmdLine -match "config\.json|moneroocean|gulf\.moneroocean|xmrig") {
                Write-Host "  • Stopping: $procName (PID: $($proc.Id))" -ForegroundColor Gray
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                $stoppedCount++
                $removeCount++
            }
        }
    } catch {}
}

# Force kill with taskkill
taskkill /F /IM xmrig.exe 2>&1 | Out-Null
taskkill /F /IM audiodg.exe /FI "COMMANDLINE eq *config.json*" 2>&1 | Out-Null

Write-Host "  ✅ Stopped $stoppedCount miner process(es)" -ForegroundColor Green
Write-Host ""

# ================================================================================================
# STEP 2: REMOVE SCHEDULED TASKS
# ================================================================================================

Write-Host "[2/10] Removing scheduled tasks..." -ForegroundColor Yellow

$taskNames = @(
    "WindowsAudioService", "SystemAudioHost", "AudioEndpoint",
    "WindowsUpdateService", "SystemMaintenance", "AudioDeviceGraph",
    "WindowsDefenderUpdate", "MicrosoftEdgeUpdate", "SystemTelemetry",
    "WindowsBackup"
)

$taskCount = 0
foreach ($taskName in $taskNames) {
    foreach ($suffix in @("", "Logon", "Hourly", "Daily")) {
        $fullName = "$taskName$suffix"
        $task = Get-ScheduledTask -TaskName $fullName -ErrorAction SilentlyContinue
        if ($task) {
            try {
                Unregister-ScheduledTask -TaskName $fullName -Confirm:$false -ErrorAction SilentlyContinue
                Write-Host "  • Removed task: $fullName" -ForegroundColor Gray
                $taskCount++
                $removeCount++
            } catch {}
        }
    }
}

Write-Host "  ✅ Removed $taskCount scheduled task(s)" -ForegroundColor Green
Write-Host ""

# ================================================================================================
# STEP 3: REMOVE REGISTRY RUN KEYS
# ================================================================================================

Write-Host "[3/10] Removing registry run keys..." -ForegroundColor Yellow

$runKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)

$regCount = 0
foreach ($runKey in $runKeys) {
    try {
        if (Test-Path $runKey) {
            $entries = Get-ItemProperty -Path $runKey -ErrorAction SilentlyContinue
            foreach ($prop in $entries.PSObject.Properties) {
                if ($prop.Value -match "audiodg|AudioSrv|WindowsUpdate|launcher\.ps1|autostart\.bat") {
                    try {
                        Remove-ItemProperty -Path $runKey -Name $prop.Name -ErrorAction SilentlyContinue
                        Write-Host "  • Removed registry key: $($prop.Name)" -ForegroundColor Gray
                        $regCount++
                        $removeCount++
                    } catch {}
                }
            }
        }
    } catch {}
}

Write-Host "  ✅ Removed $regCount registry entr(ies)" -ForegroundColor Green
Write-Host ""

# ================================================================================================
# STEP 4: REMOVE SERVICES
# ================================================================================================

Write-Host "[4/10] Removing fake services..." -ForegroundColor Yellow

$services = @(
    "WindowsAudioSrv",
    "AudioDeviceGraph",
    "WindowsUpdateSvc",
    "SystemTelemetry",
    "MicrosoftDefenderCore"
)

$svcCount = 0
foreach ($svcName in $services) {
    try {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
            sc.exe delete $svcName 2>&1 | Out-Null
            Write-Host "  • Removed service: $svcName" -ForegroundColor Gray
            $svcCount++
            $removeCount++
        }
    } catch {}
}

Write-Host "  ✅ Removed $svcCount service(s)" -ForegroundColor Green
Write-Host ""

# ================================================================================================
# STEP 5: REMOVE WMI EVENT SUBSCRIPTIONS
# ================================================================================================

Write-Host "[5/10] Removing WMI event subscriptions..." -ForegroundColor Yellow

try {
    $filters = Get-WmiObject -Namespace root\subscription -Class __EventFilter -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "SystemPerfMonitor" }
    foreach ($filter in $filters) {
        $filter.Delete()
        Write-Host "  • Removed WMI filter: $($filter.Name)" -ForegroundColor Gray
        $removeCount++
    }
    
    $consumers = Get-WmiObject -Namespace root\subscription -Class CommandLineEventConsumer -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "System|Audio" }
    foreach ($consumer in $consumers) {
        $consumer.Delete()
        Write-Host "  • Removed WMI consumer: $($consumer.Name)" -ForegroundColor Gray
        $removeCount++
    }
} catch {}

Write-Host "  ✅ WMI cleanup complete" -ForegroundColor Green
Write-Host ""

# ================================================================================================
# STEP 6: DELETE STARTUP SCRIPTS
# ================================================================================================

Write-Host "[6/10] Removing startup scripts..." -ForegroundColor Yellow

$startupFolders = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
)

$startupCount = 0
foreach ($folder in $startupFolders) {
    if (Test-Path $folder) {
        $files = Get-ChildItem -Path $folder -Filter "WindowsAudio.*" -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            try {
                Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
                Write-Host "  • Removed: $($file.Name)" -ForegroundColor Gray
                $startupCount++
                $removeCount++
            } catch {}
        }
    }
}

Write-Host "  ✅ Removed $startupCount startup script(s)" -ForegroundColor Green
Write-Host ""

# ================================================================================================
# STEP 7: DELETE ALL MINER FILES
# ================================================================================================

Write-Host "[7/10] Deleting all miner files..." -ForegroundColor Yellow

$deploymentLocations = @(
    "C:\ProgramData\Microsoft\Windows\WindowsUpdate",
    "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv",
    "C:\ProgramData\Microsoft\Network\Downloader"
)

$fileCount = 0
foreach ($location in $deploymentLocations) {
    if (Test-Path $location) {
        try {
            # Remove hidden/system attributes first
            attrib -h -s -r "$location\*.*" /s /d 2>&1 | Out-Null
            
            # Delete all files
            Get-ChildItem -Path $location -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            
            # Remove directory
            Remove-Item -Path $location -Force -Recurse -ErrorAction SilentlyContinue
            
            Write-Host "  • Deleted: $location" -ForegroundColor Gray
            $fileCount++
            $removeCount++
        } catch {}
    }
}

# Delete launcher scripts
$launcherPaths = @(
    "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv\launcher.ps1",
    "C:\ProgramData\Microsoft\Windows\WindowsUpdate\autostart.bat"
)

foreach ($path in $launcherPaths) {
    if (Test-Path $path) {
        try {
            Remove-Item $path -Force -ErrorAction SilentlyContinue
            Write-Host "  • Deleted: $path" -ForegroundColor Gray
            $removeCount++
        } catch {}
    }
}

Write-Host "  ✅ Deleted $fileCount location(s)" -ForegroundColor Green
Write-Host ""

# ================================================================================================
# STEP 8: RESTORE WINDOWS DEFENDER
# ================================================================================================

Write-Host "[8/10] Restoring Windows Defender..." -ForegroundColor Yellow

try {
    # Remove exclusions
    $exclusionPaths = @(
        "C:\", "C:\Windows", "C:\Windows\System32", "C:\Windows\SysWOW64",
        "C:\ProgramData", "C:\Windows\Temp", "$env:TEMP", "$env:USERPROFILE"
    )
    
    foreach ($path in $exclusionPaths) {
        Remove-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
    }
    
    Remove-MpPreference -ExclusionProcess "xmrig.exe" -ErrorAction SilentlyContinue
    Remove-MpPreference -ExclusionProcess "audiodg.exe" -ErrorAction SilentlyContinue
    Remove-MpPreference -ExclusionProcess "AudioSrv.exe" -ErrorAction SilentlyContinue
    Remove-MpPreference -ExclusionExtension ".exe" -ErrorAction SilentlyContinue
    Remove-MpPreference -ExclusionExtension ".dll" -ErrorAction SilentlyContinue
    
    # Re-enable Defender
    Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
    Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue
    Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue
    Set-MpPreference -DisableScriptScanning $false -ErrorAction SilentlyContinue
    
    # Restore registry
    $defenderPaths = @(
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
    )
    
    foreach ($path in $defenderPaths) {
        if (Test-Path $path) {
            Remove-ItemProperty -Path $path -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $path -Name "DisableRealtimeMonitoring" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $path -Name "DisableBehaviorMonitoring" -ErrorAction SilentlyContinue
        }
    }
    
    # Restart Defender service
    Start-Service -Name WinDefend -ErrorAction SilentlyContinue
    Set-Service -Name WinDefend -StartupType Automatic -ErrorAction SilentlyContinue
    
    Write-Host "  ✅ Windows Defender restored and re-enabled" -ForegroundColor Green
    $removeCount++
    
} catch {
    Write-Host "  ⚠️  Could not fully restore Defender (may need manual re-enable)" -ForegroundColor Yellow
    $errorCount++
}
Write-Host ""

# ================================================================================================
# STEP 9: RE-ENABLE DISABLED SERVICES
# ================================================================================================

Write-Host "[9/10] Re-enabling disabled services..." -ForegroundColor Yellow

$servicesToEnable = @("SysMain", "WSearch", "DiagTrack", "dmwappushservice", "TabletInputService")
$enabledCount = 0

foreach ($svcName in $servicesToEnable) {
    try {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc -and $svc.StartType -eq 'Disabled') {
            Set-Service -Name $svcName -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $svcName -ErrorAction SilentlyContinue
            Write-Host "  • Re-enabled: $svcName" -ForegroundColor Gray
            $enabledCount++
            $removeCount++
        }
    } catch {}
}

Write-Host "  ✅ Re-enabled $enabledCount service(s)" -ForegroundColor Green
Write-Host ""

# ================================================================================================
# STEP 10: CLEAR LOGS AND TRACES
# ================================================================================================

Write-Host "[10/10] Clearing logs and traces..." -ForegroundColor Yellow

try {
    # Delete deployment logs
    Remove-Item "$env:TEMP\ultimate_deploy.log" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\enable_lock_pages.ps1" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\secpol*.cfg" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\found_pcs.txt" -Force -ErrorAction SilentlyContinue
    
    # Clear PowerShell history
    Remove-Item (Get-PSReadlineOption).HistorySavePath -Force -ErrorAction SilentlyContinue
    
    Write-Host "  ✅ Logs and traces cleared" -ForegroundColor Green
    $removeCount++
} catch {}

Write-Host ""

# ================================================================================================
# SUMMARY
# ================================================================================================

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                    REMOVAL SUMMARY" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Components removed: $removeCount" -ForegroundColor Green
Write-Host "Errors encountered: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Yellow" } else { "Green" })
Write-Host ""

if ($errorCount -eq 0) {
    Write-Host "✅ COMPLETE REMOVAL SUCCESSFUL" -ForegroundColor Green
    Write-Host ""
    Write-Host "All miner components have been removed." -ForegroundColor White
    Write-Host "System has been restored to original state." -ForegroundColor White
    Write-Host ""
    Write-Host "RECOMMENDATION: Restart your PC to complete cleanup." -ForegroundColor Yellow
} else {
    Write-Host "⚠️  REMOVAL COMPLETED WITH WARNINGS" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Most components removed, but some errors occurred." -ForegroundColor White
    Write-Host "You may need to manually check:" -ForegroundColor White
    Write-Host "  • Windows Defender settings" -ForegroundColor Gray
    Write-Host "  • Scheduled tasks" -ForegroundColor Gray
    Write-Host "  • Services" -ForegroundColor Gray
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

exit 0
