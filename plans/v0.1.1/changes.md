# v0.1.1 Changes (2025-12-16)

## ⚠️ Breaking Changes

### New YAML Structure
Complete restructure of `fluttercraft.yaml` format:

- **`build_defaults` anchor** - Base configuration for inheritance via YAML anchor
- **`environments` section** - Groups `fvm`, `shorebird`, `bundletool` under one key
- **Renamed flags:**
  - `use_dart_define` → `should_add_dart_define`
  - `need_clean` → `should_clean`
  - `need_build_runner` → `should_build_runner`
- **Removed `paths.env`** - Use `dart_define` / `global_dart_define` instead
- **`app` section merged** - `app.name` moved to `build_defaults.app_name`

---

## ✨ New Features

### Build Flavors
Define `dev`, `staging`, `prod` flavors with overrides:

```yaml
flavors:
  dev:
    flags:
      should_add_dart_define: true
    dart_define:
      IS_DEV: true
```

Each flavor can override:
- `name` / `number` - Version per flavor
- `flags` - Build flags per flavor
- `dart_define` - Merged with global + base

### Explicit Dart Define
New `global_dart_define` + `dart_define` merging system:

```yaml
build_defaults:
  global_dart_define:
    APP_NAME: myapp
  dart_define: {}
  flags:
    should_add_dart_define: true
```

Merge order: `global_dart_define` → `dart_define` → `flavor.dart_define`

### No Color Mode
Disable console colors for CI/CD or logging:

```yaml
environments:
  no_color: true
```

### Flavor Output Path
Output directory includes flavor when set:
- `flavor: null` → `dist/`
- `flavor: dev` → `dist/dev/`

---

## 🔧 Improvements

- **refactor**: Downgraded SDK constraint from 3.9.2 to 3.7.0 for broader compatibility
- **fix**: Resolved parallel test execution failures
- **fix**: Improved `run` command exit code handling

---

## 📝 Migration Guide

1. Run `flc gen --force` to regenerate config in new format
2. Migrate your settings from old format:
   - Move `app.name` to `build_defaults.app_name`
   - Move `fvm`, `shorebird`, `bundletool` under `environments`
   - Rename flags with `should_` prefix
   - Replace `paths.env` with `dart_define`
