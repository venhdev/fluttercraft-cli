# fluttercraft CLI (fluttercraft)

**Craft Your Flutter Builds with Precision**

A cross-platform Dart CLI tool for building Flutter apps. Replaces PowerShell build scripts with a single portable executable.

## ✨ Key Features

- **Interactive Shell**: Continuous REPL for rapid development.
- **Streamlined Workflow**: Build, version, and deploy in one flow.
- **Advanced Config**: Supports Build Flavors, FVM, Shorebird, and custom Aliases.
- **Zero Setup**: Works out-of-the-box or with a generated config.

## 🚀 Quick Start

```bash
# 1. Install
dart pub global activate fluttercraft

# 2. Generate config (optional)
flc gen

# 3. Build interactively
flc build

# 4. Or build directly
flc build --type apk --no-confirm
```

## 📦 Installation

**Recommended:**
```bash
dart pub global activate fluttercraft
```

**Alternative:** Download the binary from [Releases](https://github.com/venhdev/fluttercraft-cli/releases).

## 🛠 Commands

| Command | Description | Example |
|:---|:---|:---|
| `build` | Build Flutter app (APK/AAB/IPA) | `flc build --type apk` |
| `clean` | Clean project and dist folder | `flc clean` |
| `gen` | Generate configuration file | `flc gen` |
| `run` | Run custom command alias | `flc run gen-icon` |
| `info` | Show loaded context/config | `flc info` |
| `help` | Show available commands | `flc help` |

> **Tip:** run `flc --shell` to enter interactive mode.

## ⚙️ Configuration (`fluttercraft.yaml`)

Run `flc gen` to create a starter file.

```yaml
# Simplified Example
build_defaults: &build_defaults
  app_name: myapp
  name: 1.0.0
  type: aab
  dart_define_from_file: .env

build:
  <<: *build_defaults
  flavor: dev # dev | staging | prod

flavors:
  dev:
    dart_define:
      IS_DEV: true
    dart_define_from_file: .env.dev
  prod:
    flags:
      should_clean: true

environments:
  fvm:
    enabled: true # Auto-detects version from .fvmrc

alias:
  gen-assets:
    cmds:
      - fvm flutter pub run build_runner build
```

## 📂 Output

Builds are saved to `dist/` (or `dist/<flavor>/`).
Logs are stored in `.fluttercraft/`.

## License

MIT
