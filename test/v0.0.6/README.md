# v0.0.6 Tests

Tests for custom command alias feature.

## Shared Test Configuration

The file `fluttercraft-test.yaml` contains all test aliases used across test files. This makes tests easier to maintain by centralizing test configurations.

**Location:** `test/v0.0.6/fluttercraft-test.yaml`

**Contains:**
- Simple single command (`simple`)
- Multiple commands (`multi`)
- Commands with arguments (`args`)
- FVM commands (`get`, `doctor`, `check`)
- Invalid command for error testing (`invalid`)
- Example aliases from documentation (`gen-icon`, `brn`)

---

## Test Files

### `alias_config_test.dart`
Tests for alias parsing in `BuildConfig`:
- Empty alias section
- Single alias with single command
- Single alias with multiple commands
- Multiple aliases
- Config without alias section
- Invalid alias configurations
- Complex command strings
- Command order preservation
- Special characters in alias names

**Run:**
```bash
fvm dart test test/v0.0.6/alias_config_test.dart
```

**Status:** ✅ All 10 tests passing

---

### `run_command_test.dart`
Integration tests for `RunCommand`:
- List aliases (`--list` and `-l` flags)
- Alias execution (single and multiple commands)
- Error handling
- Real command execution (echo, fvm dart pub get, fvm flutter doctor)

**Run:**
```bash
fvm dart test test/v0.0.6/run_command_test.dart
```

**Status:** ⚠️ 7 tests passing, 3 skipped (require fvm), 2 expected failures (exit() calls)

**Note:** Tests that call `exit()` will fail in test environment but work correctly in production.

---

## Run All v0.0.6 Tests

```bash
fvm dart test test/v0.0.6/
```

---

## Manual Testing

Some tests are marked with `skip` and require manual verification:

### Test 1: FVM Dart Pub Get
```bash
# Create test alias in fluttercraft.yaml
alias:
  get:
    cmds:
      - fvm dart pub get

# Run
flc run get
```

### Test 2: FVM Flutter Doctor
```bash
# Create test alias
alias:
  doctor:
    cmds:
      - fvm flutter doctor

# Run
flc run doctor
```

### Test 3: Combined Commands
```bash
# Create test alias
alias:
  check:
    cmds:
      - fvm dart pub get
      - fvm flutter doctor

# Run
flc run check
```

### Test 4: Error Handling
```bash
# Create test alias with nonexistent command
alias:
  fail:
    cmds:
      - this_command_does_not_exist

# Run (should show error and exit)
flc run fail
```

---

## Test Coverage

| Feature | Automated Tests | Manual Tests |
|---------|----------------|--------------|
| Alias parsing | ✅ 10 tests | - |
| List aliases | ✅ 3 tests | ✅ |
| Execute simple commands | ✅ 2 tests | ✅ |
| Execute multiple commands | ✅ 1 test | ✅ |
| Execute with arguments | ✅ 1 test | ✅ |
| FVM integration | ⏭️ Skipped | ✅ Required |
| Error handling | ⚠️ 2 tests (expected fail) | ✅ Required |

---

## Notes

- Tests use temporary directories for isolation
- Config parsing tests are fully automated
- Command execution tests require real shell environment
- Error handling tests that call `exit()` cannot be fully tested in unit tests
- Manual testing is required for fvm-dependent features
