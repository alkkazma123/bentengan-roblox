# Summit Kit - PowerShell Setup Script
# Run this in a fresh PowerShell window to set up the project.

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summit Kit - Rojo Project Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if aftman/rokit is installed
$hasAftman = Get-Command aftman -ErrorAction SilentlyContinue
$hasRokit = Get-Command rokit -ErrorAction SilentlyContinue

if ($hasRokit) {
    Write-Host "[1/4] Installing tools via Rokit..." -ForegroundColor Yellow
    rokit install
} elseif ($hasAftman) {
    Write-Host "[1/4] Installing tools via Aftman..." -ForegroundColor Yellow
    aftman install
} else {
    Write-Host "[1/4] Neither Aftman nor Rokit found." -ForegroundColor Red
    Write-Host "       Install Aftman: https://github.com/LPGhatguy/aftman" -ForegroundColor Gray
    Write-Host "       Install Rokit:  https://github.com/rojo-rbx/rokit" -ForegroundColor Gray
    Write-Host "       Or install Rojo manually: https://rojo.space/docs/v7/getting-started/installation/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "       Attempting to continue anyway..." -ForegroundColor Yellow
}

# Verify rojo is available
$hasRojo = Get-Command rojo -ErrorAction SilentlyContinue
if (-not $hasRojo) {
    Write-Host ""
    Write-Host "[ERROR] Rojo not found in PATH." -ForegroundColor Red
    Write-Host "        Please install Rojo first, then re-run this script." -ForegroundColor Red
    Write-Host "        https://rojo.space/docs/v7/getting-started/installation/" -ForegroundColor Gray
    exit 1
}

Write-Host "[2/4] Rojo found: $(rojo --version)" -ForegroundColor Green
Write-Host ""

# Build the place file
Write-Host "[3/4] Building place file..." -ForegroundColor Yellow
rojo build -o SummitGame.rbxlx
if ($LASTEXITCODE -eq 0) {
    Write-Host "       -> SummitGame.rbxlx created successfully!" -ForegroundColor Green
} else {
    Write-Host "       -> Build failed. Check default.project.json." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Start rojo serve
Write-Host "[4/4] Starting Rojo serve..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  INSTRUCTIONS:" -ForegroundColor White
Write-Host "  1. Open Roblox Studio" -ForegroundColor White
Write-Host "  2. Open SummitGame.rbxlx (or a blank place)" -ForegroundColor White
Write-Host "  3. Install Rojo Plugin if not already installed" -ForegroundColor White
Write-Host "  4. Click Rojo Plugin -> Connect" -ForegroundColor White
Write-Host "  5. Press F5 to Play - map builds automatically!" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the server." -ForegroundColor Gray
Write-Host ""

rojo serve
