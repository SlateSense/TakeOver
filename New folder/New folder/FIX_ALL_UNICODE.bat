@echo off
title Fix All Unicode Errors
color 0A

echo.
echo ================================================================
echo   FIX ALL UNICODE/EMOJI ERRORS IN ALL FILES
echo ================================================================
echo.
echo This will automatically fix all .bat and .ps1 files
echo in this folder by replacing emojis with ASCII text.
echo.
pause

powershell.exe -ExecutionPolicy Bypass -File "%~dp0FIX_ALL_UNICODE.ps1"

echo.
echo Done! All files have been fixed.
echo.
pause
