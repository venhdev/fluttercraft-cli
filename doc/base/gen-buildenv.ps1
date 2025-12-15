#!pwsh
<#
    gen-buildenv.ps1
    -----------------
    1. Detects App Info (Pubspec, FVM, Shorebird).
    2. Dynamically reads ALL defaults from buildenv.base.
    3. Merges detected info (Pubspec is strictly the Source of Truth).
    4. Generates a CLEAN .buildenv file.
#>

Write-Host "=== BuildEnv Generator ===" -ForegroundColor Cyan

# --- 1. Paths ---
$ScriptDir       = $PSScriptRoot
$ProjectRoot     = Resolve-Path "$ScriptDir\.."
$BuildEnvFile    = Join-Path $ScriptDir ".buildenv"
$BaseFile        = Join-Path $ScriptDir "buildenv.base"
$Pubspec         = Join-Path $ProjectRoot "pubspec.yaml"
$FvmRc           = Join-Path $ProjectRoot ".fvmrc"
$ShorebirdConfig = Join-Path $ProjectRoot "shorebird.yaml"
$RootEnvFile     = Join-Path $ProjectRoot ".env"

if (-not (Test-Path $BaseFile)) {
    Write-Warning "buildenv.base not found. Using empty defaults."
}

# --- 2. Initialize Config Map (Ordered) ---
$Config = [ordered]@{
    APPNAME = "app"
    BUILD_NAME = "1.0.0"
    BUILD_NUMBER = "1"
    
    OUTPUT_PATH = "dist"
    ENV_PATH = ""
    
    USE_FVM = "false"
    FLUTTER_VERSION = ""
    
    USE_SHOREBIRD = "false"
    SHOREBIRD_ARTIFACT = ""
    SHOREBIRD_AUTO_CONFIRM = "false"
    
    USE_DART_DEFINE = "false"
    BUILD_TYPE = "apk"
    
    FLAVOR = ""
    TARGET_DART = "lib/main.dart"
    NEED_CLEAN = "false"
    NEED_BUILD_RUNNER = "false"
}

# --- 3. Parse buildenv.base (The Dynamic Step) ---
if (Test-Path $BaseFile) {
    Get-Content $BaseFile | ForEach-Object {
        if ($_ -match "^\s*$" -or $_ -match "^\s*#") { return }
        
        # Matches: KEY=VALUE
        if ($_ -match "^\s*([A-Z_]+)\s*=\s*(.*)") {
            $key = $matches[1]
            $val = $matches[2].Trim()
            
            # Remove inline comments
            if ($val -match "^(.*?)\s*#") { $val = $matches[1].Trim() }
            
            # Update config
            $Config[$key] = $val
        }
    }
}

# --- 4. Auto-Detection (Source of Truth) ---

# A. App Name & Version (Parsed robustly line-by-line)
if (Test-Path $Pubspec) {
    Get-Content $Pubspec | ForEach-Object {
        $line = $_.Trim()
        
        # Name
        if ($line -match '^name:\s*([a-zA-Z0-9_]+)') {
            $Config["APPNAME"] = $matches[1]
            Write-Host "Detected APPNAME: $($Config["APPNAME"])"
        }
        
        # Version (Supports standard x.y.z and x.y.z+n)
        if ($line -match '^version:\s*(\d+\.\d+\.\d+)(\+(\d+))?') {
            $Config["BUILD_NAME"] = $matches[1]
            
            if ($matches[3]) {
                $Config["BUILD_NUMBER"] = $matches[3]
            } else {
                # If pubspec has no build number (e.g. 1.0.0), default to 1 
                # ensuring we don't keep a stale value from buildenv.base
                $Config["BUILD_NUMBER"] = "1" 
            }
            Write-Host "Detected version: $($Config["BUILD_NAME"])+$($Config["BUILD_NUMBER"])"
        }
    }
}

# B. Main Entry
$mainFullPath = Join-Path $ProjectRoot $Config["TARGET_DART"]
if (-not (Test-Path $mainFullPath)) {
    $found = Get-ChildItem $ProjectRoot -Recurse -Filter "main.dart" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $Config["TARGET_DART"] = $found.FullName.Substring($ProjectRoot.Path.Length + 1).Replace("\", "/")
    }
}

# C. FVM
if (Test-Path $FvmRc) {
    Write-Host "Found .fvmrc -> enabling FVM"
    $Config["USE_FVM"] = "true"
    $content = Get-Content $FvmRc -Raw
    $fVer = ""
    try {
        $json = $content | ConvertFrom-Json
        if ($json.flutter) { $fVer = $json.flutter }
    } catch {
        if ($content -match '"flutter"\s*:\s*"([^"]+)"') { $fVer = $matches[1].Trim() }
        elseif ($content -match "'flutter'\s*:\s*'([^']+)'") { $fVer = $matches[1].Trim() }
    }
    if ($fVer) { 
        $Config["FLUTTER_VERSION"] = $fVer
        Write-Host "Flutter version: $fVer"
    }
}

# D. Shorebird
if (Test-Path $ShorebirdConfig) { 
    $Config["USE_SHOREBIRD"] = "true" 
}

# E. Env Path Fallback
if ($Config["ENV_PATH"] -eq "" -and (Test-Path $RootEnvFile)) {
    $Config["ENV_PATH"] = "./.env"
}

# --- 5. Generate CLEAN File ---
$cleanContent = ""
foreach ($key in $Config.Keys) {
    # Ensure strictly Key=Value format
    $cleanContent += "$key=$($Config[$key])`n"
}

$cleanContent | Set-Content $BuildEnvFile -Encoding UTF8

# --- 6. Log Result ---
Write-Host "`nBUILDENV GENERATED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "Location: $BuildEnvFile`n"
Write-Host "Summary:"
Write-Host "   App Name     : $($Config["APPNAME"])"
Write-Host "   Version      : $($Config["BUILD_NAME"])+$($Config["BUILD_NUMBER"])"
Write-Host "   FVM          : $($Config["USE_FVM"]) $(if($Config["FLUTTER_VERSION"]){ "($($Config["FLUTTER_VERSION"]))" })"
Write-Host "   Shorebird    : $($Config["USE_SHOREBIRD"])"
Write-Host "   Auto Confirm : $($Config["SHOREBIRD_AUTO_CONFIRM"])"
Write-Host "   Output Path  : $($Config["OUTPUT_PATH"])"
Write-Host "   Main Entry   : $($Config["TARGET_DART"])"