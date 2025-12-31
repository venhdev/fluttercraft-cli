# fluttercraft CLI - Compile Script (PowerShell)
# Compiles Dart CLI to native executable

param(
    [string]$Target = "windows",
    [string]$Version = "0.1.1",
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Show help
if ($Help) {
    Write-Host "Usage: .\compile.ps1 [-Target <platform>]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Target     Target platform: windows, linux, macos (default: windows)"
    Write-Host "  -Help       Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\compile.ps1                        # bin/fluttercraft.exe"
    Write-Host "  .\compile.ps1 -Target linux          # bin/fluttercraft"
    Write-Host ""
    Write-Host "Output:"
    Write-Host "  bin/fluttercraft.exe                   # Latest version (no version suffix)"
    exit 0
}

# Determine executable name and extension
$exeName = "fluttercraft"
switch ($Target.ToLower()) {
    "windows" { $exeExt = ".exe" }
    "linux"   { $exeExt = "" }
    "macos"   { $exeExt = "" }
    default   { 
        Write-Error "Unknown target: $Target" 
        exit 1
    }
}

# Define output paths
$outputPath = Join-Path "bin" "$exeName$exeExt"
$aliasPath = Join-Path "bin" "flc$exeExt"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  fluttercraft CLI - Compiler" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Target:   $Target"
Write-Host "Output:   $outputPath"
Write-Host "Alias:    $aliasPath"
Write-Host ""

# Ensure output directory exists
if (-not (Test-Path "bin")) {
    Write-Host "Creating output directory: bin"
    New-Item -ItemType Directory -Path "bin" -Force | Out-Null
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
        & fvm dart compile exe bin/fluttercraft.dart -o $outputPath
    } else {
        & dart compile exe bin/fluttercraft.dart -o $outputPath
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
    
    # Create alias copy
    Write-Host ""
    Write-Host "Creating alias executable..." -ForegroundColor Cyan
    Copy-Item $outputPath $aliasPath -Force
    Write-Host "Alias created: $aliasPath" -ForegroundColor Green
    Write-Host ""
    
    # Test the executable
    Write-Host "Testing executables..." -ForegroundColor Cyan
    & $outputPath --version
    
    Write-Host ""
    Write-Host "Done! You can now run:" -ForegroundColor Green
    Write-Host "  $outputPath"
    Write-Host "  $aliasPath"
    Write-Host "  $aliasPath --help"
    Write-Host "  $aliasPath build --type apk"
    
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}

