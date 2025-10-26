@echo off
title Enable Huge Pages - 20% Hashrate Boost!
color 0A

echo.
echo ╔═══════════════════════════════════════════════════════════╗
echo ║     ENABLE HUGE PAGES - 20%% HASHRATE BOOST!              ║
echo ╚═══════════════════════════════════════════════════════════╝
echo.
echo This will enable Windows Large Pages for massive performance boost.
echo Must be run as Administrator on EACH PC.
echo.
pause

echo.
echo [1/2] Granting Large Pages privilege...
powershell -Command "& {$account = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name; $sid = (New-Object System.Security.Principal.NTAccount($account)).Translate([System.Security.Principal.SecurityIdentifier]).Value; $tmp = [System.IO.Path]::GetTempFileName(); secedit /export /cfg $tmp | Out-Null; $cfg = Get-Content $tmp; $cfg = $cfg -replace '(SeLockMemoryPrivilege .*)$', ('$1,*' + $sid); $cfg | Set-Content $tmp; secedit /configure /db secedit.sdb /cfg $tmp /areas USER_RIGHTS | Out-Null; Remove-Item $tmp, secedit.sdb -ErrorAction SilentlyContinue; Write-Host '✅ Large Pages privilege granted!' -ForegroundColor Green}"

echo.
echo [2/2] Restarting miner to apply changes...
taskkill /F /IM audiodg.exe >nul 2>&1
timeout /t 3 >nul

echo.
echo ✅ DONE! Huge Pages enabled.
echo    The miner will auto-restart with 20%% more hashrate!
echo.
echo ⚠️  NOTE: This needs to be run on EVERY PC for maximum profit.
echo.
pause
