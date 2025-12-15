# v0.1.0 Tests

Tests for v0.1.0 features.

## Shared Test Configuration

The file `fluttercraft-test.yaml` contains the base test configuration:
- Shorebird enabled with `no_confirm: true`
- FVM disabled
- Build type: apk

**Location:** `test/v0.1.0/fluttercraft-test.yaml`

---

## Test Files

### `shorebird_args_test.dart`
Tests for Shorebird build argument fixes:
- `--release` flag NOT added when using Shorebird (per official docs)
- `--release` flag IS added for non-Shorebird builds
- `--no-confirm` flag included when `no_confirm: true`
- `--no-confirm` flag excluded when `no_confirm: false`

**Run:**
```bash
fvm dart test test/v0.1.0/shorebird_args_test.dart
```

**Status:** ✅ 4 tests

---

### `config_no_confirm_test.dart`
Tests for `no_confirm` config parsing:
- Parses `no_confirm: true` correctly
- Parses `no_confirm: false` correctly
- Default value is `true` when key missing
- Default value is `true` when shorebird section missing
- Default value is `true` when config file missing

**Run:**
```bash
fvm dart test test/v0.1.0/config_no_confirm_test.dart
```

**Status:** ✅ 5 tests

---

## Run All v0.1.0 Tests

```bash
fvm dart test test/v0.1.0/
```

---

## Test Coverage

| Feature | Automated Tests |
|---------|----------------|
| Shorebird --release fix | ✅ 2 tests |
| --no-confirm flag | ✅ 2 tests |
| no_confirm parsing | ✅ 5 tests |

---

## Notes

- Tests use `TestHelper.copyTestFile()` for shared configs
- Tests use `TestHelper.writeFile()` for inline configs
- Tests use `TestHelper.createTempDirWithCleanup()` for temp directories
