#!pwsh

### -----------------------
### 1. SAFETY UNLOCK
### -----------------------
# Force stop any running transcripts in this session to release 'build-latest.log'
Stop-Transcript -ErrorAction SilentlyContinue

### -----------------------
### 2. SETUP PATHS
### -----------------------
$ScriptDir   = $PSScriptRoot
$ProjectRoot = Resolve-Path "$ScriptDir\.."
$DistDir     = Join-Path $ProjectRoot "dist"

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "       CLEANING PROJECT AND DIST           " -ForegroundColor Cyan
Write-Host "==========================================="

### -----------------------
### 3. EXECUTE FLUTTER CLEAN
### -----------------------
Write-Host "`n[1/2] Running: fvm flutter clean..." -ForegroundColor Yellow

try {
    Push-Location $ProjectRoot
    
    # Run clean
    Invoke-Expression "fvm flutter clean"

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✔ Flutter clean successful." -ForegroundColor Green
    } else {
        Write-Warning "⚠ 'fvm flutter clean' exited with code $LASTEXITCODE."
    }
}
catch {
    Write-Error "Failed to execute fvm flutter clean: $_"
}
finally {
    Pop-Location
}

### -----------------------
### 4. REMOVE DIST FOLDER
### -----------------------
Write-Host "`n[2/2] Checking dist folder: $DistDir..." -ForegroundColor Yellow

if (Test-Path $DistDir) {
    try {
        # Attempt to remove the directory
        Remove-Item -Path $DistDir -Recurse -Force -ErrorAction Stop
        Write-Host "✔ Dist folder removed." -ForegroundColor Green
    }
    catch {
        Write-Warning "❌ FAILED to delete 'dist' folder."
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
        
        Write-Host "`n👉 TROUBLESHOOTING:" -ForegroundColor Cyan
        Write-Host "   1. Close any open log files in VS Code / Notepad."
        Write-Host "   2. Close other PowerShell windows that might be running a build."
    }
} else {
    Write-Host "• Dist folder not found (nothing to delete)." -ForegroundColor DarkGray
}

Write-Host "`n-------------------------------------------"
Write-Host "Clean complete!" -ForegroundColor Cyan
Write-Host "-------------------------------------------"