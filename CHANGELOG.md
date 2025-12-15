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

