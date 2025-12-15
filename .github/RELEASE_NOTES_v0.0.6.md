# 🚀 FlutterCraft CLI - Initial Release

> **Craft Your Flutter Builds with Precision**

FlutterCraft is a cross-platform CLI tool that streamlines your Flutter build workflow with intelligent automation, custom aliases, and seamless integration with FVM and Shorebird.

## ✨ Key Features

### 🎯 Core Commands
- **Interactive Shell** - Continuous REPL experience for rapid development
- **Smart Build System** - Build APK/AAB/IPA with version management
- **Clean & Convert** - Project cleanup and AAB to APK conversion
- **Config Generation** - Auto-generate configuration with sensible defaults

### 🔧 Custom Command Aliases
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

Run them instantly:
```bash
flc run gen-icon
flc run brn
flc run --list  # Show all available aliases
```

### 🎯 Smart Integrations
- **FVM Support** - Automatic version detection from `.fvmrc`
- **Shorebird Integration** - Seamless OTA update builds
- **Smart Defaults** - Works without config, reads from `pubspec.yaml`

### 📦 Installation

**Global Activation:**
```bash
dart pub global activate fluttercraft
```

**Or run directly:**
```bash
dart pub global activate --source git https://github.com/venhdev/fluttercraft-cli.git
```

### 🎬 Quick Start

```bash
# Generate config (optional)
flc gen

# Build interactively
flc build

# Or build directly
flc build --type apk --no-confirm

# Use custom aliases
flc run gen-icon
```

### 📚 Documentation
- [README](https://github.com/venhdev/fluttercraft-cli#readme)
- [Configuration Guide](https://github.com/venhdev/fluttercraft-cli#configuration)
- [Custom Aliases](https://github.com/venhdev/fluttercraft-cli#custom-command-aliases)

### 🧪 Quality
- ✅ 17 passing tests
- ✅ Comprehensive test coverage
- ✅ Zero static analysis issues
- ✅ MIT Licensed

---

**What's Next?** Check out the [README](https://github.com/venhdev/fluttercraft-cli#readme) for detailed usage and configuration options.

**Feedback?** Open an [issue](https://github.com/venhdev/fluttercraft-cli/issues) or start a [discussion](https://github.com/venhdev/fluttercraft-cli/discussions)!
