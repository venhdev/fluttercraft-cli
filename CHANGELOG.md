## 0.1.2 (2025-12-17)

### ✨ New Features
- **dart_define_from_file support** - Configure `--dart-define-from-file` parameter in `fluttercraft.yaml`
  - Global configuration in `build_defaults.dart_define_from_file`
  - Flavor-specific overrides via `flavors.<flavor>.dart_define_from_file`  
  - Supports `.env`, `.env.dev`, `.json` file formats
  - Automatically included in build command when `should_add_dart_define: true`

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
