# v0.1.1 Tests

Tests for the new YAML format restructure and related features.

## Test Files

| File | Description | Tests |
|------|-------------|-------|
| `new_yaml_format_test.dart` | Tests for new YAML structure with `build_defaults`, `environments`, `paths`, and renamed flags | 15 |
| `flavor_resolution_test.dart` | Tests for flavor override logic, error handling, output paths | 10 |
| `dart_define_test.dart` | Tests for `global_dart_define` + `dart_define` merging, value types | 15 |
| `build_flags_test.dart` | Tests for `BuildFlags` model, merging, defaults | 9 |
| `flavor_config_test.dart` | Tests for `FlavorConfig` parsing, validation | 12 |

## Features Tested

### 1. New YAML Structure
- `build_defaults` anchor parsing
- `build` section inheriting from defaults
- `build` overriding `build_defaults` values
- `environments` section (fvm, shorebird, bundletool, no_color)
- `paths` section
- Renamed flags (`should_add_dart_define`, `should_clean`, `should_build_runner`)

### 2. Flavor Resolution
- Applying flavor overrides (dev, staging, prod)
- Version name/number overrides per flavor
- Flag overrides per flavor
- Error when flavor not found
- Null flavor handling
- Output path with flavor suffix

### 3. Dart Define Merging
- `global_dart_define` parsing
- `dart_define` parsing
- Merging global + local defines
- Local overrides global for same key
- Flavor `dart_define` overrides
- Value type validation (string, bool, number)
- Rejection of object/list values

### 4. Model Classes
- `BuildFlags` construction and merging
- `FlavorConfig` parsing from YAML
- `FlavorConfig` validation

### 5. Console Settings
- `environments.no_color` parsing
- Default to `false` when not specified

## Running Tests

```bash
# All v0.1.1 tests
fvm dart test test/v0.1.1/

# Specific test file
fvm dart test test/v0.1.1/flavor_resolution_test.dart

# With verbose output
fvm dart test test/v0.1.1/ --reporter expanded
```
