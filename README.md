# FlutterBuild CLI (flb)

A cross-platform Dart CLI tool for building Flutter apps. Replaces PowerShell build scripts with a single portable executable.

## Features

- 🖥️ **Interactive Shell** - Continuous REPL experience
- 🔧 **Build** - Build APK/AAB/IPA with version management
- 🧹 **Clean** - Clean project and dist folder
- 📦 **Convert** - Convert AAB to universal APK using bundletool
- ⚙️ **Gen** - Generate flutterbuild.yaml configuration file
- 🎯 **FVM Support** - Automatic FVM detection from `.fvmrc`
- 🐦 **Shorebird Support** - Integrated Shorebird release builds
- 🚀 **Smart Defaults** - Works without config, reads from pubspec.yaml

## Quick Start

```powershell
# Generate config (optional but recommended)
flb gen

# Build interactively
flb build

# Or build directly
flb build --type apk --no-confirm
```

## Installation

**Option 1: Compiled Binary**
```powershell
.\bin\flutterbuild.exe --help
```

**Option 2: Global Activation**
```powershell
fvm dart pub global activate --source path .
flutterbuild --help
```

**Option 3: Run Directly**
```powershell
fvm dart run bin/flutterbuild.dart --help
```

## Commands

### `flb build`
```powershell
flb build                              # Interactive
flb build --type apk                   # Build APK
flb build --no-confirm                 # Skip prompts
flb build --version 1.2.3 --build-number 45
```

### `flb clean`
```powershell
flb clean                              # Full clean
flb clean --dist-only                  # Only dist folder
```

### `flb convert`
```powershell
flb convert                            # Auto-detect AAB
flb convert --aab path/to/app.aab      # Specify AAB
```

### `flb gen`
```powershell
flb gen                                # Generate config
flb gen --force                        # Overwrite existing
```

## Configuration

### First Run (No Config Required)

The CLI works without `flutterbuild.yaml`:
- Reads app name/version from `pubspec.yaml`
- Uses sensible defaults
- Run `flb gen` to create config file

### `flutterbuild.yaml`

```yaml
app:
  name: testapp

build:
  name: 1.0.1
  number: 10
  type: apk
  flavor: null
  target: lib/main.dart

paths:
  output: dist
  env: ./.env

flags:
  use_dart_define: false
  need_clean: false
  need_build_runner: false

fvm:
  enabled: true
  version: null  # Auto-detected from .fvmrc if null

shorebird:
  enabled: false
  artifact: null
  auto_confirm: true
```

## FVM Integration

**Auto-Detection:** When `fvm.enabled: true` and `version: null`, the CLI reads `.fvmrc`:

```json
{
  "flutter": "3.35.3"
}
```

**Manual Pin:** Override with explicit version:
```yaml
fvm:
  enabled: true
  version: 3.24.0
```

**Disable FVM:**
```yaml
fvm:
  enabled: false
```

## Output

Build artifacts: `dist/{app_name}_{version}+{build_number}.{ext}`

Example: `myapp_1.2.3+45.aab`

Logs:
- `.flutterbuild/build_latest.log`
- `.flutterbuild/logs/{build-id}.log`
- `.flutterbuild/build_history.jsonl`

## Development

```powershell
fvm dart pub get                       # Install dependencies
fvm dart test                          # Run tests
fvm dart analyze                       # Analyze code
.\scripts\compile.ps1                  # Compile to binary
```

## License

MIT
