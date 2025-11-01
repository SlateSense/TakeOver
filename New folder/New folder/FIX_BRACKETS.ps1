$content = Get-Content 'DEPLOY_ULTIMATE.ps1' -Raw

# Remove all [OK], [!], [HOT], [TARGET], [AUTO], [LOCK], [SCAN], [SAFE], [FIX], [X] from Write-Log statements
$content = $content -replace 'Write-Log "\[OK\] ', 'Write-Log "'
$content = $content -replace 'Write-Log "\[!\] ', 'Write-Log "'
$content = $content -replace 'Write-Log "\[HOT\] ', 'Write-Log "'
$content = $content -replace 'Write-Log "\[TARGET\] ', 'Write-Log "'
$content = $content -replace 'Write-Log "\[AUTO\] ', 'Write-Log "'
$content = $content -replace 'Write-Log "\[LOCK\] ', 'Write-Log "'
$content = $content -replace 'Write-Log "\[SCAN\] ', 'Write-Log "'
$content = $content -replace 'Write-Log "\[SAFE\] ', 'Write-Log "'
$content = $content -replace 'Write-Log "\[SAFE TEST MODE\] ', 'Write-Log "SAFE TEST MODE: '
$content = $content -replace 'Write-Log "\[FIX\] ', 'Write-Log "'
$content = $content -replace 'Write-Log "\[X\] ', 'Write-Log "'

$content | Set-Content 'DEPLOY_ULTIMATE.ps1' -NoNewline

Write-Host "Fixed all square brackets in Write-Log statements" -ForegroundColor Green
