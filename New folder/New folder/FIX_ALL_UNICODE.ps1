# ================================================================================================
# UNICODE/EMOJI FIX SCRIPT
# ================================================================================================
# This script replaces all Unicode emoji characters with ASCII equivalents
# Run this to fix all .bat and .ps1 files at once
# ================================================================================================

Write-Host "================================" -ForegroundColor Cyan
Write-Host "  FIXING UNICODE/EMOJI ERRORS"  -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Create replacements using Unicode code points to avoid parsing issues
$replacements = @{}

# Add emoji replacements using proper conversion for characters > U+FFFF
$replacements[[char]0x2705] = '[OK]'      # [OK]
$replacements[[char]0x274C] = '[X]'       # [X]
$replacements[[char]0x26A0 + [char]0xFE0F] = '[!]'  # ⚠
$replacements[[System.Char]::ConvertFromUtf32(0x1F525)] = '[HOT]'    # [HOT]
$replacements[[System.Char]::ConvertFromUtf32(0x1F680)] = '[START]'  # [START]
$replacements[[System.Char]::ConvertFromUtf32(0x1F4BB)] = 'CPU'      # CPU
$replacements[[System.Char]::ConvertFromUtf32(0x1F4CA)] = '[STATS]'  # [STATS]
$replacements[[System.Char]::ConvertFromUtf32(0x1F310)] = '[NET]'    # [NET]
$replacements[[System.Char]::ConvertFromUtf32(0x1F4BE)] = 'MEM'      # MEM
$replacements[[char]0x26A1] = '[ACTIVE]'  # [ACTIVE]
$replacements[[System.Char]::ConvertFromUtf32(0x1F3AF)] = '[TARGET]' # [TARGET]
$replacements[[char]0x23F0] = '[TIME]'    # [TIME]
$replacements[[System.Char]::ConvertFromUtf32(0x1F4F1)] = '[TELEGRAM]' # [TELEGRAM]
$replacements[[System.Char]::ConvertFromUtf32(0x1F527)] = '[FIX]'    # [FIX]
$replacements[[System.Char]::ConvertFromUtf32(0x1F50D)] = '[SCAN]'   # [SCAN]
$replacements[[System.Char]::ConvertFromUtf32(0x1F4B0)] = '[MONEY]'  # [MONEY]
$replacements[[System.Char]::ConvertFromUtf32(0x1F977)] = '[STEALTH]' # [STEALTH]
$replacements[[System.Char]::ConvertFromUtf32(0x1F4AA)] = '[POWER]'  # [POWER]
$replacements[[System.Char]::ConvertFromUtf32(0x1F389)] = '[SUCCESS]' # [SUCCESS]
$replacements[[System.Char]::ConvertFromUtf32(0x1F512)] = '[LOCK]'   # [LOCK]
$replacements[[System.Char]::ConvertFromUtf32(0x1F47B)] = '[GHOST]'  # [GHOST]
$replacements[[System.Char]::ConvertFromUtf32(0x1F5D1) + [char]0xFE0F] = '[DELETE]' # [DELETE]
$replacements[[System.Char]::ConvertFromUtf32(0x1F4C1)] = 'FILE'     # FILE
$replacements[[System.Char]::ConvertFromUtf32(0x1F194)] = 'ID'       # ID
$replacements[[char]0x23F1 + [char]0xFE0F] = '[TIMER]'  # ⏱
$replacements[[System.Char]::ConvertFromUtf32(0x1F4E1)] = 'SIGNAL'   # SIGNAL
$replacements[[System.Char]::ConvertFromUtf32(0x1F5A5) + [char]0xFE0F] = 'PC'      # 🖥
$replacements[[System.Char]::ConvertFromUtf32(0x1F4A1)] = '[NOTE]'   # [NOTE]
$replacements[[System.Char]::ConvertFromUtf32(0x1F4CB)] = '[MENU]'   # [MENU]
$replacements[[char]0x2B50] = '*'         # *
$replacements[[char]0x2550] = '='         # =
$replacements[[char]0x2500] = '-'         # -
$replacements[[char]0x2554] = '+'         # +
$replacements[[char]0x2557] = '+'         # +
$replacements[[char]0x255A] = '+'         # +
$replacements[[char]0x255D] = '+'         # +
$replacements[[char]0x2551] = '|'         # |
$replacements[[char]0x2714] = '[OK]'      # [OK]
$replacements[[char]0xFE0F] = ''          # Remove variation selector

$folder = $PSScriptRoot
$files = Get-ChildItem -Path $folder -Include *.bat,*.ps1 -Recurse

$fixedCount = 0
$totalFiles = $files.Count

Write-Host "Found $totalFiles files to check..." -ForegroundColor Yellow
Write-Host ""

foreach ($file in $files) {
    Write-Host "Checking: $($file.Name)..." -NoNewline
    
    try {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
        $modified = $false
        
        foreach ($emoji in $replacements.Keys) {
            if ($content -match [regex]::Escape($emoji)) {
                $content = $content -replace [regex]::Escape($emoji), $replacements[$emoji]
                $modified = $true
            }
        }
        
        if ($modified) {
            Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
            Write-Host " [FIXED]" -ForegroundColor Green
            $fixedCount++
        } else {
            Write-Host " [OK]" -ForegroundColor Gray
        }
    } catch {
        Write-Host " [ERROR]" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host "  COMPLETED!"  -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total files checked: $totalFiles" -ForegroundColor Yellow
Write-Host "Files fixed: $fixedCount" -ForegroundColor Green
Write-Host ""
Write-Host "All Unicode/emoji errors have been replaced with ASCII!" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
