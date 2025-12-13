# FlutterBuild CLI (flb)

A cross-platform Dart CLI tool for building Flutter apps. Replaces PowerShell build scripts with a single portable executable.

**Display Name:** `flb` - Short, fast, and friendly!

## Features

- 🖥️ **Interactive Shell** - Continuous REPL experience
- 🔧 **Build** - Build APK/AAB/IPA with version management
- 🧹 **Clean** - Clean project and dist folder
- 📦 **Convert** - Convert AAB to universal APK using bundletool
- ⚙️ **Gen** - Generate flutterbuild.yaml configuration file
- 🎯 **FVM Support** - Automatic FVM detection and usage
- 🐦 **Shorebird Support** - Integrated Shorebird release builds
- 🚀 **Smart Defaults** - Works without config, reads from pubspec.yaml

## Installation

### Option 1: Use Compiled Binary

Download `flutterbuild.exe` from the `bin/` folder and add it to your PATH.

```powershell
# Run from project root
.\bin\flutterbuild.exe --help
```

### Option 2: Global Activation

```powershell
# Activate globally (requires Dart SDK)
fvm dart pub global activate --source path .

# Then use anywhere
flutterbuild --help
```

### Option 3: Run Directly

```powershell
fvm dart run bin/flutterbuild.dart --help
```

## Interactive Shell

Start the interactive shell for a continuous REPL experience:

```powershell
# Start interactive shell (default when no args)
flutterbuild

# You'll see the flb prompt:
flb>
```

**Shell Commands:**
- `help` - Show available commands
- `context` / `ctx` - Show loaded project context
- `version` / `v` - Show version
- `build`, `clean`, `convert`, `gen` - Regular commands
- `exit` / `quit` / `q` - Exit shell

## Commands

### `flb build`

Build Flutter app with version management.

```powershell
# Interactive build with prompts
flb build

# Build specific type
flb build --type apk
flb build --type aab
flb build --type ipa

# Skip prompts
flb build --no-confirm

# Set version directly
flb build --version 1.2.3 --build-number 45

# Clean before building
flb build --clean
```

Options:
- `--type, -t` - Build type: apk, aab, ipa, app
- `--clean, -c` - Run flutter clean first
- `--no-confirm` - Skip confirmation prompts
- `--version, -v` - Set version directly
- `--build-number` - Set build number directly

### `flb clean`

Clean project and dist folder.

```powershell
# Full clean (flutter clean + remove dist)
flb clean

# Only remove dist folder
flb clean --dist-only

# Skip confirmation
flb clean -y
```

Options:
- `--dist-only` - Only remove dist folder
- `--yes, -y` - Skip confirmation prompts

### `flb convert`

Convert AAB to universal APK using bundletool.

```powershell
# Auto-detect AAB from dist folder
flb convert

# Specify AAB file
flb convert --aab path/to/app.aab

# Custom output directory
flb convert --output ./releases
```

Options:
- `--aab, -a` - Path to AAB file
- `--output, -o` - Output directory
- `--bundletool` - Path to bundletool.jar
- `--key-properties` - Path to key.properties

### `flb gen`

Generate `flutterbuild.yaml` configuration file.

```powershell
# Generate config (reads app name/version from pubspec.yaml)
flb gen

# Overwrite existing config
flb gen --force
```

Options:
- `--force, -f` - Overwrite existing flutterbuild.yaml

**What it does:**
- Creates `flutterbuild.yaml` in your project root
- Automatically populates app name and version from `pubspec.yaml`
- Sets sensible defaults for all other settings

## Configuration

### First Run

**Good news!** The CLI works without any configuration file. On first run:

1. **No `flutterbuild.yaml`?** The CLI will:
   - Read app name and version from `pubspec.yaml`
   - Use sensible defaults for all settings
   - Show a warning: "⚠ No flutterbuild.yaml found. Run 'gen' to create one."

2. **Generate config** (recommended):
   ```powershell
   flb gen
   ```
   This creates `flutterbuild.yaml` with your app's name and version pre-filled.

### `flutterbuild.yaml` File

The build configuration is stored in `flutterbuild.yaml` at the project root.
Generate it with `flb gen` or copy `flutterbuild.yaml.example`.

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
- `.flutterbuild/build_latest.log` (always overwritten)
- `.flutterbuild/logs/{build-id}.log` (per-build log)
- `.flutterbuild/build_history.jsonl` (JSONL build history)

## Development

```powershell
# Install dependencies
fvm dart pub get

# Run tests
fvm dart test

# Analyze code
fvm dart analyze

# Compile to native binary
.\scripts\compile.ps1
# Output: bin/flutterbuild.exe
```

## Project Structure

```
mobile-build-cli/
├── bin/
│   └── flutterbuild.dart         # CLI Entry point
├── lib/
│   ├── src/
│   │   ├── commands/             # Command implementations (build, clean, convert)
│   │   ├── core/                 # Core logic, business rules, and state
│   │   ├── ui/                   # Interactive Shell, Menu, and UI components
│   │   └── utils/                # Logging, Console I/O, and helper utilities
│   └── flutterbuild.dart         # Main library export
├── scripts/
│   ├── compile.ps1               # Compilation script (Windows)
│   └── compile.sh                # Compilation script (Unix/Mac)
├── test/                         # Unit and integration tests
├── bin/                          # Compiled executable
├── flutterbuild.yaml             # Active configuration file
├── flutterbuild.yaml.example     # Configuration template
├── pubspec.yaml                  # Dart dependencies and metadata
└── analysis_options.yaml         # Static analysis rules
```

## Why "flb"?

**FlutterBuild** → **flb** (Flutter Build)

- ⚡ **Fast to type**: Only 3 characters
- 🎯 **Clear purpose**: Flutter Build
- 💪 **Professional**: Sounds like a proper build tool
- 🚀 **Memorable**: Short and punchy

## License

MIT
