# fluttercraft CLI (fluttercraft)

A cross-platform Dart CLI tool for building Flutter apps. Replaces PowerShell build scripts with a single portable executable.

## Features

- 🖥️ **Interactive Shell** - Continuous REPL experience
- 🔧 **Build** - Build APK/AAB/IPA with version management
- 🧹 **Clean** - Clean project and dist folder
- 📦 **Convert** - Convert AAB to universal APK using bundletool
- ⚙️ **Gen** - Generate fluttercraft.yaml configuration file
- 🎯 **FVM Support** - Automatic FVM detection from `.fvmrc`
- 🐦 **Shorebird Support** - Integrated Shorebird release builds
- 🚀 **Smart Defaults** - Works without config, reads from pubspec.yaml
- 🔧 **Custom Aliases** - Define reusable command sequences

## Quick Start

```powershell
# Generate config (optional but recommended)
fluttercraft gen

# Build interactively
fluttercraft build

# Or build directly
fluttercraft build --type apk --no-confirm
```

## Installation

**Option 1: Compiled Binary**
```powershell
.\bin\fluttercraft.exe --help
```

**Option 2: Global Activation**
```powershell
fvm dart pub global activate --source path .
fluttercraft --help
```

**Option 3: Run Directly**
```powershell
fvm dart run bin/fluttercraft.dart --help
```

## Commands

| Command | Description | Example |
|---------|-------------|---------|
| `build` | Build Flutter app (APK/AAB/IPA) | `flc build --type apk` |
| `clean` | Clean project and dist folder | `flc clean --dist-only` |
| `convert` | Convert AAB to universal APK | `flc convert --aab app.aab` |
| `gen` | Generate fluttercraft.yaml | `flc gen --force` |
| `run` | Run custom command alias | `flc run gen-icon` |

**Interactive Mode:**
```powershell
flc                    # Start interactive shell
flc build              # Interactive build with prompts
```

**Direct Mode:**
```powershell
flc build --type apk --no-confirm
flc run --list
```

## Configuration

### First Run (No Config Required)

The CLI works without `fluttercraft.yaml`:
- Reads app name/version from `pubspec.yaml`
- Uses sensible defaults
- Run `fluttercraft gen` to create config file

### `fluttercraft.yaml`

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
  app_id: null   # Auto-detected from shorebird.yaml
  artifact: null
  auto_confirm: true

alias:
  gen-icon:
    cmds:
      - fvm flutter pub get
      - fvm flutter pub run flutter_launcher_icons
  brn:
    cmds:
      - fvm flutter pub get
      - fvm flutter packages pub run build_runner build --delete-conflicting-outputs
```

## Custom Command Aliases

Define reusable command sequences in `fluttercraft.yaml`:

```yaml
alias:
  gen-icon:
    cmds:
      - fvm flutter pub get
      - fvm flutter pub run flutter_launcher_icons
  brn:
    cmds:
      - fvm flutter pub get
      - fvm flutter packages pub run build_runner build --delete-conflicting-outputs
```

Then run them with:
```powershell
flc run gen-icon
flc run brn
flc run --list  # Show all available aliases
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
- `.fluttercraft/build_latest.log`
- `.fluttercraft/logs/{build-id}.log`
- `.fluttercraft/build_history.jsonl`

## Development

```powershell
fvm dart pub get                       # Install dependencies
fvm dart test                          # Run tests
fvm dart analyze                       # Analyze code
.\scripts\compile.ps1                  # Compile to binary
```

## License

MIT

