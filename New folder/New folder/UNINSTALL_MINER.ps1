# =====================================================================
# UNINSTALL_MINER.ps1 - Complete Miner Cleanup
# =====================================================================
# Removes miner files, persistence, scheduled tasks, startup entries
# Does NOT change Windows Defender / Antivirus settings
# =====================================================================

# Force run as Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   MINER FULL UNINSTALL STARTED" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# ========== 1. Stop all miner processes ==========
Write-Host "[1] Stopping miner processes..." -ForegroundColor Yellow

$processNames = @("audiodg.exe", "xmrig.exe", "AudioSrv.exe")
foreach ($proc in $processNames) {
    Get-Process -Name $proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2
Write-Host "    Done." -ForegroundColor Green

# ========== 2. Remove scheduled tasks ==========
Write-Host "[2] Removing scheduled tasks..." -ForegroundColor Yellow

$taskNames = @(
    "WinUpdSvc",
    "WindowsUpdateWatchdog",
    "WindowsUpdateService",
    "AudioSrv",
    "WindowsUpdate",
    "MicrosoftEdgeUpdate"
)

foreach ($task in $taskNames) {
    schtasks /delete /tn $task /f 2>$null
}
Write-Host "    Done." -ForegroundColor Green

# ========== 3. Remove from Startup folder ==========
Write-Host "[3] Cleaning Startup folder..." -ForegroundColor Yellow

$startupPaths = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\SILENT_LAUNCH.vbs",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\launch.vbs",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\start_miner.vbs",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\SILENT_LAUNCH.vbs"
)

foreach ($path in $startupPaths) {
    if (Test-Path $path) {
        Remove-Item $path -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "    Done." -ForegroundColor Green

# ========== 4. Remove common miner folders ==========
Write-Host "[4] Removing miner folders..." -ForegroundColor Yellow

$folders = @(
    "C:\ProgramData\Microsoft\Windows\WindowsUpdate",
    "C:\ProgramData\WindowsUpdater",
    "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv",
    "C:\ProgramData\Microsoft\Network\Downloader",
    "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell",
    "$env:LOCALAPPDATA\Microsoft\Windows\Defender",
    "$env:APPDATA\Microsoft\Windows\Templates",
    "$env:TEMP\WindowsUpdateCache"
)

foreach ($folder in $folders) {
    if (Test-Path $folder) {
        # Only delete if it contains miner-related files
        $hasMiner = Get-ChildItem $folder -Recurse -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match "audiodg|xmrig|config\.json|watchdog|SILENT_LAUNCH"
        }
        if ($hasMiner) {
            Remove-Item $folder -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "    Removed: $folder" -ForegroundColor Gray
        }
    }
}
Write-Host "    Done." -ForegroundColor Green

# ========== 5. Clean Registry Run keys ==========
Write-Host "[5] Cleaning Registry Run keys..." -ForegroundColor Yellow

$regPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
)

$keysToRemove = @("WindowsUpdate", "AudioSrv", "WinUpdSvc", "SILENT_LAUNCH", "xmrig", "audiodg")

foreach ($regPath in $regPaths) {
    foreach ($key in $keysToRemove) {
        Remove-ItemProperty -Path $regPath -Name $key -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "    Done." -ForegroundColor Green

# ========== 6. Remove remaining files ==========
Write-Host "[6] Final cleanup..." -ForegroundColor Yellow

$extraFiles = @(
    "$env:TEMP\ultimate_deploy.log",
    "$env:TEMP\miner_debug.log",
    "$env:TEMP\xmrig_latest.zip",
    "$env:TEMP\xmrig_extract"
)

foreach ($file in $extraFiles) {
    if (Test-Path $file) {
        Remove-Item $file -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "    Done." -ForegroundColor Green

# ========== Finished ==========
Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "   UNINSTALL COMPLETED SUCCESSFULLY" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Miner and all related persistence have been removed." -ForegroundColor White
Write-Host "Windows Defender settings were NOT changed." -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")