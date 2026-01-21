## 0.3.3 (2026-01-14)

### 🧹 Cleanup

- **Removed `no_review` Configuration** - No longer supported in YAML
  - Default behavior unchanged: Shows confirmation prompt by default
  - Existing `no_review` settings in config files are ignored
  - Use CLI flags: `--review` (force prompt), `-y`/`--no-review` (skip)
- Fixed `--no-confirm` CLI flag usage (now Shorebird-only, removed from shouldReview logic)
- Removed obsolete tests and fixtures

---

## 0.2.10 (2025-12-30)

### 🐛 Critical Bug Fixes

- **Shorebird Build Argument Parsing** - Fixed critical issue where Shorebird builds failed with "Missing argument for --build-name"
  - Root cause: Using `runInShell: true` on Windows caused cmd.exe to mangle the `--` separator and arguments
  - Solution: Disabled shell execution for Shorebird commands to pass arguments directly to the process
  - Added `runInShell` parameter to ProcessRunner.run() with default for backward compatibility
  - Kept `'--'` quoting in command display for Windows (per Shorebird docs), but execution uses unquoted array argument
  - Shorebird commands now execute correctly on Windows without shell interference

## 0.2.4 (2025-12-30)

### 🐛 Critical Bug Fixes

- **Edited Command Execution** - Fixed critical bug where manually edited build commands were never executed
  - Commands edited via `(e)dit command` option were validated and displayed but ignored during execution
  - Code was rebuilding commands from config instead of using the edited version
  - Now properly detects edited commands and executes them as provided by user
  - Added `buildFromCommand()` method in FlutterRunner for raw command execution
  - Shows "Final Command" section before execution so users see exactly what will run

### ✨ Enhancements

- **Command Execution Transparency** - Show final command immediately before execution
  - Displays "(Custom edited command - not generated from config)" when applicable
  - Logs whether command was manually edited by user in build log
  - Helps users verify the exact command being executed

- **Improved dart_define_from_file Debugging** - Enhanced validation and logging
  - Shows both configured path and resolved absolute path
  - Displays clear warning if file not found: "⚠ File not found!"
  - Explains that missing file will not be included in build command
  - Provides actionable guidance: "Create the file or update fluttercraft.yaml to fix this"

---

## 0.2.3 (2025-12-30)

### 🐛 Bug Fixes

- **Shorebird Error Detection** - Fixed false success reporting when Shorebird commands fail
  - Now detects Shorebird error patterns ("Missing argument", "Usage: shorebird") even when exit code is 0
  - Prevents misleading "BUILD COMPLETE" message when build actually failed
  - Shows appropriate error message: "Build failed: Shorebird command error detected"

### ✨ Enhancements

- **Command Edit Validation** - Added validation when manually editing build commands
  - Warns if `--build-name` is missing from Flutter arguments (after `--`)
  - Warns if `--build-number` is missing from Flutter arguments (after `--`)
  - Validates presence of `--` separator for Shorebird commands
  - Helps prevent accidental removal of required flags when adding custom arguments

- **dart_define_from_file Visibility** - Enhanced logging and validation
  - Now displays `dart_define_from_file` path in build log and console output
  - Shows file existence status (✓ or ✗ NOT FOUND) in console
  - Displays source: "(from flavor)" or "(from defaults)" when flavor is active
  - Validates file existence and warns if configured file is missing
  - Helps users verify configuration is loaded correctly and catch missing files early

---

## 0.2.2 (2025-12-22)

### 🐛 Bug Fixes

- **Shorebird Command Structure** - Fixed incorrect `--` separator placement in Shorebird commands
  - Corrected per official Shorebird documentation: only management flags (`--artifact`, `--no-confirm`, `--flutter-version`) go before `--`
  - All Flutter build flags (`--build-name`, `--build-number`, `--flavor`, `--target`, `--dart-define`, `--dart-define-from-file`) now correctly placed after `--` separator
  - Removed duplicate flags that were appearing both before and after `--`
  - **Before (incorrect)**: `shorebird release android --artifact=apk --build-name=1.0.0 -- --build-name=1.0.0 --dart-define=foo=bar`
  - **After (correct)**: `shorebird release android --artifact=apk --no-confirm --flutter-version=3.35.3 -- --build-name=1.0.0 --build-number=1 --dart-define-from-file=.env`

---

## 0.2.1 (2025-12-22)

### ✨ New Features

- **Dual Config Loading** - Support for both separate `fluttercraft.yaml` and embedded `pubspec.yaml` configuration
  - **Priority Chain**: `fluttercraft.yaml` (highest) → `pubspec.yaml` with `fluttercraft:` section → sensible defaults
  - **Config Source Tracking**: New `configSource` field in `AppContext` shows where config was loaded from
  - **No Auto-Generation**: Tool works with intelligent defaults when no config exists - no file creation
  - **Embedded Config Example**: Added `doc/examples/pubspec_embedded.yaml` showing how to embed config in `pubspec.yaml`

### ⚠️ BREAKING CHANGES

- **Root Key Requirement**: All config files (both `fluttercraft.yaml` and embedded) MUST now have `fluttercraft:` as root key

  **Old Format (No longer supported):**

  ```yaml
  build_defaults: &build_defaults
    platform: aab
  build:
    <<: *build_defaults
  ```

  **New Format (Required):**

  ```yaml
  fluttercraft:
    build_defaults: &build_defaults
      platform: aab
    build:
      <<: *build_defaults
  ```

### 🔄 Migration Guide

**Option 1: Auto-regenerate (Recommended)**

```bash
fluttercraft gen -f
```

**Option 2: Manual Update**

1. Add `fluttercraft:` at the beginning of your `fluttercraft.yaml`
2. Indent all existing content by 2 spaces

### 🛠️ Improvements

- **Clear Error Messages**: Helpful error messages with migration guidance when root key is missing
- **YAML Anchors**: Continue to work correctly with the new indented structure
- **Consistent Structure**: Same format whether using separate file or embedded config

---

## 0.2.0 (2025-12-22)

### 🎨 UI Improvements

- **Rich CLI Output**: Enhanced shell UI with colored borders, spinner animations, and better formatted tables.
- **Improved Summary**: Build summary now shows detailed information in a styled box.

### 🛠️ Fixes

- **Platform Handling**: Replaced deprecated `buildType` with `platform` internally.
- **Console Colors**: Fixed potential crash with undefined colors in prompts.
- **Validation**: Added explicit validation for supported platforms (Mobile only for now).

---

## 0.1.9 (2025-12-21)

### 🧹 Housekeeping

- **Removed Legacy Config**: Removed obsolete `.buildenv` system and related documentation scripts (`gen-buildenv.ps1`, `build.ps1`, `buildenv.base`).
- **Documentation**: Updated `doc/proj_structure.md` to accurately reflect the current project structure, including new core modules and tests.

---

## 0.1.8 (2025-12-19)

### 🐛 Bug Fixes

- **Shorebird Integration**: Fixed missing `--flutter-version` flag in Shorebird command generation when FVM is used.
- **Config UI**: Fixed `info -v` not displaying `dart_define_from_file` when the dart define map is empty.

---

## 0.1.7 (2025-12-19)

### ✨ New Features

- **Run Aliases** - Enhanced `run` command:
  - **Direct Execution** - Run aliases directly in shell (e.g. `> my_alias`)
  - **Runtime Parameters** - Support for `{0}` (positional) and `{key}` (named) placeholders.
  - **Preview** - Shows command preview before execution
  - **Auto-list** - `flc run` lists available aliases

---

## 0.1.6 (2025-12-18)

### ✨ New Features

- **No Review Option** - Added `no_review` config and CLI flag to skip final build confirmation
  - `build --no-review` or `build -y` skips the "Do you want to proceed?" prompt
  - Configurable via `build.no_review: true` in `fluttercraft.yaml`

---

## 0.1.5 (2025-12-18)

### 🔧 Improvements

- **Output path** - Changed default from `dist/` to `.fluttercraft/dist/`
- **Auto gitignore** - `flc gen` now adds `.fluttercraft/` to `.gitignore`
- **Console edge cases** - `choose()` now handles empty options and invalid defaultIndex

---

## 0.1.4 (2025-12-17)

### ⚠️ Breaking: Renamed Flag

- **`should_add_dart_define`** → **`should_prompt_dart_define`**
  - Config-defined `global_dart_define` + `dart_define` now **always** apply to builds
  - Flag now only controls interactive prompting for custom dart-defines at build time

### ✨ New Features

- **Interactive dart-define input** - When `should_prompt_dart_define: true`, prompts for custom `KEY=VALUE` pairs during build
- **Always apply config dart-defines** - `global_dart_define` and `dart_define` values are always included in build commands

### 🔧 Technical Changes

- Removed conditional guards from `finalDartDefine` and `finalDartDefineFromFile` getters
- Added interactive input loop in `build_command.dart`
- Updated `gen` command template with new flag name

---

## 0.1.3 (2025-12-17)

### 🔧 Enhancements

- **Shell UI** - Added `dart_define_from_file` display in `info -v` command
  - Shows file path in "Dart Define" section when configured
  - Helps users understand where dart define values are sourced from
  - Display format: `From File    .env.prod` (shown before individual defines)

---

## 0.1.2 (2025-12-17)

### ✨ New Features

- **dart_define_from_file support** - Configure `--dart-define-from-file` parameter in `fluttercraft.yaml`
  - Global configuration in `build_defaults.dart_define_from_file`
  - Flavor-specific overrides via `flavors.<flavor>.dart_define_from_file`
  - Supports `.env`, `.env.dev`, `.json` file formats
  - Automatically included in build command

### 🔧 Updates

- **gen command** - Updated `flc gen` to include `dart_define_from_file` examples in generated config
- **YAML structure** - Added `dart_define_from_file: null` to build_defaults section

---

## 0.1.1 (2025-12-16)

### ⚠️ Breaking: New YAML Structure

- `build_defaults` anchor for inheritance
- `environments` section (groups fvm, shorebird, bundletool)
- Renamed flags: `use_*` → `should_*`

### ✨ New Features

- **Build Flavors** - dev/staging/prod overrides
- **Explicit Dart Define** - global + flavor merging
- **No Color Mode** - `environments.no_color`

See [detailed changes](plans/v0.1.1/changed/CHANGES.md) for migration guide.

## 0.1.0 (2025-12-15)

### ⚠️ Breaking Changes

- **Breaking:** Renamed `auto_confirm` → `no_confirm` in Shorebird config (update your `fluttercraft.yaml`)

### ✨ New Features

- **Edit before build** - Type `e` at confirmation to modify the build command interactively
- **Reload command** - Added `reload`/`r` command in shell to hot-reload config from disk
- **Improved help** - Updated help format with proper sections

### 🐛 Bug Fixes

- **fix**: Removed `--release` flag from Shorebird builds (per official docs: "never add --release when using shorebird")
- **fix**: Shorebird artifact now correctly derived from build type

### 📝 Documentation

- Cleaner YAML format in generated `fluttercraft.yaml` (comments above lines, no uppercase labels)
- Added `@read-only` annotation for derived config values

---

## 0.0.6 (2025-12-15) - Initial Release

> **Craft Your Flutter Builds with Precision**

### ✨ Key Features

- **Interactive Shell** - Continuous REPL for rapid development
- **Streamlined Build Process** - Build, version, and deploy in one flow
- **Seamless Integrations** - FVM, Shorebird, auto-determine versions and context
- **Custom Command Aliases** - Define reusable command sequences via `flc run <alias>`

### 📦 Installation

```bash
# From pub.dev
dart pub global activate fluttercraft

# From binary
# Download fluttercraft.exe from releases
```

## 0.0.5 (2025-12-15)

- **feat**: Add BuildConfig for YAML-based project configuration, FVM integration, and update documentation and gitignore
- **refactor**: FlutterCraft (renamed ALL)
- **fix**: Complete rename to fluttercraft, also alias flb to flc
- **fix**: Auto-detect FVM Flutter version from `.fvmrc`
- **fix**: Auto-detect Shorebird app_id from `shorebird.yaml`

## 0.0.4 (2025-12-13)

- **New `gen` command** - Generate `fluttercraft.yaml` with `--force` flag support
- **Smart defaults** - CLI works without config file, reads from `pubspec.yaml`
- **Warning banner** - Shows message when `fluttercraft.yaml` is missing

## 0.0.3

- Shell mode improvements
- Build logging enhancements
- Version management fixes

## 1.0.0

- Initial version.
