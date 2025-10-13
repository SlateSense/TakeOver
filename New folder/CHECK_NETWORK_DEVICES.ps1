# ================================================================================================
# NETWORK DEVICE DISCOVERY - Check what's on your network BEFORE deploying
# ================================================================================================
# Run this BEFORE competition to see all devices and identify smart boards
# ================================================================================================

Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          NETWORK DEVICE DISCOVERY - Pre-Competition          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "[+] This will help you identify smart boards BEFORE deployment" -ForegroundColor Yellow
Write-Host "[+] Scanning network for all devices..." -ForegroundColor Yellow
Write-Host ""

# Get local IP and subnet
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127.*" -and $_.PrefixOrigin -eq "Dhcp" -or $_.PrefixOrigin -eq "Manual"} | Select-Object -First 1).IPAddress

if (-not $localIP) {
    Write-Host "❌ Could not determine local IP address" -ForegroundColor Red
    exit 1
}

Write-Host "📡 Your IP: $localIP" -ForegroundColor Cyan
$subnet = $localIP.Substring(0, $localIP.LastIndexOf('.'))
Write-Host "🌐 Scanning subnet: $subnet.0/24" -ForegroundColor Cyan
Write-Host "⏱️  This will take 1-2 minutes...`n" -ForegroundColor Yellow

# Arrays to store devices
$labPCs = @()
$smartBoards = @()
$teacherPCs = @()
$unknown = @()

# Scan network
Write-Host "Scanning..." -ForegroundColor Yellow
1..254 | ForEach-Object -Parallel {
    $ip = "$using:subnet.$_"
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeoutSeconds 1) {
        try {
            $hostname = [System.Net.Dns]::GetHostEntry($ip).HostName.Split('.')[0]
            "$hostname`t$ip"
        } catch {
            "$ip`t$ip"
        }
    }
} -ThrottleLimit 50 | ForEach-Object {
    $parts = $_ -split "`t"
    $hostname = $parts[0]
    $ip = $parts[1]
    
    # Categorize devices
    if ($hostname -match "SMARTBOARD|SMART-BOARD|ANDROID-BOARD|IFP|WHITEBOARD|BOARD") {
        $smartBoards += [PSCustomObject]@{Name=$hostname; IP=$ip; Type="Smart Board"}
    }
    elseif ($hostname -match "TEACHER|ADMIN|FACULTY|STAFF") {
        $teacherPCs += [PSCustomObject]@{Name=$hostname; IP=$ip; Type="Teacher/Admin PC"}
    }
    elseif ($hostname -match "LAB|STUDENT|PC-\d+|COMP|WORKSTATION") {
        $labPCs += [PSCustomObject]@{Name=$hostname; IP=$ip; Type="Lab PC"}
    }
    else {
        $unknown += [PSCustomObject]@{Name=$hostname; IP=$ip; Type="Unknown"}
    }
}

# Display results
Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                     DISCOVERY COMPLETE                       ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

# Lab PCs
if ($labPCs.Count -gt 0) {
    Write-Host "✅ LAB PCS DETECTED ($($labPCs.Count)):" -ForegroundColor Green
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    $labPCs | ForEach-Object {
        Write-Host "  ✓ $($_.Name) ($($_.IP))" -ForegroundColor Green
    }
    Write-Host ""
}

# Smart Boards
if ($smartBoards.Count -gt 0) {
    Write-Host "⚠️  SMART BOARDS DETECTED ($($smartBoards.Count)):" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    $smartBoards | ForEach-Object {
        Write-Host "  ⚠️  $($_.Name) ($($_.IP)) - DO NOT DEPLOY HERE!" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Teacher PCs
if ($teacherPCs.Count -gt 0) {
    Write-Host "⚠️  TEACHER/ADMIN PCS DETECTED ($($teacherPCs.Count)):" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    $teacherPCs | ForEach-Object {
        Write-Host "  ⚠️  $($_.Name) ($($_.IP)) - DO NOT DEPLOY HERE!" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Unknown devices
if ($unknown.Count -gt 0) {
    Write-Host "❓ UNKNOWN DEVICES ($($unknown.Count)):" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "These devices don't match common patterns. CHECK MANUALLY!" -ForegroundColor Cyan
    Write-Host ""
    $unknown | ForEach-Object {
        Write-Host "  ? $($_.Name) ($($_.IP)) - VERIFY WHAT THIS IS!" -ForegroundColor Cyan
    }
    Write-Host ""
}

# Summary
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║                          SUMMARY                             ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Lab PCs:          $($labPCs.Count) (✅ Safe to deploy)" -ForegroundColor Green
Write-Host "  Smart Boards:     $($smartBoards.Count) (⚠️  DO NOT DEPLOY)" -ForegroundColor Yellow
Write-Host "  Teacher PCs:      $($teacherPCs.Count) (⚠️  DO NOT DEPLOY)" -ForegroundColor Yellow
Write-Host "  Unknown Devices:  $($unknown.Count) (❓ VERIFY FIRST)" -ForegroundColor Cyan
Write-Host ""

# Recommendations
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║                      RECOMMENDATIONS                         ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""

if ($unknown.Count -gt 0) {
    Write-Host "⚠️  ACTION REQUIRED: Unknown devices detected!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "You have $($unknown.Count) unknown device(s). Before deploying:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Option 1: Physically check these devices" -ForegroundColor Cyan
    Write-Host "  - Walk to the lab and check what these IPs are" -ForegroundColor Gray
    Write-Host "  - Look at the device name on screen or check with lab admin" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Option 2: Use manual IP selection" -ForegroundColor Cyan
    Write-Host "  - When running DEPLOY_TO_ALL_PCS.bat" -ForegroundColor Gray
    Write-Host "  - Choose option 2 (manual selection)" -ForegroundColor Gray
    Write-Host "  - Only enter IPs of confirmed lab PCs:" -ForegroundColor Gray
    foreach ($pc in $labPCs) {
        Write-Host "    $($pc.IP)" -ForegroundColor Green -NoNewline
        Write-Host " " -NoNewline
    }
    Write-Host ""
    Write-Host ""
}

if ($smartBoards.Count -gt 0) {
    Write-Host "✅ Good news: Smart boards detected automatically!" -ForegroundColor Green
    Write-Host "   These will be excluded by default patterns." -ForegroundColor Gray
    Write-Host ""
}

if ($labPCs.Count -gt 0 -and $unknown.Count -eq 0) {
    Write-Host "✅ All clear! Network layout is clean." -ForegroundColor Green
    Write-Host "   You can safely use auto-discovery and deploy to all!" -ForegroundColor Gray
    Write-Host ""
}

# Save to file for reference
$reportPath = "$env:TEMP\network_discovery_report.txt"
@"
NETWORK DISCOVERY REPORT
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Subnet: $subnet.0/24

LAB PCS ($($labPCs.Count)):
$($labPCs | ForEach-Object {"  $($_.Name) - $($_.IP)"} | Out-String)

SMART BOARDS ($($smartBoards.Count)):
$($smartBoards | ForEach-Object {"  $($_.Name) - $($_.IP)"} | Out-String)

TEACHER PCS ($($teacherPCs.Count)):
$($teacherPCs | ForEach-Object {"  $($_.Name) - $($_.IP)"} | Out-String)

UNKNOWN DEVICES ($($unknown.Count)):
$($unknown | ForEach-Object {"  $($_.Name) - $($_.IP)"} | Out-String)

SAFE TO DEPLOY IPs (Lab PCs only):
$($labPCs | ForEach-Object {$_.IP} | Out-String)
"@ | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "📄 Full report saved to: $reportPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
