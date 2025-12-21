# BetterResting - Clear Cache and Update Script
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "BetterResting - Cache Clear and Update" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Close Project Zomboid
Write-Host "Step 1: Closing Project Zomboid..." -ForegroundColor Yellow
$zomboidProcesses = Get-Process -Name "ProjectZomboid*" -ErrorAction SilentlyContinue
if ($zomboidProcesses) {
    $zomboidProcesses | Stop-Process -Force
    Start-Sleep -Seconds 2
    Write-Host "  Processes closed" -ForegroundColor Green
} else {
    Write-Host "  No processes found" -ForegroundColor Green
}

# Step 2: Clear Lua cache
Write-Host ""
Write-Host "Step 2: Clearing Lua cache..." -ForegroundColor Yellow
$luaCachePath = "$env:USERPROFILE\Zomboid\Lua"
if (Test-Path $luaCachePath) {
    Remove-Item -Path $luaCachePath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  Lua cache cleared" -ForegroundColor Green
} else {
    Write-Host "  Lua cache folder not found" -ForegroundColor Gray
}

# Step 3: Copy files
Write-Host ""
Write-Host "Step 3: Copying files..." -ForegroundColor Yellow
$sourceDir = "C:\Users\Emilio\Desktop\BetterResting\mods\BetterResting"
$destDir1 = "C:\Users\Emilio\Zomboid\mods\BetterResting"
$destDir2 = "C:\Users\Emilio\Zomboid\Workshop\BetterResting - Copy\Contents\mods\BetterResting"

if (Test-Path $sourceDir) {
    if (Test-Path $destDir1) {
        Copy-Item -Path "$sourceDir\*" -Destination "$destDir1\" -Recurse -Force
        Write-Host "  Copied to local mods folder" -ForegroundColor Green
    }
    if (Test-Path $destDir2) {
        Copy-Item -Path "$sourceDir\*" -Destination "$destDir2\" -Recurse -Force
        Write-Host "  Copied to Workshop folder" -ForegroundColor Green
    }
} else {
    Write-Host "  Source directory not found!" -ForegroundColor Red
}

# Step 4: Verify
Write-Host ""
Write-Host "Step 4: Verifying..." -ForegroundColor Yellow
$modInfoPath = "$destDir1\mod.info"
if (Test-Path $modInfoPath) {
    $modVersion = Get-Content $modInfoPath | Select-String -Pattern "modversion="
    Write-Host "  Mod version: $modVersion" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Complete! Launch Project Zomboid now." -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
