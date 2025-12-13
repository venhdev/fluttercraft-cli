# Buildcraft CLI

A cross-platform Dart CLI tool for building Flutter apps. Replaces PowerShell build scripts with a single portable executable.

## Features

- 🖥️ **Interactive Shell** - Continuous REPL experience
- 🔧 **Build** - Build APK/AAB/IPA with version management
- 🧹 **Clean** - Clean project and dist folder
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
fvm dart run bin/buildcraft.dart --help
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
- `build`, `clean`, `convert` - Regular commands
- `exit` / `q` - Exit shell

## Commands

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

Options:
- `--dist-only` - Only remove dist folder
- `--yes, -y` - Skip confirmation prompts

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

Options:
- `--aab, -a` - Path to AAB file
- `--output, -o` - Output directory
- `--bundletool` - Path to bundletool.jar
- `--key-properties` - Path to key.properties

## Configuration

### `buildcraft.yaml` File

The build configuration is stored in `buildcraft.yaml` at the project root.
Copy `buildcraft.yaml.example` to get started.

```yaml
# ──────────────────────────────────────────────
# App info (from pubspec or override here)
# ──────────────────────────────────────────────
app:
  name: testapp                # generated filename prefix

# ──────────────────────────────────────────────
# Core build settings
# ──────────────────────────────────────────────
build:
  name: 1.0.1                # version
  number: 10                  # build number
  type: apk                  # default build type
  flavor: null               # flavor name
  target: lib/main.dart      # entry point

# ──────────────────────────────────────────────
# Output & Input paths
# ──────────────────────────────────────────────
paths:
  output: dist               # output directory
  env: ./.env                # env file path

# ──────────────────────────────────────────────
# Build flags
# ──────────────────────────────────────────────
flags:
  use_dart_define: false     # use --dart-define-from-file
  need_clean: false          # run clean before build
  need_build_runner: false   # run build_runner before build

# ──────────────────────────────────────────────
# FVM integration
# ──────────────────────────────────────────────
fvm:
  enabled: true             # use FVM if detected
  version: null              # pin specific version

# ──────────────────────────────────────────────
# Shorebird integration
# ──────────────────────────────────────────────
shorebird:
  enabled: false             # use shorebird release
  artifact: null             # apk | aab
  auto_confirm: true         # skip confirmation
```

## Output

Build artifacts are copied to the `output` directory (default: `dist/`) with naming:

```
{app_name}_{version}+{build_number}.{ext}
Example: myapp_1.2.3+45.aab
```

Logs are saved to:
- `dist/logs/build-latest.log` (always overwritten)
- `dist/logs/build-{version}-summary.json` (build summary)

## Development

```powershell
# Run tests
fvm dart test

# Analyze code
fvm dart analyze

# Compile to native binary
fvm dart compile exe bin/buildcraft.dart -o dist/buildcraft.exe
```

## Project Structure

```
mobile-build-cli/
├── bin/
│   └── buildcraft.dart           # CLI Entry point
├── lib/
│   ├── src/
│   │   ├── commands/             # Command implementations (build, clean, convert)
│   │   ├── core/                 # Core logic, business rules, and state
│   │   ├── ui/                   # Interactive Shell, Menu, and UI components
│   │   └── utils/                # Logging, Console I/O, and helper utilities
│   └── buildcraft.dart           # Main library export
├── scripts/
│   ├── compile.ps1               # Compilation script (Windows)
│   └── compile.sh                # Compilation script (Unix/Mac)
├── test/                         # Unit and integration tests
├── dist/                         # Build output (executables and logs)
├── buildcraft.yaml               # Active configuration file
├── buildcraft.yaml.example       # Configuration template
├── pubspec.yaml                  # Dart dependencies and metadata
└── analysis_options.yaml         # Static analysis rules
```

## License

MIT
