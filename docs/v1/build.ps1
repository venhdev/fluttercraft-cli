#!pwsh
param (
    [switch]$Clean
)

### -----------------------
### 1. INITIAL SETUP
### -----------------------
$ScriptDir    = $PSScriptRoot
$ProjectRoot  = Resolve-Path "$ScriptDir\.."
$BuildEnvFile = "$ScriptDir\.buildenv"

if (-not (Test-Path $BuildEnvFile)) {
    Write-Error "Missing .buildenv - Run gen-buildenv.ps1 first"
    exit 1
}

# --- LOGGING SETUP -------------------------------------------------
$LogRoot = Join-Path $ProjectRoot "dist\logs"
if (-not (Test-Path $LogRoot)) {
    New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
}

$LatestLog   = Join-Path $LogRoot "build-latest.log"
$Timestamp   = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ArchiveLog  = $null

Start-Transcript -Path $LatestLog -Force | Out-Null

Write-Host @"
=====================================================================
      Flutter Build Script – Logging Enabled
      Latest log  : $LatestLog
      Archive log : (will be created after version selection)
=====================================================================
"@ -ForegroundColor Cyan

### Load .buildenv
$BuildEnv = @{}
Get-Content $BuildEnvFile | ForEach-Object {
    if ($_ -match "^\s*$" -or $_ -match "^#") { return }
    $k = ($_ -split "=", 2)[0].Trim()
    $v = ($_ -split "=", 2)[1].Trim()
    $BuildEnv[$k] = $v
}

### -----------------------
### 2. LOAD / INIT VERSION
### -----------------------
$ver = $BuildEnv["BUILD_NAME"]
if (-not $ver) {
    Write-Host "Missing BUILD_NAME."
    $inputVer = Read-Host "Enter BUILD_NAME (default 1.0.0)"
    $ver = if ($inputVer) { $inputVer } else { "1.0.0" }
    $BuildEnv["BUILD_NAME"] = $ver
}

$num = $BuildEnv["BUILD_NUMBER"]
if (-not $num) {
    Write-Host "Missing BUILD_NUMBER."
    $inputNum = Read-Host "Enter BUILD_NUMBER (default 1)"
    $num = if ($inputNum) { $inputNum } else { "1" }
    $BuildEnv["BUILD_NUMBER"] = $num
}

### -----------------------
### 3. VERSION INCREMENT
### -----------------------
$parts = $ver.Split(".")
$major = [int]$parts[0]
$minor = [int]$parts[1]
$patch = [int]$parts[2]

Write-Host "`nSelect version increment:" -ForegroundColor Cyan
Write-Host "0. No change (keep $ver)"
Write-Host "1. Patch (+0.0.1)"
Write-Host "2. Minor (+0.1.0)"
Write-Host "3. Major (+1.0.0)"
$choice = Read-Host "Choose (0-3)"

switch ($choice) {
    "3" { $major++; $minor=0; $patch=0 }
    "2" { $minor++; $patch=0 }
    "1" { $patch++ }
    "0" { }
    default { Write-Host "Keeping current version: $ver" }
}

$NewVer = "$major.$minor.$patch"

Write-Host "`nCurrent BUILD_NUMBER: $num" -ForegroundColor Yellow
Write-Host "BUILD_NUMBER options:" -ForegroundColor Cyan
Write-Host "0. Keep current ($num)"
Write-Host "1. Auto-increment (+1) → $([int]$num + 1)"
Write-Host "2. Set custom number"
$buildNumChoice = Read-Host "Choose (0-2)"

switch ($buildNumChoice) {
    "0" { $NewNum = $num }
    "1" { $NewNum = ([int]$num) + 1 }
    "2" {
        do {
            $custom = Read-Host "Enter new BUILD_NUMBER (positive integer)"
            if ($custom -match '^\d+$' -and [int]$custom -ge 0) {
                $NewNum = $custom
                break
            } else { Write-Host "Invalid input." -ForegroundColor Red }
        } while ($true)
    }
    default { $NewNum = $num }
}

$FullVersion = "$NewVer+$NewNum"
$ArchiveLog  = Join-Path $LogRoot "build-${FullVersion}_$Timestamp.log"

Write-Host "`n=== ARCHIVE LOG WILL BE ===" -ForegroundColor Green
Write-Host $ArchiveLog
Write-Host "================================`n"

# Update .buildenv
$BuildEnv["BUILD_NAME"]   = $NewVer
$BuildEnv["BUILD_NUMBER"] = $NewNum.ToString()
$BuildEnv.GetEnumerator() | Sort-Object Name | ForEach-Object {
    "$($_.Key)=$($_.Value)"
} | Set-Content $BuildEnvFile

$BaseAppName = $BuildEnv["APPNAME"]
if (-not $BaseAppName) { $BaseAppName = "app" }
$FullAppName = "$BaseAppName`_$NewVer+$NewNum"

Write-Host "`nNew version: $NewVer+$NewNum" -ForegroundColor Green
Write-Host "Output filename will be: $FullAppName.*`n"

### -----------------------
### 4. BUILD MODE
### -----------------------
$UseShorebird = $BuildEnv["USE_SHOREBIRD"] -eq "true"
$UseFvm       = $BuildEnv["USE_FVM"] -eq "true"
$FlutterVer   = $BuildEnv["FLUTTER_VERSION"]

$Mode = if ($UseShorebird) { "shorebird" }
        elseif ($UseFvm)   { $FlutterVer ? "fvm-$FlutterVer" : "fvm" }
        else               { "flutter" }

# Enhance: Add .sb.base suffix for Shorebird builds
if ($UseShorebird) {
    $FullAppName += ".sb.base"
}

### -----------------------
### 5. DART DEFINES
### -----------------------
$inlineDefs = @()
if ($BuildEnv["USE_DART_DEFINE"] -eq "true") {
    while ($true) {
        Write-Host "`nAdd dart-define?"
        Write-Host "1. Add new"
        Write-Host "0. Continue"
        $opt = Read-Host "Choose"
        if ($opt -eq "0") { break }
        if ($opt -eq "1") {
            $k = Read-Host "Key"
            $v = Read-Host "Value"
            $inlineDefs += "$k=$v"
        }
    }
}

$EnvFile = $BuildEnv["ENV_PATH"]
if ($EnvFile -and -not (Test-Path "$ProjectRoot\$($EnvFile -replace '^\./','')")) {
    $EnvFile = $null
}

### -----------------------
### 6. BUILD TYPE & PLATFORM
### -----------------------
$buildType = $BuildEnv["BUILD_TYPE"]?.ToLower().Trim()
if (-not $buildType) {
    Write-Host "`nEnter BUILD_TYPE (aab | apk | ipa | app):"
    $buildType = Read-Host "BUILD_TYPE"
    $BuildEnv["BUILD_TYPE"] = $buildType
    $BuildEnv.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" } | Set-Content $BuildEnvFile
}

$validTypes = @("aab", "apk", "ipa", "app")
if ($validTypes -notcontains $buildType) {
    Write-Error "Invalid BUILD_TYPE: '$buildType'. Must be one of: aab, apk, ipa, app"
    Stop-Transcript
    exit 1
}

$platform = if ($buildType -eq "app") { "macos" } else { $buildType }

$Flavor          = $BuildEnv["FLAVOR"]
$Target          = $BuildEnv["TARGET_DART"]
$NeedClean       = $BuildEnv["NEED_CLEAN"] -eq "true"
$NeedBuildRunner = $BuildEnv["NEED_BUILD_RUNNER"] -eq "true"

### -----------------------
### 7. OUTPUT PATH
### -----------------------
$OutputPath = $BuildEnv["OUTPUT_PATH"]?.TrimStart("/", "\")
if (-not $OutputPath) { $OutputPath = "dist" }

$DistDir = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
} else {
    Join-Path $ProjectRoot $OutputPath
}

### -----------------------
### 8. BUILD ARGS
### -----------------------
$flutterArgs = @("--release")
if ($Flavor) { $flutterArgs += "--flavor=$Flavor" }
if ($Target) { $flutterArgs += "--target=$Target" }
if ($NewVer) { $flutterArgs += "--build-name=$NewVer" }
if ($NewNum) { $flutterArgs += "--build-number=$NewNum" }
foreach ($d in $inlineDefs) { $flutterArgs += "--dart-define=$d" }
if ($EnvFile) { $flutterArgs += "--dart-define-from-file=$EnvFile" }

$sbArgs = $null
$fullCmd = ""

if ($Mode -eq "shorebird") {
    $sbArgs = @("release", "android")

    # Smart artifact: apk when requested
    if ($buildType -eq "apk") {
        $sbArgs += "--artifact"; $sbArgs += "apk"
        Write-Host "Shorebird → building APK (BUILD_TYPE=apk)" -ForegroundColor Magenta
    } elseif ($buildType -eq "aab") {
        Write-Host "Shorebird → building AAB (default)" -ForegroundColor Magenta
    }

    if ($BuildEnv["SHOREBIRD_AUTO_CONFIRM"] -eq "true") { $sbArgs += "--no-confirm" }
    if ($FlutterVer) { $sbArgs += "--flutter-version=$FlutterVer" }

    # Manual override wins
    if ($BuildEnv["SHOREBIRD_ARTIFACT"]) {
        $sbArgs = $sbArgs | Where-Object { $_ -notin @("--artifact", "apk", "aab") }
        $sbArgs += "--artifact"; $sbArgs += $BuildEnv["SHOREBIRD_ARTIFACT"]
        Write-Host "Shorebird → using manual SHOREBIRD_ARTIFACT=$($BuildEnv["SHOREBIRD_ARTIFACT"])" -ForegroundColor Yellow
    }

    $fullCmd = "shorebird $(($sbArgs -join ' ')) -- $(($flutterArgs -join ' '))"
}
elseif ($Mode -like "fvm*") {
    $flutterCmd = if ($FlutterVer) { "fvm use $FlutterVer; fvm flutter" } else { "fvm flutter" }
    $args = "build $platform $(($flutterArgs -join ' '))"
    $fullCmd = "$flutterCmd $args"
}
else {
    $args = "build $platform $(($flutterArgs -join ' '))"
    $fullCmd = "flutter $args"
}

### -----------------------
### 9. FINAL CONFIGURATION + CONFIRMATION
### -----------------------
Write-Host "`n=== Final Build Configuration ===" -ForegroundColor Cyan
Write-Host "Mode          : $Mode"
Write-Host "Platform      : $platform  (BUILD_TYPE=$buildType)"
Write-Host "Version       : $NewVer+$NewNum"
Write-Host "App name      : $FullAppName"
Write-Host "Output dir    : $DistDir"
Write-Host "Command       : $fullCmd"
Write-Host "====================================`n"

$confirm = Read-Host "Proceed with build? (Y/n)"
if ($confirm -inotmatch "^[Yy]?$") {
    Write-Host "Build cancelled by user." -ForegroundColor Yellow
    Stop-Transcript
    exit 0
}

### -----------------------
### 10. ACTUAL BUILD PROCESS
### -----------------------
Push-Location $ProjectRoot
$Start = Get-Date

function Exec([string]$Cmd) {
    Write-Host "EXEC: $Cmd" -ForegroundColor DarkGray
    Invoke-Expression $Cmd
    if ($LASTEXITCODE -ne 0) { throw "FAILED: $Cmd" }
}

try {
    if ($Clean -or $NeedClean) {
        Write-Host "`nCleaning project..." -ForegroundColor Yellow
        if ($Mode -eq "shorebird") { Exec "flutter clean" }
        elseif ($Mode -like "fvm*") { Exec "fvm flutter clean" }
        else { Exec "flutter clean" }
    }

    if ($NeedBuildRunner) {
        Write-Host "`nRunning build_runner..." -ForegroundColor Yellow
        if ($Mode -like "fvm*") { Exec "fvm dart run build_runner build --delete-conflicting-outputs" }
        else { Exec "dart run build_runner build --delete-conflicting-outputs" }
    }

    Write-Host "`nStarting build... ($NewVer+$NewNum)" -ForegroundColor Yellow

    if ($Mode -eq "shorebird") {
        $shorebirdCmd = "shorebird $(($sbArgs -join ' ')) -- $(($flutterArgs -join ' '))"
        Exec $shorebirdCmd
    }
    elseif ($Mode -like "fvm*") {
        $flutterCmd = if ($FlutterVer) { "fvm use $FlutterVer; fvm flutter" } else { "fvm flutter" }
        $args = "build $platform $(($flutterArgs -join ' '))"
        Exec "$flutterCmd $args"
    }
    else {
        $args = "build $platform $(($flutterArgs -join ' '))"
        Exec "flutter $args"
    }

    # --- COPY OUTPUT ---
    Write-Host "`nCopying output to $DistDir..." -ForegroundColor Cyan
    if (-not (Test-Path $DistDir)) { New-Item -Path $DistDir -ItemType Directory | Out-Null }

    $copied = $false

    if ($platform -eq "apk") {
        $srcPath = "build/app/outputs/flutter-apk"
        $patterns = @("app-release.apk", "$Flavor-release.apk", "app-$Flavor-release.apk")
        foreach ($p in $patterns) {
            $src = Join-Path $srcPath $p
            if (Test-Path $src) {
                Copy-Item $src "$DistDir\$FullAppName.apk" -Force
                Write-Host "Copied APK → $FullAppName.apk"
                $copied = $true; break
            }
        }

        # Enhance: For Shorebird + APK, also copy AAB if exists
        if ($Mode -eq "shorebird") {
            $srcPathAab = "build/app/outputs/bundle"
            $patternsAab = @("release/app-release.aab", "${Flavor}Release/app-$Flavor-release.aab")
            foreach ($p in $patternsAab) {
                $srcAab = Join-Path $srcPathAab $p
                if (Test-Path $srcAab) {
                    Copy-Item $srcAab "$DistDir\$FullAppName.aab" -Force
                    Write-Host "Copied AAB (Shorebird extra) → $FullAppName.aab"
                    $copied = $true; break
                }
            }
        }
    }
    elseif ($platform -eq "aab") {
        $srcPath = "build/app/outputs/bundle"
        $patterns = @("release/app-release.aab", "${Flavor}Release/app-$Flavor-release.aab")
        foreach ($p in $patterns) {
            $src = Join-Path $srcPath $p
            if (Test-Path $src) {
                Copy-Item $src "$DistDir\$FullAppName.aab" -Force
                Write-Host "Copied AAB → $FullAppName.aab"
                $copied = $true; break
            }
        }
    }
    elseif ($platform -eq "ipa") {
        $ipa = Get-ChildItem "build/ios/ipa/*.ipa" | Select-Object -First 1
        if ($ipa) {
            Copy-Item $ipa.FullName "$DistDir\$FullAppName.ipa" -Force
            Write-Host "Copied IPA → $FullAppName.ipa"
            $copied = $true
        }
    }
    elseif ($platform -eq "macos") {
        $src = "build/macos/Build/Products/Release/$BaseAppName.app"
        if (Test-Path $src) {
            Copy-Item $src "$DistDir\$FullAppName.app" -Recurse -Force
            Write-Host "Copied macOS app → $FullAppName.app"
            $copied = $true
        }
    }

    if (-not $copied) { Write-Warning "Output file not found – check build logs." }

    Write-Host "`nBuild completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "`nBUILD FAILED!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
finally {
    Pop-Location
    $End = Get-Date
    $Duration = ($End - $Start).TotalSeconds

    if (Test-Path $LatestLog) {
        Copy-Item $LatestLog $ArchiveLog -Force
        Write-Host "`nArchive log: $ArchiveLog" -ForegroundColor Green
    }

    Write-Host "`n===========================" -ForegroundColor Cyan
    Write-Host "Duration      : $([math]::Round($Duration, 2)) seconds"
    Write-Host "Version       : $NewVer+$NewNum"
    Write-Host "Output        : $FullAppName.*"
    Write-Host "Directory     : $DistDir"
    Write-Host "Latest log    : $LatestLog"
    Write-Host "Archive log   : $ArchiveLog"
    Write-Host "===========================" -ForegroundColor Cyan

    Stop-Transcript | Out-Null
}