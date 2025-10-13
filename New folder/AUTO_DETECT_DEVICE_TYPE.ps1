# ================================================================================================
# AUTOMATIC DEVICE TYPE DETECTION
# ================================================================================================
# Detects if current device is a smart board, lab PC, or other device type
# Called before deployment to prevent deploying to wrong devices
# ================================================================================================

function Get-DeviceType {
    Write-Host "[+] Auto-detecting device type..." -ForegroundColor Cyan
    
    $detectionResults = @{
        DeviceType = "Unknown"
        Confidence = 0
        Reasons = @()
        IsSmartBoard = $false
        IsLabPC = $false
        ShouldDeploy = $false
    }
    
    # ========== DETECTION 1: SCREEN RESOLUTION ==========
    Add-Type -AssemblyName System.Windows.Forms
    $screens = [System.Windows.Forms.Screen]::AllScreens
    
    foreach ($screen in $screens) {
        $width = $screen.Bounds.Width
        $height = $screen.Bounds.Height
        
        # Smart boards typically have:
        # - 4K resolution (3840×2160) or higher
        # - Very large physical size (55-86 inches)
        # - Single large display
        
        if ($width -ge 3840 -or $height -ge 2160) {
            $detectionResults.Reasons += "Ultra-high resolution detected: ${width}×${height} (typical of smart boards)"
            $detectionResults.Confidence += 30
        }
        
        if ($screens.Count -eq 1 -and $width -ge 1920 -and $height -ge 1080) {
            $detectionResults.Reasons += "Single large display: ${width}×${height}"
            $detectionResults.Confidence += 10
        }
    }
    
    # ========== DETECTION 2: TOUCH INPUT CAPABILITY ==========
    try {
        $hasTouchDigitizer = (Get-WmiObject -Query "SELECT * FROM Win32_PointingDevice" | 
                             Where-Object {$_.Description -match "Touch|Digitizer|HID"}).Count -gt 0
        
        if ($hasTouchDigitizer) {
            $detectionResults.Reasons += "Touch input digitizer detected (common on smart boards)"
            $detectionResults.Confidence += 25
        }
    } catch {}
    
    # ========== DETECTION 3: MANUFACTURER & MODEL ==========
    $computerSystem = Get-WmiObject Win32_ComputerSystem
    $manufacturer = $computerSystem.Manufacturer
    $model = $computerSystem.Model
    
    # Smart board manufacturers
    $smartBoardBrands = @("Samsung", "Promethean", "SMART Technologies", "ViewSonic", "BenQ", "Newline", "Clevertouch", "Vibe")
    
    foreach ($brand in $smartBoardBrands) {
        if ($manufacturer -match $brand -or $model -match $brand) {
            $detectionResults.Reasons += "Manufacturer/Model matches smart board brand: $manufacturer $model"
            $detectionResults.Confidence += 40
            break
        }
    }
    
    # Common lab PC manufacturers
    $labPCBrands = @("Dell", "HP", "Lenovo", "Acer", "ASUS")
    foreach ($brand in $labPCBrands) {
        if ($manufacturer -match $brand) {
            $detectionResults.Reasons += "Manufacturer matches typical lab PC: $manufacturer"
            $detectionResults.Confidence -= 10  # Reduces smart board likelihood
            break
        }
    }
    
    # ========== DETECTION 4: SMART BOARD SOFTWARE ==========
    $smartBoardSoftware = @(
        "ActivInspire",           # Promethean
        "SMART Notebook",         # SMART Board
        "SMART Meeting Pro",      # SMART Board
        "MagicIWB",              # Samsung
        "ViewBoard",             # ViewSonic
        "EZWrite",               # BenQ
        "myViewBoard",           # ViewSonic
        "InGlass",               # Clevertouch
        "vibe",                  # Vibe Board
        "Whiteboard",            # Generic
        "Teachmint",             # Teachmint (Indian schools)
        "TeachmintX"             # Teachmint X
    )
    
    $installedPrograms = Get-WmiObject -Class Win32_Product -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    $runningProcesses = Get-Process | Select-Object -ExpandProperty ProcessName
    
    foreach ($software in $smartBoardSoftware) {
        if ($installedPrograms -match $software -or $runningProcesses -match $software) {
            $detectionResults.Reasons += "Smart board software detected: $software"
            $detectionResults.Confidence += 35
            break
        }
    }
    
    # ========== DETECTION 5: DEVICE FORM FACTOR ==========
    $chassis = Get-WmiObject Win32_SystemEnclosure
    $chassisType = $chassis.ChassisTypes[0]
    
    # Chassis types:
    # 3 = Desktop
    # 4 = Low Profile Desktop
    # 13 = All in One
    # 30 = Tablet
    # 31 = Convertible
    
    if ($chassisType -eq 13) {
        # All-in-One could be smart board or desktop
        $detectionResults.Reasons += "All-in-One form factor detected"
        $detectionResults.Confidence += 5
    } elseif ($chassisType -eq 3 -or $chassisType -eq 4) {
        $detectionResults.Reasons += "Desktop form factor (typical lab PC)"
        $detectionResults.Confidence -= 15
    }
    
    # ========== DETECTION 6: POWER PLAN (Smart boards often on "Presentation" mode) ==========
    try {
        $powerPlan = powercfg /getactivescheme
        if ($powerPlan -match "Presentation|Kiosk") {
            $detectionResults.Reasons += "Presentation power plan detected (common on smart boards)"
            $detectionResults.Confidence += 10
        }
    } catch {}
    
    # ========== DETECTION 7: DISPLAY PORT TYPE ==========
    try {
        $monitors = Get-WmiObject WmiMonitorID -Namespace root\wmi -ErrorAction SilentlyContinue
        foreach ($monitor in $monitors) {
            $name = ($monitor.UserFriendlyName | ForEach-Object {[char]$_}) -join ''
            
            if ($name -match "SMART|Samsung|Promethean|ViewBoard|Interactive|Touch") {
                $detectionResults.Reasons += "Display name suggests smart board: $name"
                $detectionResults.Confidence += 30
                break
            }
        }
    } catch {}
    
    # ========== DETECTION 8: USB DEVICES (Smart boards have touch controllers) ==========
    try {
        $usbDevices = Get-WmiObject Win32_USBControllerDevice | ForEach-Object {
            [wmi]($_.Dependent)
        } | Select-Object Description
        
        foreach ($device in $usbDevices) {
            if ($device.Description -match "Touch|Digitizer|Interactive|SMART|Promethean") {
                $detectionResults.Reasons += "USB touch controller detected: $($device.Description)"
                $detectionResults.Confidence += 20
                break
            }
        }
    } catch {}
    
    # ========== DETECTION 9: NETWORK NAME PATTERN ==========
    $hostname = $env:COMPUTERNAME
    
    if ($hostname -match "SMARTBOARD|SMART-BOARD|ANDROID-BOARD|IFP|WHITEBOARD|DISPLAY|BOARD|ROOM-\d+-DISPLAY") {
        $detectionResults.Reasons += "Hostname pattern suggests smart board: $hostname"
        $detectionResults.Confidence += 50
    }
    
    if ($hostname -match "LAB|PC-\d+|STUDENT|COMP|WORKSTATION") {
        $detectionResults.Reasons += "Hostname pattern suggests lab PC: $hostname"
        $detectionResults.Confidence -= 20
    }
    
    # ========== FINAL DETERMINATION ==========
    if ($detectionResults.Confidence -ge 50) {
        $detectionResults.DeviceType = "Smart Board / Interactive Display"
        $detectionResults.IsSmartBoard = $true
        $detectionResults.ShouldDeploy = $false
    } elseif ($detectionResults.Confidence -le -10) {
        $detectionResults.DeviceType = "Lab PC / Desktop Computer"
        $detectionResults.IsLabPC = $true
        $detectionResults.ShouldDeploy = $true
    } else {
        $detectionResults.DeviceType = "Unknown / Uncertain"
        $detectionResults.ShouldDeploy = $false  # When uncertain, don't deploy
    }
    
    return $detectionResults
}

# ================================================================================================
# MAIN EXECUTION (if run directly)
# ================================================================================================

if ($MyInvocation.InvocationName -ne '.') {
    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║            DEVICE TYPE AUTO-DETECTION RESULTS                ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    $result = Get-DeviceType
    
    Write-Host "Device: $env:COMPUTERNAME" -ForegroundColor White
    Write-Host "Detected Type: $($result.DeviceType)" -ForegroundColor $(if($result.IsSmartBoard){"Yellow"}elseif($result.IsLabPC){"Green"}else{"Cyan"})
    Write-Host "Confidence Score: $($result.Confidence)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Detection Reasons:" -ForegroundColor White
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    foreach ($reason in $result.Reasons) {
        Write-Host "  • $reason" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    if ($result.IsSmartBoard) {
        Write-Host "`n⚠️  WARNING: This device appears to be a SMART BOARD!" -ForegroundColor Yellow
        Write-Host "└─ Deployment recommendation: DO NOT DEPLOY" -ForegroundColor Yellow
        Write-Host "└─ Reason: High visibility, will be detected immediately" -ForegroundColor Yellow
    } elseif ($result.IsLabPC) {
        Write-Host "`n✅ This device appears to be a LAB PC" -ForegroundColor Green
        Write-Host "└─ Deployment recommendation: SAFE TO DEPLOY" -ForegroundColor Green
    } else {
        Write-Host "`n❓ Device type is UNCERTAIN" -ForegroundColor Cyan
        Write-Host "└─ Deployment recommendation: VERIFY MANUALLY before deploying" -ForegroundColor Cyan
        Write-Host "└─ Confidence score too low for automatic decision" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
