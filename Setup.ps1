# ============================================================
# Summit Kit - Game Gunung | PowerShell Setup (FRESH)
# ============================================================
# Jalankan script ini di PowerShell yang baru dibuka.
# Script ini akan: clone repo, checkout branch, merge ke main,
# dan serve Rojo.
#
# CARA PAKAI:
#   1. Buka PowerShell
#   2. Jalankan:
#      Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
#   3. Clone repo:
#      git clone https://github.com/alkkazma123/bentengan-roblox.git
#      cd bentengan-roblox
#   4. Jalankan setup:
#      .\Setup.ps1
# ============================================================

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   SUMMIT KIT - Game Gunung Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if we're in the repo already
$inRepo = Test-Path "default.project.json"
if (-not $inRepo) {
    Write-Host "[1/6] Cloning repository..." -ForegroundColor Yellow
    git clone https://github.com/alkkazma123/bentengan-roblox.git
    Set-Location bentengan-roblox
} else {
    Write-Host "[1/6] Already in repo directory." -ForegroundColor Green
}

# Step 2: Fetch and checkout summit-kit branch
Write-Host "[2/6] Fetching latest..." -ForegroundColor Yellow
git fetch origin

# Step 3: Merge summit-kit into main
Write-Host "[3/6] Merging summit-kit ke main..." -ForegroundColor Yellow
git checkout main 2>$null
if ($LASTEXITCODE -ne 0) {
    git checkout -b main origin/main
}
git merge origin/devin/1777857766-summit-kit-standalone --no-edit
if ($LASTEXITCODE -ne 0) {
    Write-Host "       Merge conflict! Accepting theirs..." -ForegroundColor Yellow
    git merge --abort
    git merge origin/devin/1777857766-summit-kit-standalone --strategy-option=theirs --no-edit
}
git push origin main
Write-Host "       Summit kit sudah di-merge ke main!" -ForegroundColor Green
Write-Host ""

# Step 4: Check for Rojo
Write-Host "[4/6] Checking Rojo..." -ForegroundColor Yellow
$hasRojo = Get-Command rojo -ErrorAction SilentlyContinue
if (-not $hasRojo) {
    $hasAftman = Get-Command aftman -ErrorAction SilentlyContinue
    $hasRokit = Get-Command rokit -ErrorAction SilentlyContinue
    if ($hasRokit) {
        rokit install
    } elseif ($hasAftman) {
        aftman install
    } else {
        Write-Host ""
        Write-Host "  [!] Rojo belum terinstall." -ForegroundColor Red
        Write-Host "      Install salah satu:" -ForegroundColor White
        Write-Host "        - Aftman: https://github.com/LPGhatguy/aftman" -ForegroundColor Gray
        Write-Host "        - Rokit:  https://github.com/rojo-rbx/rokit" -ForegroundColor Gray
        Write-Host "        - Rojo:   https://rojo.space/docs/v7/getting-started/installation/" -ForegroundColor Gray
        Write-Host ""
        Write-Host "      Setelah install, jalankan ulang script ini." -ForegroundColor White
        exit 1
    }
    $hasRojo = Get-Command rojo -ErrorAction SilentlyContinue
    if (-not $hasRojo) {
        Write-Host "  [!] Rojo masih tidak ditemukan." -ForegroundColor Red
        exit 1
    }
}
Write-Host "       Rojo found: $(rojo --version)" -ForegroundColor Green
Write-Host ""

# Step 5: Build place file
Write-Host "[5/6] Building SummitKit.rbxlx..." -ForegroundColor Yellow
rojo build -o SummitKit.rbxlx
if ($LASTEXITCODE -eq 0) {
    Write-Host "       SummitKit.rbxlx berhasil dibuat!" -ForegroundColor Green
} else {
    Write-Host "       Build gagal! Pastikan rojo terinstall dengan benar." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 6: Serve
Write-Host "[6/6] Memulai Rojo serve..." -ForegroundColor Yellow
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  LANGKAH SELANJUTNYA:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Buka Roblox Studio" -ForegroundColor White
Write-Host "  2. Buka file SummitKit.rbxlx" -ForegroundColor White
Write-Host "     (atau place kosong)" -ForegroundColor Gray
Write-Host "  3. Install Rojo Plugin jika belum" -ForegroundColor White
Write-Host "  4. Klik Rojo Plugin -> Connect" -ForegroundColor White
Write-Host "  5. Tekan F5 untuk Play!" -ForegroundColor White
Write-Host ""
Write-Host "  Map (Start, Checkpoints, Finish," -ForegroundColor Gray
Write-Host "  KillParts) akan di-build otomatis!" -ForegroundColor Gray
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tekan Ctrl+C untuk stop server." -ForegroundColor Gray
Write-Host ""

rojo serve
