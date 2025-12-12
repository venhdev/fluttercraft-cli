# Mobile Build CLI

A cross-platform Dart CLI tool for building Flutter apps. Replaces PowerShell build scripts with a single portable executable.

## Features

- 🖥️ **Interactive Shell** - Continuous REPL experience
- 🔧 **Build** - Build APK/AAB/IPA with version management
- 🧹 **Clean** - Clean project and dist folder
- ⚙️ **Gen-Env** - Auto-detect project settings and generate `.buildenv`
- 📦 **Convert** - Convert AAB to universal APK using bundletool
- 🎯 **FVM Support** - Automatic FVM detection and usage
- 🐦 **Shorebird Support** - Integrated Shorebird release builds

## Installation

### Option 1: Use Compiled Binary

Download `buildcraft.exe` from the `dist/` folder and add it to your PATH.

```powershell
# Run from project root
.\dist\buildcraft.exe --help
```

### Option 2: Global Activation

```powershell
# Activate globally (requires Dart SDK)
fvm dart pub global activate --source path .

# Then use anywhere
buildcraft --help
```

### Option 3: Run Directly

```powershell
fvm dart run bin/mobile_build_cli.dart --help
```

## Interactive Shell (v0.0.2+)

Start the interactive shell for a continuous REPL experience:

```powershell
# Start interactive shell (default when no args)
buildcraft
```

**Shell Commands:**
- `help` - Show available commands
- `demo` - Test interactive menus
- `context` - Show loaded project context
- `build`, `clean`, `gen-env`, `convert` - Regular commands
- `exit` / `q` - Exit shell

## Commands

### `buildcraft gen-env`

Generate `.buildenv` configuration from project detection.

```powershell
buildcraft gen-env
buildcraft gen-env --force  # Overwrite existing
```

Detects:
- App name and version from `pubspec.yaml`
- FVM configuration from `.fvmrc`
- Shorebird configuration from `shorebird.yaml`
- Main entry point

### `buildcraft build`

Build Flutter app with version management.

```powershell
# Interactive build with prompts
buildcraft build

# Build specific type
buildcraft build --type apk
buildcraft build --type aab
buildcraft build --type ipa

# Skip prompts
buildcraft build --no-confirm

# Set version directly
buildcraft build --version 1.2.3 --build-number 45

# Clean before building
buildcraft build --clean
```

Options:
- `--type, -t` - Build type: apk, aab, ipa, app
- `--clean, -c` - Run flutter clean first
- `--no-confirm` - Skip confirmation prompts
- `--version, -v` - Set version directly
- `--build-number` - Set build number directly

### `buildcraft clean`

Clean project and dist folder.

```powershell
# Full clean (flutter clean + remove dist)
buildcraft clean

# Only remove dist folder
buildcraft clean --dist-only

# Skip confirmation
buildcraft clean -y
```

### `buildcraft convert`

Convert AAB to universal APK using bundletool.

```powershell
# Auto-detect AAB from dist folder
buildcraft convert

# Specify AAB file
buildcraft convert --aab path/to/app.aab

# Custom output directory
buildcraft convert --output ./releases
```

## Configuration

### `.buildenv` File

The build configuration is stored in `scripts/.buildenv`:

```ini
APPNAME=myapp
BUILD_NAME=1.0.0
BUILD_NUMBER=1
BUILD_TYPE=aab

OUTPUT_PATH=dist
ENV_PATH=./.env
TARGET_DART=lib/main.dart
FLAVOR=

USE_FVM=true
FLUTTER_VERSION=3.9.2

USE_SHOREBIRD=false
SHOREBIRD_ARTIFACT=
SHOREBIRD_AUTO_CONFIRM=true

NEED_CLEAN=false
NEED_BUILD_RUNNER=false

BUNDLETOOL_PATH=
KEY_PROPERTIES_PATH=android/key.properties
KEYSTORE_PATH=
```

### `buildenv.base` File

Default values are stored in `scripts/buildenv.base`. These are used as fallbacks when generating `.buildenv`.

## Output

Build artifacts are copied to the `OUTPUT_PATH` (default: `dist/`) with naming:

```
{APPNAME}_{version}+{buildnumber}.{ext}
Example: myapp_1.2.3+45.aab
```

Logs are saved to:
- `dist/logs/build-latest.log` (always overwritten)
- `dist/logs/build-1.2.3+45-2025-12-12_15-30-22.log` (archived)

## Development

```powershell
# Run tests
fvm dart test

# Analyze code
fvm dart analyze

# Compile to native binary
fvm dart compile exe bin/mobile_build_cli.dart -o dist/buildcraft.exe
```

## Project Structure

```
mobile-build-cli/
├── bin/
│   └── mobile_build_cli.dart   # Entry point
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
│   └── mobile_build_cli.dart   # Library exports
├── dist/
│   └── buildcraft.exe               # Compiled binary
├── scripts/
│   ├── .buildenv               # Generated config (gitignored)
│   └── buildenv.base           # Default config
└── pubspec.yaml
```

## License

MIT
