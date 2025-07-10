@echo off
setlocal

:: === Telegram Bot Configuration ===
set "BOT_TOKEN=7895971971:AAFLygxcPbKIv31iwsbkB2YDMj-12e7_YSE"
set "CHAT_ID=8112985977"
set "MESSAGE=🚨 XMRig restarted or crashed on %COMPUTERNAME% at %TIME% on %DATE%."

:: === Send Telegram Alert ===
curl -s -X POST "https://api.telegram.org/bot%BOT_TOKEN%/sendMessage" ^
  -d "chat_id=%CHAT_ID%" ^
  -d "text=%MESSAGE%" >nul

echo [✔] Telegram alert sent.
