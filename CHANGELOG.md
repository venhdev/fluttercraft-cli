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
