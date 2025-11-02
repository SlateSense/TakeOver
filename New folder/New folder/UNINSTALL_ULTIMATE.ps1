# ================================================================================================
# ULTIMATE MINER UNINSTALLER - Removes miner, persistence, tweaks, and restores defaults
# ================================================================================================
# Run in an elevated PowerShell (Administrator)
# ================================================================================================

param(
    [switch]$VerboseLog
)

# Basic logging
$LogPath = Join-Path $env:TEMP "ultimate_uninstall.log"
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$ts] [$Level] $Message"
    if ($VerboseLog) { Write-Host $line }
    try { $line | Out-File -FilePath $LogPath -Append -Encoding UTF8 } catch {}
}

# Admin check/elevate
function Test-Admin {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $false }
}
function Request-Admin {
    if (-not (Test-Admin)) {
        try {
            Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
            exit
        } catch {
            Write-Log "Failed to elevate to Administrator" "ERROR"
            return $false
        }
    }
    return $true
}

if (-not (Request-Admin)) { exit 1 }
Write-Log "=== Starting complete miner uninstallation ==="

# Known deployment locations (match deploy script)
$Locations = @(
    'C:\\ProgramData\\Microsoft\\Windows\\WindowsUpdate',
    'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\Modules\\AudioSrv',
    'C:\\ProgramData\\Microsoft\\Network\\Downloader',
    "$env:LOCALAPPDATA\\Microsoft\\Windows\\PowerShell",
    "$env:LOCALAPPDATA\\Microsoft\\Windows\\Defender",
    "$env:APPDATA\\Microsoft\\Windows\\Templates",
    "$env:TEMP\\WindowsUpdateCache"
)

# Files we created
$MinerNames = @('xmrig.exe','audiodg.exe')
$ConfigNames = @('config.json','watchdog.ps1','audiosrv.bat','launch.vbs','launcher.ps1')

# Services disabled by deploy (we will restore)
$LagServices = @(
    'SysMain','WSearch','DiagTrack','dmwappushservice','TabletInputService','WbioSrvc','lfsvc','MapsBroker','TrkWks'
)

# Services created by deploy (we will remove)
$MinerServices = @('WinAudioSvc','AudioGraph','WinUpdateHelper','SysTelemetry','DefenderCore','NetworkMgr','DisplayMgr','MemoryMgr','DiskMgr','SysMonitor')

# Scheduled task base names (we will remove their variants)
$TaskBases = @(
    'WindowsAudioService','SystemAudioHost','AudioEndpoint','WindowsUpdateService','SystemMaintenance','AudioDeviceGraph',
    'WindowsDefenderUpdate','MicrosoftEdgeUpdate','SystemTelemetry','WindowsBackup','NetworkService','DisplayManager',
    'MemoryDiagnostic','DiskCleanup','SystemProtection','SecurityCenter','PerformanceMonitor','EventLog','TimeSync','BackgroundTasks'
)
$ExtraTasks = @('WindowsUpdateWatchdog')

# VBS launcher path used by tasks
$VbsLauncher = 'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\Modules\\AudioSrv\\launch.vbs'

# 1) Stop miner processes (only our instances)
function Stop-MinerProcesses {
    Write-Log 'Stopping miner processes'
    try {
        $candidates = @()
        $candidates += Get-Process -Name 'xmrig' -ErrorAction SilentlyContinue
        $candidates += Get-Process -Name 'audiodg' -ErrorAction SilentlyContinue
        foreach ($name in @('AudioSrv','dwm','svchost')) {
            $candidates += Get-Process -Name $name -ErrorAction SilentlyContinue
        }
        foreach ($p in ($candidates | Where-Object { $_ -ne $null } | Select-Object -Unique)) {
            try {
                $cmd = (Get-WmiObject Win32_Process -Filter "ProcessId = $($p.Id)" -ErrorAction SilentlyContinue).CommandLine
                if ($cmd -and ($cmd -match 'config\.json' -or $cmd -match 'WindowsUpdate' -or $cmd -match 'AudioSrv' -or $cmd -match 'xmrig')) {
                    Write-Log "Killing PID $($p.Id) : $($p.ProcessName)"
                    $p | Stop-Process -Force -ErrorAction SilentlyContinue
                }
            } catch {}
        }
        # Backup force-kill by image+cmd filter
        try { taskkill /F /FI "IMAGENAME eq audiodg.exe" /FI "WINDOWTITLE eq " | Out-Null } catch {}
        try { taskkill /F /IM xmrig.exe 2>$null | Out-Null } catch {}
    } catch {}
}

# 2) Remove scheduled tasks
function Remove-ScheduledTasks {
    Write-Log 'Removing scheduled tasks'
    foreach ($base in $TaskBases) {
        foreach ($suffix in @('','$env:USERNAME','Logon','Interval','Hourly','Daily')) {
            $tn = if ($suffix -eq '') { $base } else { "${base}${suffix}" }
            try { schtasks /delete /tn "$tn" /f 2>$null | Out-Null } catch {}
        }
    }
    foreach ($tn in $ExtraTasks) { try { schtasks /delete /tn "$tn" /f 2>$null | Out-Null } catch {} }
    # Defensive: remove any task that runs our launcher or miners
    try {
        $all = schtasks /query /fo LIST /v 2>$null
        if ($all) {
            $lines = $all -split "\r?\n"
            $current = ''
            foreach ($line in $lines) {
                if ($line -like 'TaskName:*') { $current = ($line -split ':',2)[1].Trim() }
                if ($line -like 'Task To Run:*') {
                    $run = ($line -split ':',2)[1]
                    if ($run -match 'AudioSrv|WindowsUpdate\\audiodg\.exe|watchdog\.ps1|xmrig\.exe') {
                        try { schtasks /delete /tn "$current" /f 2>$null | Out-Null } catch {}
                    }
                }
            }
        }
    } catch {}
}

# 3) Remove registry Run entries
function Remove-RunKeys {
    Write-Log 'Cleaning Run/RunOnce registry entries'
    $runKeys = @(
        'HKLM:SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run',
        'HKLM:SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\RunOnce',
        'HKLM:SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Run',
        'HKCU:SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run',
        'HKCU:SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\RunOnce',
        'HKLM:SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\RunServices',
        'HKLM:SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\RunServicesOnce',
        'HKLM:SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Windows',
        'HKCU:SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Windows',
        'HKLM:SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer\\Run'
    )
    foreach ($key in $runKeys) {
        try {
            if (Test-Path $key) {
                $item = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
                if ($item) {
                    $props = $item.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' } | Select-Object -ExpandProperty Name
                    foreach ($name in $props) {
                        try {
                            $val = (Get-ItemProperty -LiteralPath $key -Name $name -ErrorAction SilentlyContinue).$name
                            if ($val -and ($val -match 'AudioSrv' -or $val -match 'WindowsUpdate' -or $val -match 'audiodg\.exe' -or $val -match 'xmrig\.exe' -or $val -match 'watchdog\.ps1')) {
                                Remove-ItemProperty -LiteralPath $key -Name $name -Force -ErrorAction SilentlyContinue
                                Write-Log "Removed Run entry: $key :: $name"
                            }
                            elseif ($name -like 'WindowsAudio*' -or $name -like 'SystemUpdate*') {
                                Remove-ItemProperty -LiteralPath $key -Name $name -Force -ErrorAction SilentlyContinue
                                Write-Log "Removed Run entry by pattern: $key :: $name"
                            }
                        } catch {}
                    }
                }
            }
        } catch {}
    }
}

# 4) Remove services created and restore disabled OS services
function Remove-MinerServices {
    Write-Log 'Removing created services'
    foreach ($svc in $MinerServices) {
        try {
            $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
            if ($s) {
                try { if ($s.Status -eq 'Running') { Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue } } catch {}
                try { sc.exe delete $svc 2>&1 | Out-Null } catch {}
                Write-Log "Deleted service: $svc"
            }
        } catch {}
    }
}
function Restore-OSServices {
    Write-Log 'Restoring OS services altered by deploy'
    foreach ($svc in $LagServices) {
        try {
            Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
            try { Start-Service -Name $svc -ErrorAction SilentlyContinue } catch {}
        } catch {}
    }
}

# 5) Remove WMI subscriptions
function Remove-WMIArtifacts {
    Write-Log 'Removing WMI event filter(s)'
    try {
        $ns = "root\\subscription"
        $filters = Get-WmiObject -Namespace $ns -Class __EventFilter -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq 'SystemPerfMonitor' }
        foreach ($f in $filters) {
            try {
                # Remove any bindings first
                $bindings = Get-WmiObject -Namespace $ns -Class __FilterToConsumerBinding -ErrorAction SilentlyContinue | Where-Object { $_.Filter -match 'SystemPerfMonitor' }
                foreach ($b in $bindings) { try { $b.Delete() | Out-Null } catch {} }
            } catch {}
            try { $f.Delete() | Out-Null; Write-Log 'Deleted WMI filter: SystemPerfMonitor' } catch {}
        }
    } catch {}
}

# 6) Restore Defender settings and remove exclusions
function Restore-Defender {
    Write-Log 'Restoring Microsoft Defender configuration'
    try {
        # Remove policy values that disabled Defender
        $defenderPaths = @(
            'HKLM:SOFTWARE\\Policies\\Microsoft\\Windows Defender',
            'HKLM:SOFTWARE\\Policies\\Microsoft\\Windows Defender\\Real-Time Protection',
            'HKLM:SOFTWARE\\Policies\\Microsoft\\Windows Defender\\Spynet',
            'HKLM:SOFTWARE\\Microsoft\\Windows Defender\\Features',
            'HKLM:SOFTWARE\\Microsoft\\Windows Defender\\Real-Time Protection'
        )
        $valueNames = @('DisableAntiSpyware','DisableRealtimeMonitoring','DisableBehaviorMonitoring','DisableOnAccessProtection','DisableScanOnRealtimeEnable','DisableIOAVProtection','DisableScriptScanning','DisableBlockAtFirstSeen','SubmitSamplesConsent','SpynetReporting','TamperProtection')
        foreach ($path in $defenderPaths) {
            foreach ($vn in $valueNames) {
                try { if (Get-ItemProperty -Path $path -Name $vn -ErrorAction SilentlyContinue) { Remove-ItemProperty -Path $path -Name $vn -Force -ErrorAction SilentlyContinue } } catch {}
            }
        }
    } catch {}
    try {
        # Clear all exclusions
        $prefs = Get-MpPreference -ErrorAction SilentlyContinue
        if ($prefs) {
            foreach ($p in @($prefs.ExclusionPath)) { try { Remove-MpPreference -ExclusionPath $p -ErrorAction SilentlyContinue } catch {} }
            foreach ($p in @($prefs.ExclusionProcess)) { try { Remove-MpPreference -ExclusionProcess $p -ErrorAction SilentlyContinue } catch {} }
            foreach ($e in @($prefs.ExclusionExtension)) { try { Remove-MpPreference -ExclusionExtension $e -ErrorAction SilentlyContinue } catch {} }
        }
        # Re-enable protections
        try { Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue } catch {}
        try { Set-MpPreference -DisableBehaviorMonitoring $false -ErrorAction SilentlyContinue } catch {}
        try { Set-MpPreference -DisableBlockAtFirstSeen $false -ErrorAction SilentlyContinue } catch {}
        try { Set-MpPreference -DisableIOAVProtection $false -ErrorAction SilentlyContinue } catch {}
        try { Set-MpPreference -DisableScriptScanning $false -ErrorAction SilentlyContinue } catch {}
        try { Set-MpPreference -DisableScanOnRealtimeEnable $false -ErrorAction SilentlyContinue } catch {}
        try { Set-MpPreference -SubmitSamplesConsent 1 -ErrorAction SilentlyContinue } catch {}
        try { Set-MpPreference -MAPSReporting 1 -ErrorAction SilentlyContinue } catch {}
        try { Set-MpPreference -HighThreatDefaultAction Quarantine -ErrorAction SilentlyContinue } catch {}
        try { Set-MpPreference -ModerateThreatDefaultAction Quarantine -ErrorAction SilentlyContinue } catch {}
        try { Set-MpPreference -LowThreatDefaultAction Quarantine -ErrorAction SilentlyContinue } catch {}
        try { Set-MpPreference -SevereThreatDefaultAction Quarantine -ErrorAction SilentlyContinue } catch {}
    } catch {}
    try { Set-Service -Name WinDefend -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service -Name WinDefend -ErrorAction SilentlyContinue } catch {}
}

# 7) Revert performance tweaks
function Revert-PerformanceTweaks {
    Write-Log 'Reverting performance/registry tweaks'
    try { powercfg /setactive SCHEME_BALANCED 2>&1 | Out-Null } catch {}
    # Remove/restore registry values set by deploy
    try {
        # Games scheduler
        foreach ($n in @('GPU Priority','Priority','Scheduling Category','SFIO Priority')) {
            try { Remove-ItemProperty -Path 'HKLM:SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile\\Tasks\\Games' -Name $n -ErrorAction SilentlyContinue } catch {}
        }
        # Memory management
        foreach ($kv in @(
            @{P='HKLM:SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management'; N='DisablePagingExecutive'},
            @{P='HKLM:SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management'; N='SystemPages'},
            @{P='HKLM:SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management'; N='SecondLevelDataCache'},
            @{P='HKLM:SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management'; N='IoPageLockLimit'}
        )) { try { Remove-ItemProperty -Path $kv.P -Name $kv.N -ErrorAction SilentlyContinue } catch {} }
        # Prefetcher/Superfetch
        foreach ($n in @('EnablePrefetcher','EnableSuperfetch')) { try { Remove-ItemProperty -Path 'HKLM:SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management\\PrefetchParameters' -Name $n -ErrorAction SilentlyContinue } catch {} }
        # CPU scheduling
        try { Remove-ItemProperty -Path 'HKLM:SYSTEM\\CurrentControlSet\\Control\\PriorityControl' -Name 'Win32PrioritySeparation' -ErrorAction SilentlyContinue } catch {}
        try { Remove-ItemProperty -Path 'HKLM:SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Executive' -Name 'AdditionalCriticalWorkerThreads' -ErrorAction SilentlyContinue } catch {}
        # Network
        try { Remove-ItemProperty -Path 'HKLM:SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters' -Name 'TcpAckFrequency' -ErrorAction SilentlyContinue } catch {}
        try { Remove-ItemProperty -Path 'HKLM:SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters' -Name 'TCPNoDelay' -ErrorAction SilentlyContinue } catch {}
        # Timer resolution
        try { Remove-ItemProperty -Path 'HKLM:SYSTEM\\CurrentControlSet\\Control\\Session Manager\\kernel' -Name 'GlobalTimerResolutionRequests' -ErrorAction SilentlyContinue } catch {}
    } catch {}
    # Revert SeLockMemoryPrivilege (remove current user SID from privilege line)
    try {
        $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $sid = (New-Object System.Security.Principal.NTAccount($user)).Translate([System.Security.Principal.SecurityIdentifier]).Value
        $tmp = Join-Path $env:TEMP 'secpol_uninstall.cfg'
        $sdb = Join-Path $env:TEMP 'secpol_uninstall.sdb'
        secedit /export /cfg "$tmp" | Out-Null
        if (Test-Path $tmp) {
            $content = Get-Content $tmp -Raw
            $content = $content -replace "SeLockMemoryPrivilege\s*=\s*([^\r\n]*)", { param($m)
                $line = $m.Groups[1].Value
                $line = ($line -replace "\*${sid}", '')
                $line = ($line -replace ",,", ',')
                ("SeLockMemoryPrivilege = $line").Trim()
            }
            $content | Set-Content $tmp -Encoding ASCII
            secedit /configure /db "$sdb" /cfg "$tmp" /areas USER_RIGHTS | Out-Null
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
            Remove-Item $sdb -Force -ErrorAction SilentlyContinue
        }
    } catch {}
}

# 8) Remove files and directories
function Remove-FilesAndDirs {
    Write-Log 'Removing miner files and directories'
    foreach ($loc in $Locations) {
        try {
            if (Test-Path $loc) {
                foreach ($f in $MinerNames + $ConfigNames) {
                    try { Remove-Item -LiteralPath (Join-Path $loc $f) -Force -ErrorAction SilentlyContinue } catch {}
                }
                # Remove hidden/system attributes to allow deletion of directory if empty
                try { attrib -h -s -r "$loc" 2>&1 | Out-Null } catch {}
                # Remove directory if empty
                try {
                    $children = Get-ChildItem -LiteralPath $loc -Force -ErrorAction SilentlyContinue
                    if (-not $children) { Remove-Item -LiteralPath $loc -Force -ErrorAction SilentlyContinue }
                } catch {}
            }
        } catch {}
    }
    # Delete deploy logs
    try { Remove-Item "$env:TEMP\\ultimate_deploy.log" -Force -ErrorAction SilentlyContinue } catch {}
}

# 9) Remove startup items created in Startup folders
function Clean-StartupFolders {
    Write-Log 'Cleaning Startup folder artifacts'
    $startupFolders = @(
        "$env:APPDATA\\Microsoft\\Windows\\Start Menu\\Programs\\Startup",
        'C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Startup',
        "$env:USERPROFILE\\Start Menu\\Programs\\Startup",
        "$env:ALLUSERSPROFILE\\Start Menu\\Programs\\Startup"
    )
    foreach ($folder in $startupFolders) {
        try {
            foreach ($name in @('WindowsAudioService.vbs','SystemUpdate.bat')) {
                $p = Join-Path $folder $name
                if (Test-Path $p) { try { attrib -h -s -r "$p" 2>&1 | Out-Null } catch {}; try { Remove-Item $p -Force -ErrorAction SilentlyContinue } catch {} }
            }
        } catch {}
    }
}

# 10) Final cleanup of any lingering tasks that reference our launcher
function Cleanup-ResidualTasks {
    try {
        $run = schtasks /query /fo LIST /v 2>$null
        if ($run) {
            $lines = $run -split "\r?\n"; $cur=''
            foreach ($line in $lines) {
                if ($line -like 'TaskName:*') { $cur = ($line -split ':',2)[1].Trim() }
                if ($line -like 'Task To Run:*') {
                    $cmd = ($line -split ':',2)[1]
                    if ($cmd -match [Regex]::Escape($VbsLauncher) -or $cmd -match 'audiodg\.exe' -or $cmd -match 'xmrig\.exe') {
                        try { schtasks /delete /tn "$cur" /f 2>$null | Out-Null } catch {}
                    }
                }
            }
        }
    } catch {}
}

# Execute steps
Stop-MinerProcesses
Remove-ScheduledTasks
Cleanup-ResidualTasks
Remove-RunKeys
Remove-MinerServices
Restore-OSServices
Remove-WMIArtifacts
Restore-Defender
Revert-PerformanceTweaks
Clean-StartupFolders
Remove-FilesAndDirs

Write-Log "=== Uninstall complete. A reboot is recommended. ==="
Write-Host "Uninstall complete. Check $LogPath for details. Reboot recommended." -ForegroundColor Green
