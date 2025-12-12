# AabToApk.ps1 - FINAL VERSION (Fixed + Choose Output Folder)
# Perfect for Flutter developers - just run and get your APK anywhere you want!

Clear-Host
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "   AAB → Universal APK Converter (Flutter Ready)    " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# --- Helper: Resolve relative storeFile path ---
function Resolve-StoreFilePath {
    param([string]$StoreFile, [string]$PropertiesPath)
    if ([System.IO.Path]::IsPathRooted($StoreFile)) {
        return $StoreFile
    } else {
        $propsDir = Split-Path $PropertiesPath -Parent
        return Join-Path $propsDir $StoreFile
    }
}

# === 1. Auto-detect bundletool ===
$defaultBundletoolPaths = @(
    "$env:USERPROFILE\tools\bundletool-all-*.jar"
    "$env:USERPROFILE\Downloads\bundletool-all-*.jar"
    "D:\Dev\tools\bundletool\bundletool-all-*.jar"
    "C:\tools\bundletool-all-*.jar"
    "D:\tools\bundletool-all-*.jar"
)

$bundletool = $null
foreach ($pattern in $defaultBundletoolPaths) {
    $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($found) {
        $bundletool = $found.FullName
        Write-Host "Found bundletool: $bundletool" -ForegroundColor Green
        break
    }
}

while (-not $bundletool -or -not (Test-Path $bundletool)) {
    $input = Read-Host "Enter path to bundletool-all-*.jar (or drag & drop)"
    $input = $input.Trim('"').Trim("'")
    if (Test-Path $input) { $bundletool = $input } else { Write-Host "Not found!" -ForegroundColor Red }
}

# === 2. key.properties ===
do {
    $keyPropsPath = Read-Host "Drag & drop key.properties (usually android/key.properties)"
    $keyPropsPath = $keyPropsPath.Trim('"').Trim("'")
    if (-not (Test-Path $keyPropsPath)) { Write-Host "File not found!" -ForegroundColor Red }
} while (-not (Test-Path $keyPropsPath))

# === 3. Parse key.properties ===
Write-Host "`nReading key.properties..." -ForegroundColor Cyan
$content = Get-Content $keyPropsPath
$props = @{}
foreach ($line in $content) {
    if ($line -match "^\s*([^#].*?)=(.*)$") {
        $props[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$storePassword = $props["storePassword"]
$keyPassword    = $props["keyPassword"]
$keyAlias       = $props["keyAlias"]
$storeFileRaw   = $props["storeFile"]

if (-not $storePassword -or -not $keyPassword -or -not $keyAlias -or -not $storeFileRaw) {
    Write-Host "Missing required fields in key.properties!" -ForegroundColor Red
    Pause; exit 1
}

# === 4. Smart keystore detection ===
$possibleDirs = @(
    Split-Path $keyPropsPath -Parent
    (Join-Path (Split-Path $keyPropsPath -Parent) "android")
    (Join-Path (Split-Path $keyPropsPath -Parent) "android\app")
)

$keystorePath = $null
$rawPath = Resolve-StoreFilePath $storeFileRaw $keyPropsPath
if (Test-Path $rawPath) { $keystorePath = $rawPath }

if (-not $keystorePath) {
    Write-Host "Searching common Flutter keystore locations..." -ForegroundColor Yellow
    foreach ($dir in $possibleDirs) {
        if (-not (Test-Path $dir)) { continue }
        $exact = Join-Path $dir ([IO.Path]::GetFileName($storeFileRaw))
        if (Test-Path $exact) { $keystorePath = $exact; break }
        $anyJks = Get-ChildItem -Path $dir -Filter *.jks -File | Select-Object -First 1
        if ($anyJks) { $keystorePath = $anyJks.FullName; break }
    }
}

while (-not $keystorePath -or -not (Test-Path $keystorePath)) {
    Write-Host "Keystore not found automatically." -ForegroundColor Red
    $input = Read-Host "Drag & drop your .jks file here"
    $input = $input.Trim('"').Trim("'")
    if (Test-Path $input) { $keystorePath = $input } else { Write-Host "Not found!" -ForegroundColor Red }
}
Write-Host "Keystore: $keystorePath" -ForegroundColor Green

# === 5. Choose .aab file ===
do {
    $aabPath = Read-Host "`nDrag & drop your .aab file here"
    $aabPath = $aabPath.Trim('"').Trim("'")
    if (-not (Test-Path $aabPath) -or -not $aabPath.EndsWith(".aab", 1)) {
        Write-Host "Invalid .aab file!" -ForegroundColor Red
    }
} while (-not (Test-Path $aabPath))

$aabName = [IO.Path]::GetFileNameWithoutExtension($aabPath)

# === 6. LET USER CHOOSE OUTPUT FOLDER ===
Add-Type -AssemblyName System.Windows.Forms
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = "Select folder to save the final APK"
$folderDialog.SelectedPath = Split-Path $aabPath -Parent

if ($folderDialog.ShowDialog() -eq "OK") {
    $outputDir = $folderDialog.SelectedPath
} else {
    Write-Host "Cancelled." -ForegroundColor Red
    Pause; exit 1
}

$finalApk = Join-Path $outputDir "$aabName-universal.apk"
$apksTemp = Join-Path $env:TEMP "temp_bundle.apks"
$extractTemp = Join-Path $env:TEMP "aab_extract_temp"

Write-Host "`nFinal APK will be saved to:" -ForegroundColor Cyan
Write-Host "   $finalApk" -ForegroundColor Yellow

# === 7. Run bundletool ===
Write-Host "`nGenerating signed universal APK..." -ForegroundColor Cyan
java -jar "$bundletool" build-apks `
    --bundle="$aabPath" `
    --output="$apksTemp" `
    --mode=universal `
    --ks="$keystorePath" `
    --ks-key-alias="$keyAlias" `
    --ks-pass="pass:$storePassword" `
    --key-pass="pass:$keyPassword" `
    --overwrite | Out-Host

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nBundletool failed!" -ForegroundColor Red
    Pause; exit 1
}

# === 8. Extract APK ===
if (Test-Path $extractTemp) { Remove-Item $extractTemp -Recurse -Force }
New-Item -ItemType Directory -Path $extractTemp -Force | Out-Null

Expand-Archive -Path $apksTemp -DestinationPath $extractTemp -Force
Move-Item -Path "$extractTemp\universal.apk" -Destination $finalApk -Force

# Cleanup
Remove-Item $apksTemp -Force
Remove-Item $extractTemp -Recurse -Force

# === DONE ===
Write-Host "`nSUCCESS! Your universal APK is ready!" -ForegroundColor Green
Write-Host "Saved to: $finalApk" -ForegroundColor Yellow

# Open folder
explorer.exe /select,"$finalApk"

Pause