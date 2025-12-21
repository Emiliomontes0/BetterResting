# BetterResting - Copy to Zomboid Mods Directory
# This script copies all mod files to both Zomboid directories

$sourceDir = "C:\Users\Emilio\Desktop\BetterResting\mods\BetterResting"
$destDir1 = "C:\Users\Emilio\Zomboid\mods\BetterResting"
$destDir2 = "C:\Users\Emilio\Zomboid\Workshop\BetterResting - Copy\Contents\mods\BetterResting"

Write-Host "Copying BetterResting mod files to both locations..." -ForegroundColor Green

# Copy to first location (local mods)
Write-Host "Copying to: $destDir1" -ForegroundColor Cyan
if (Test-Path $destDir1) {
    Copy-Item -Path "$sourceDir\*" -Destination "$destDir1\" -Recurse -Force
    Write-Host "  ✓ Copied to local mods folder" -ForegroundColor Green
} else {
    Write-Host "  ✗ Destination not found: $destDir1" -ForegroundColor Red
}

# Copy to second location (Workshop)
Write-Host "Copying to: $destDir2" -ForegroundColor Cyan
if (Test-Path $destDir2) {
    Copy-Item -Path "$sourceDir\*" -Destination "$destDir2\" -Recurse -Force
    Write-Host "  ✓ Copied to Workshop folder" -ForegroundColor Green
} else {
    Write-Host "  ✗ Destination not found: $destDir2" -ForegroundColor Yellow
    Write-Host "  (This is okay if you're not using Workshop testing)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Files copied successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: To see changes, you must:" -ForegroundColor Yellow
Write-Host "1. Completely close the game/server" -ForegroundColor Yellow
Write-Host "2. Restart the game/server" -ForegroundColor Yellow
Write-Host "3. The mod will reload with new changes" -ForegroundColor Yellow
Write-Host ""
Write-Host "Just reloading won't work - you need a full restart!" -ForegroundColor Red

