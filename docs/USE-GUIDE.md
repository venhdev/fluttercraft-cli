# Mobile Build CLI - Quick Start Guide

## 📥 Clone & Build

```powershell
# 1. Clone the repository
git clone https://github.com/venhdev/mobile-build-cli.git
cd mobile-build-cli

# 2. Install dependencies
fvm dart pub get

# 3. Build executable
mkdir dist
fvm dart compile exe bin/mobile_build_cli.dart -o dist/mycli.exe
```

---

## 🔧 Activate (Choose One)

### Option A: Use Compiled Binary Directly
```powershell
# Copy mycli.exe to your project or add dist/ to PATH
.\dist\mycli.exe --help
```

### Option B: Global Activation
```powershell
# Activate globally (use from anywhere)
fvm dart pub global activate --source path .

# Now use:
mycli --help
```

### Option C: Run from Source
```powershell
# No build needed
fvm dart run bin/mobile_build_cli.dart --help
```

---

## 🚀 Usage

### First Time Setup (in your Flutter project)
```powershell
cd your-flutter-project

# Generate build configuration
mycli gen-env
```

### Build Your App
```powershell
# Interactive build (with version prompts)
mycli build

# Quick build (skip prompts)
mycli build --type apk --no-confirm

# Build AAB for Play Store
mycli build --type aab

# Build with specific version
mycli build --version 1.2.0 --build-number 42
```

### Clean Project
```powershell
mycli clean
```

### Convert AAB to APK
```powershell
mycli convert
```

---

## 📋 Commands Summary

| Command | Description |
|---------|-------------|
| `mycli gen-env` | Generate `.buildenv` from project detection |
| `mycli build` | Build APK/AAB/IPA with version management |
| `mycli build --type apk` | Build APK directly |
| `mycli build --clean` | Clean before building |
| `mycli clean` | Run flutter clean + remove dist |
| `mycli convert` | Convert AAB → universal APK |

---

## 📂 Output

Build artifacts are saved to `dist/`:
```
dist/
├── myapp_1.2.3+45.apk
├── myapp_1.2.3+45.aab
└── logs/
    ├── build-latest.log
    └── build-1.2.3+45-2025-12-12_15-30-22.log
```

---

## ⚡ Quick Reference

```powershell
# Build APK quickly
mycli build -t apk --no-confirm

# Build AAB with clean
mycli build -t aab -c

# Set version explicitly
mycli build -v 2.0.0 --build-number 100
```
