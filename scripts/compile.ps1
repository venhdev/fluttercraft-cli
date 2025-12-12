# Buildcraft CLI - Compile Script (PowerShell)
# Compiles Dart CLI to native executable

param(
    [string]$Target = "windows",
    [string]$OutputDir = "dist/bin",
    [string]$Version = "0.0.2",
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Show help
if ($Help) {
    Write-Host "Usage: .\compile.ps1 [-Target <platform>] [-OutputDir <path>] [-Version <ver>]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Target     Target platform: windows, linux, macos (default: windows)"
    Write-Host "  -OutputDir  Output directory (default: dist/bin)"
    Write-Host "  -Version    Version for output filename (default: 0.0.2)"
    Write-Host "  -Help       Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\compile.ps1                        # buildcraft.v0.0.2.exe"
    Write-Host "  .\compile.ps1 -Version 1.0.0         # buildcraft.v1.0.0.exe"
    exit 0
}

# Determine executable name and extension
$exeName = "buildcraft"
switch ($Target.ToLower()) {
    "windows" { $exeExt = ".exe" }
    "linux"   { $exeExt = "" }
    "macos"   { $exeExt = "" }
    default   { 
        Write-Error "Unknown target: $Target" 
        exit 1
    }
}

$outputPath = Join-Path $OutputDir "$exeName.v$Version$exeExt"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  BUILDCRAFT CLI - Compiler" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Target:   $Target"
Write-Host "Version:  v$Version"
Write-Host "Output:   $outputPath"
Write-Host ""

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    Write-Host "Creating output directory: $OutputDir"
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Check if dart is available (prefer fvm)
$dartCmd = "dart"
if (Get-Command fvm -ErrorAction SilentlyContinue) {
    $dartCmd = "fvm dart"
    Write-Host "Using FVM Dart" -ForegroundColor Green
} else {
    Write-Host "Using system Dart" -ForegroundColor Yellow
}

# Compile
Write-Host ""
Write-Host "Compiling..." -ForegroundColor Cyan

try {
    if ($dartCmd -eq "fvm dart") {
        & fvm dart compile exe bin/buildcraft.dart -o $outputPath
    } else {
        & dart compile exe bin/buildcraft.dart -o $outputPath
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Compilation failed with exit code $LASTEXITCODE"
    }
    
    Write-Host ""
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host "Executable: $outputPath"
    
    # Show file size
    $fileInfo = Get-Item $outputPath
    $sizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
    Write-Host "Size: $sizeMB MB"
    Write-Host ""
    
    # Test the executable
    Write-Host "Testing executable..." -ForegroundColor Cyan
    & $outputPath --version
    
    Write-Host ""
    Write-Host "Done! You can now run:" -ForegroundColor Green
    Write-Host "  $outputPath"
    Write-Host "  $outputPath --help"
    Write-Host "  $outputPath build --type apk"
    
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
