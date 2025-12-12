# Mobile Build CLI - Implementation Plan (Dart-First)

A cross-platform Dart CLI to replace all PowerShell build scripts with a single portable executable.

---

## 📋 Overview

```
mycli build          # Build APK/AAB/IPA with version management
mycli clean          # Clean project and dist folder
mycli gen-env        # Generate .buildenv from project detection
mycli convert        # Convert AAB → Universal APK
mycli release        # Shorebird release (future)
mycli patch          # Shorebird patch (future)
```

---

## 🛠️ Phase 1: Project Setup

### Step 1.1: Create Dart Console Project

```powershell
# Navigate to project root
cd c:\src\self\flutter-dart\cli\mobile-build-cli

# Create Dart console project (using FVM's Dart 3.9.2)
fvm dart create -t console .
```

> [!NOTE]
> If directory not empty, use: `fvm dart create -t console --force .`

### Step 1.2: Configure pubspec.yaml

```yaml
name: mycli
description: Flutter build CLI - cross-platform build system
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  args: ^2.6.0              # Command-line argument parsing
  yaml: ^3.1.3              # YAML parsing for pubspec
  path: ^1.9.1              # Cross-platform path utilities
  interact: ^2.2.0          # Interactive prompts
  ansicolor: ^2.0.3         # Terminal colors

dev_dependencies:
  lints: ^5.1.0
  test: ^1.25.0
```

```powershell
# Install dependencies
fvm dart pub get
```

### Step 1.3: Project Structure

```
mobile-build-cli/
├── bin/
│   └── mycli.dart              # Entry point + command router
├── lib/
│   ├── src/
│   │   ├── commands/           # CLI commands
│   │   │   ├── build_command.dart
│   │   │   ├── clean_command.dart
│   │   │   ├── gen_env_command.dart
│   │   │   └── convert_command.dart
│   │   ├── core/               # Business logic
│   │   │   ├── build_env.dart
│   │   │   ├── pubspec_parser.dart
│   │   │   ├── version_manager.dart
│   │   │   ├── flutter_runner.dart
│   │   │   ├── artifact_mover.dart
│   │   │   └── apk_converter.dart
│   │   └── utils/              # Utilities
│   │       ├── console.dart
│   │       ├── logger.dart
│   │       └── process_runner.dart
│   └── mycli.dart              # Library exports
├── test/
├── pubspec.yaml
└── README.md
```

---

## 🛠️ Phase 2: Core Utilities

### Step 2.1: Process Runner (`lib/src/utils/process_runner.dart`)
- [ ] Run external commands with `Process.run()`
- [ ] Capture stdout/stderr
- [ ] Handle exit codes
- [ ] Stream output in real-time

### Step 2.2: Console Utilities (`lib/src/utils/console.dart`)
- [ ] Colored text output (success, error, warning, info)
- [ ] Box drawing for configuration display
- [ ] Spinner for long operations

### Step 2.3: Logger (`lib/src/utils/logger.dart`)
- [ ] Log to `dist/logs/build-latest.log`
- [ ] Archive logs with timestamp

---

## 🛠️ Phase 3: Core Logic

### Step 3.1: Build Environment (`lib/src/core/build_env.dart`)
- [ ] Load `.buildenv` file (KEY=VALUE format)
- [ ] Load `buildenv.base` for defaults
- [ ] Merge configurations
- [ ] Save updated `.buildenv`

### Step 3.2: Pubspec Parser (`lib/src/core/pubspec_parser.dart`)
- [ ] Extract `name` from pubspec.yaml
- [ ] Extract `version` (e.g., `1.2.3+45`)
- [ ] Parse into build name and build number

### Step 3.3: Version Manager (`lib/src/core/version_manager.dart`)
- [ ] Parse semantic version (major.minor.patch)
- [ ] Increment version (major/minor/patch)
- [ ] Manage build number (auto-increment/custom)
- [ ] Format full version string

### Step 3.4: Flutter Runner (`lib/src/core/flutter_runner.dart`)
- [ ] Execute `flutter build apk/aab/ipa`
- [ ] Execute `flutter clean`
- [ ] Handle FVM prefix (`fvm flutter ...`)
- [ ] Handle Shorebird (`shorebird release ...`)
- [ ] Pass dart-defines

### Step 3.5: Artifact Mover (`lib/src/core/artifact_mover.dart`)
- [ ] Locate build output (APK/AAB/IPA paths)
- [ ] Copy to `dist/` folder with proper naming
- [ ] Handle flavor-specific paths

### Step 3.6: APK Converter (`lib/src/core/apk_converter.dart`)
- [ ] Find AAB files in OUTPUT_PATH
- [ ] Locate bundletool
- [ ] Read keystore info from key.properties
- [ ] Run bundletool to create universal APK

---

## 🛠️ Phase 4: Commands

### Step 4.1: Entry Point (`bin/mycli.dart`)
```dart
void main(List<String> args) {
  final runner = CommandRunner('mycli', 'Flutter Build CLI')
    ..addCommand(BuildCommand())
    ..addCommand(CleanCommand())
    ..addCommand(GenEnvCommand())
    ..addCommand(ConvertCommand());
  
  runner.run(args);
}
```

### Step 4.2: Build Command (`mycli build`)
- [ ] Load .buildenv configuration
- [ ] Prompt for version bump (major/minor/patch/none)
- [ ] Prompt for build number handling
- [ ] Display final configuration for confirmation
- [ ] Execute flutter/shorebird/fvm build
- [ ] Copy artifacts to output directory
- [ ] Show build summary

**Options:**
```
mycli build
    --type, -t        Build type: apk, aab, ipa (default: from .buildenv)
    --clean, -c       Run flutter clean first
    --no-confirm      Skip confirmation prompts
    --version         Set version directly (e.g., 1.2.3)
    --build-number    Set build number directly
```

### Step 4.3: Clean Command (`mycli clean`)
- [ ] Run `flutter clean` (with FVM if configured)
- [ ] Delete `dist/` folder
- [ ] Show cleanup summary

### Step 4.4: Gen-Env Command (`mycli gen-env`)
- [ ] Read `pubspec.yaml` for name/version
- [ ] Detect FVM configuration (`.fvmrc`)
- [ ] Detect Shorebird configuration (`shorebird.yaml`)
- [ ] Read `buildenv.base` for defaults
- [ ] Generate `.buildenv` file
- [ ] Display summary

### Step 4.5: Convert Command (`mycli convert`)
- [ ] Find AAB files in dist folder
- [ ] Auto-detect or prompt for bundletool path
- [ ] Auto-detect keystore from key.properties
- [ ] Run bundletool to create universal APK
- [ ] Save to output folder

---

## 🛠️ Phase 5: Testing & Distribution

### Step 5.1: Test Locally

```powershell
# Run directly
fvm dart run bin/mycli.dart --help
fvm dart run bin/mycli.dart build --help
fvm dart run bin/mycli.dart gen-env

# Or activate globally for testing
fvm dart pub global activate --source path .
mycli --help
```

### Step 5.2: Compile to Native Binary

```powershell
# Windows
fvm dart compile exe bin/mycli.dart -o dist/mycli.exe

# macOS / Linux (run on those platforms)
fvm dart compile exe bin/mycli.dart -o mycli
```

### Step 5.3: Distribution Options

**Option A: Global Dart Tool**
```powershell
fvm dart pub global activate --source path .
```

**Option B: Compiled Binary**
- Commit `mycli.exe` to repo
- Team downloads and uses directly

**Option C: GitHub Releases**
- Upload compiled binaries for each platform

---

## 📊 Feature Mapping

| PowerShell Script | Dart Command | Core Module |
|-------------------|--------------|-------------|
| `gen-buildenv.ps1` | `mycli gen-env` | `build_env.dart`, `pubspec_parser.dart` |
| `build.ps1` | `mycli build` | `flutter_runner.dart`, `version_manager.dart`, `artifact_mover.dart` |
| `clean.ps1` | `mycli clean` | `flutter_runner.dart` |
| `apk-converter.ps1` | `mycli convert` | `apk_converter.dart` |

---

## ⏱️ Timeline

| Phase | Description | Effort | Commands |
|-------|-------------|--------|----------|
| Phase 1 | Project Setup | 30 min | `dart create`, `dart pub get` |
| Phase 2 | Core Utilities | 1 day | — |
| Phase 3 | Core Logic | 2-3 days | — |
| Phase 4 | Commands | 2 days | — |
| Phase 5 | Testing & Distribution | 1 day | `dart compile exe` |
| **Total** | | **5-7 days** | |

---

## 🚀 Quick Start Commands

```powershell
# Phase 1: Setup
cd c:\src\self\flutter-dart\cli\mobile-build-cli
fvm dart create -t console --force .
# Edit pubspec.yaml with dependencies
fvm dart pub get

# Phase 5: Test
fvm dart run bin/mycli.dart --help

# Phase 5: Compile
fvm dart compile exe bin/mycli.dart -o mycli.exe
```

---

## ✅ Success Criteria

1. `mycli gen-env` → generates `.buildenv` from project detection
2. `mycli build` → builds app with version prompts, copies to dist
3. `mycli clean` → cleans project and dist folder
4. `mycli convert` → converts AAB to universal APK
5. Works on Windows, macOS, Linux
6. Compiles to standalone executable
