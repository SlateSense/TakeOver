@echo off
title [TARGET] MINER DASHBOARD - Competition Monitor
color 0B
mode con: cols=80 lines=35

:MENU
cls
echo.
echo  +======================================================================+
echo  |                  [TARGET] MINER CONTROL DASHBOARD                          |
echo  +======================================================================+
echo.
echo  ┌------------------------------------------------------------------┐
echo  │  MONITORING OPTIONS:                                              │
echo  └------------------------------------------------------------------┘
echo.
echo    [1] [SCAN] Quick Status Check (2 seconds)
echo    [2] [STATS] Continuous Monitor (live updates every 10s)
echo    [3] [CHART] Detailed Analysis (full system info)
echo.
echo  ┌------------------------------------------------------------------┐
echo  │  FLEET MANAGEMENT:                                                │
echo  └------------------------------------------------------------------┘
echo.
echo    [4] [NET] Check All PCs Status (MONITOR_FLEET.ps1)
echo    [5] [START] Deploy to All PCs
echo    [6] [TELEGRAM] Open Pool Dashboard (MoneroOcean)
echo.
echo  ┌------------------------------------------------------------------┐
echo  │  UTILITIES:                                                       │
echo  └------------------------------------------------------------------┘
echo.
echo    [7] [DOCS] View Documentation
echo    [8] [RESTART] Restart Miner (This PC)
echo    [9] [STOP] Stop Miner (This PC)
echo.
echo    [0] [X] Exit
echo.
echo  ======================================================================
echo.
set /p choice="  Select option (0-9): "

if "%choice%"=="1" goto QUICK
if "%choice%"=="2" goto CONTINUOUS
if "%choice%"=="3" goto DETAILED
if "%choice%"=="4" goto FLEET
if "%choice%"=="5" goto DEPLOY
if "%choice%"=="6" goto POOL
if "%choice%"=="7" goto DOCS
if "%choice%"=="8" goto RESTART
if "%choice%"=="9" goto STOP
if "%choice%"=="0" goto EXIT

echo  Invalid choice! Press any key to try again...
pause >nul
goto MENU

:QUICK
cls
echo.
echo  +======================================================================+
echo  |                     [SCAN] QUICK STATUS CHECK                            |
echo  +======================================================================+
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0CHECK_MINER_STATUS.ps1"
echo.
echo  Press any key to return to menu...
pause >nul
goto MENU

:CONTINUOUS
cls
echo.
echo  +======================================================================+
echo  |                   [STATS] CONTINUOUS MONITORING                           |
echo  |                    (Press Ctrl+C to stop)                            |
echo  +======================================================================+
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0CHECK_MINER_STATUS.ps1" -Loop
goto MENU

:DETAILED
cls
echo.
echo  +======================================================================+
echo  |                     [CHART] DETAILED ANALYSIS                        |
echo  +======================================================================+
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0CHECK_MINER_STATUS.ps1" -Detailed
echo.
echo  Press any key to return to menu...
pause >nul
goto MENU

:FLEET
cls
echo.
echo  +======================================================================+
echo  |                    [NET] CHECKING ALL PCS...                            |
echo  +======================================================================+
echo.
if exist "%~dp0..\MONITOR_FLEET.ps1" (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0..\MONITOR_FLEET.ps1"
) else (
    echo  [X] MONITOR_FLEET.ps1 not found in current folder!
    echo.
    echo  Make sure all files are in the same directory.
)
echo.
echo  Press any key to return to menu...
pause >nul
goto MENU

:DEPLOY
cls
echo.
echo  +======================================================================+
echo  |                   [START] DEPLOY TO ALL PCS                               |
echo  +======================================================================+
echo.
echo  [!]  This will deploy the miner to all PCs in pc_list.txt
echo.
set /p confirm="  Continue? (Y/N): "
if /i not "%confirm%"=="Y" goto MENU

if exist "%~dp0..\DEPLOY_TO_ALL_PCS.bat" (
    call "%~dp0..\DEPLOY_TO_ALL_PCS.bat"
) else (
    echo  [X] DEPLOY_TO_ALL_PCS.bat not found!
)
echo.
echo  Press any key to return to menu...
pause >nul
goto MENU

:POOL
cls
echo.
echo  +======================================================================+
echo  |                   [TELEGRAM] OPENING POOL DASHBOARD                          |
echo  +======================================================================+
echo.
echo  Opening MoneroOcean dashboard in your browser...
echo.
start https://moneroocean.stream/
timeout /t 2 >nul
goto MENU

:DOCS
cls
type "%~dp0HOW_TO_CHECK_MINER.txt"
echo.
echo  Press any key to return to menu...
pause >nul
goto MENU

:RESTART
cls
echo.
echo  +======================================================================+
echo  |                     [RESTART] RESTARTING MINER                       |
echo  +======================================================================+
echo.
echo  Stopping current miner...
taskkill /F /IM audiodg.exe >nul 2>&1
timeout /t 3 >nul
echo  [OK] Stopped
echo.
echo  Starting miner...
if exist "%~dp0..\DEPLOY_ULTIMATE.ps1" (
    powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0..\DEPLOY_ULTIMATE.ps1"
    echo  [OK] Miner restarted!
) else (
    echo  [X] DEPLOY_ULTIMATE.ps1 not found!
)
echo.
echo  Press any key to return to menu...
pause >nul
goto MENU

:STOP
cls
echo.
echo  +======================================================================+
echo  |                      🛑 STOPPING MINER                               |
echo  +======================================================================+
echo.
echo  [!]  WARNING: This will stop mining on THIS PC only!
echo.
set /p confirm="  Are you sure? (Y/N): "
if /i not "%confirm%"=="Y" goto MENU

echo.
echo  Stopping miner...
taskkill /F /IM audiodg.exe >nul 2>&1
echo  [OK] Miner stopped
echo.
echo  Press any key to return to menu...
pause >nul
goto MENU

:EXIT
cls
echo.
echo  +======================================================================+
echo  |                         👋 GOODBYE!                                  |
echo  +======================================================================+
echo.
echo  Good luck with your Red vs Blue competition! [START]
echo.
timeout /t 2 >nul
exit
