@echo off
setlocal
cd /d "%~dp0"

:: Elevate if not running as Administrator
net session >nul 2>&1
if %errorlevel% NEQ 0 (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

:: Run uninstaller and keep window open
powershell -NoProfile -ExecutionPolicy Bypass -File ".\UNINSTALL_ULTIMATE.ps1" -VerboseLog
echo.
echo Uninstall finished. Review %TEMP%\ultimate_uninstall.log for details.
pause
endlocal
