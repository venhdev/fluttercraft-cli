# fluttercraft CLI (fluttercraft) - Craft Your Flutter Builds with Precision

A cross-platform Dart CLI tool for building Flutter apps. Replaces PowerShell build scripts with a single portable executable.

## ✨ Key Features

- **Interactive Shell** - Continuous REPL for rapid development
- **Streamlined Build Process** - Build, version, and deploy in one flow
- **Seamless Integrations** - FVM, Shorebird, auto-determine versions and context
- **Custom Command Aliases** - Define reusable command sequences via `flc run <alias>`
- **Build Flavors** - Define dev/staging/prod with overrides (v0.1.1)
- **Explicit Dart Define** - Merge global + flavor dart defines (v0.1.1)
- **Edit Before Build** - Modify build command before execution (v0.1.0)
- **Reload Config** - Hot-reload configuration in shell mode (v0.1.0)

## Quick Start

```powershell
# Generate config (optional but recommended)
fluttercraft gen

# Build interactively
fluttercraft build

# Or build directly
fluttercraft build --type apk --no-confirm
```

## 📦 Installation

### From pub.dev (Recommended)
```bash
# Install globally
dart pub global activate fluttercraft

# Use anywhere
flc --version
flc build
```

### From Binary
1. Download `fluttercraft.exe` from [releases](https://github.com/venhdev/fluttercraft-cli/releases)
2. Add to PATH or run directly:
   ```bash
   .\fluttercraft.exe --help
   ```

### From Source
```bash
# Clone and activate
git clone https://github.com/venhdev/fluttercraft-cli.git
cd fluttercraft-cli
dart pub global activate --source path .

# Or install directly from git
dart pub global activate --source git https://github.com/venhdev/fluttercraft-cli.git
```

### Run Directly (No Installation)
```bash
# Clone repository
git clone https://github.com/venhdev/fluttercraft-cli.git
cd fluttercraft-cli

# Run commands
fvm dart run bin/fluttercraft.dart --help
fvm dart run bin/fluttercraft.dart build
```

## Commands

| `build` | Build Flutter app (APK/AAB/IPA) | `flc build --type apk` |
| `clean` | Clean project and dist folder | `flc clean --dist-only` |
| `convert` | Convert AAB to universal APK | `flc convert --aab app.aab` |
| `gen` | Generate fluttercraft.yaml | `flc gen --force` |
| `run` | Run custom command alias | `flc run gen-icon` |

**Shell Commands (in interactive mode):**

| Command | Description |
|---------|-------------|
| `reload`, `r` | Reload configuration from disk |
| `context`, `ctx` | Show loaded context |
| `help`, `?` | Show available commands |

**Interactive Mode:**
```powershell
flc --shell            # Start interactive shell
flc -s                 # Start interactive shell (short)
```

**Direct Mode:**
```powershell
flc                    # Show help (default)
flc build --type apk --no-confirm
flc run --list
```

## Configuration

### First Run (No Config Required)

The CLI works without `fluttercraft.yaml`:
- Reads app name/version from `pubspec.yaml`
- Uses sensible defaults
- Run `fluttercraft gen` to create config file

### `fluttercraft.yaml` (v0.1.1+)

```yaml
# Base configuration (anchor for inheritance)
build_defaults: &build_defaults
  app_name: myapp
  name: 1.0.0
  number: 1
  type: aab
  target: lib/main.dart

  # Dart defines (when should_add_dart_define = true)
  global_dart_define:
    APP_NAME: myapp
  dart_define: {}

  flags:
    should_add_dart_define: false
    should_clean: false
    should_build_runner: false

# Active build (inherits from build_defaults)
build:
  <<: *build_defaults
  flavor: null  # null | dev | staging | prod

# Flavor overrides
flavors:
  dev:
    flags:
      should_add_dart_define: true
    dart_define:
      IS_DEV: true
      LOG_LEVEL: debug

  staging:
    name: 1.0.0-rc
    flags:
      should_add_dart_define: true
      should_clean: true
    dart_define:
      IS_STAGING: true

  prod:
    flags:
      should_add_dart_define: true
      should_clean: true
      should_build_runner: true
    dart_define:
      IS_PROD: true

# Environment tools
environments:
  fvm:
    enabled: true
    version: null  # Auto-detected from .fvmrc if null

  shorebird:
    enabled: false
    app_id: null   # Auto-detected from shorebird.yaml
    artifact: null
    no_confirm: true

  bundletool:
    path: null
    keystore: android/key.properties

  no_color: false  # Disable console colors

# Output paths
paths:
  output: dist  # becomes dist/<flavor>/ when flavor is set

# Custom command aliases
alias:
  gen-icon:
    cmds:
      - fvm flutter pub get
      - fvm flutter pub run flutter_launcher_icons
```

## Build Flavors (v0.1.1+)

Define flavor-specific overrides in the `flavors` section:

```yaml
build:
  <<: *build_defaults
  flavor: dev  # Switch between: null | dev | staging | prod

flavors:
  dev:
    flags:
      should_add_dart_define: true
    dart_define:
      IS_DEV: true
      API_URL: https://dev.api.com

  prod:
    flags:
      should_add_dart_define: true
      should_clean: true
    dart_define:
      IS_PROD: true
      API_URL: https://api.com
```

**Flavor Overrides:**
- `name` / `number` - Override version per flavor
- `flags` - Override build flags per flavor
- `dart_define` - Merges with `global_dart_define` + base `dart_define`

**Output Path:** When flavor is set, output becomes `dist/<flavor>/`

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

