# Test Plan

## Test Categories

### 1. Console Edge Cases (`test/utils/console_test.dart`)
| Test | Description |
|------|-------------|
| `choose with empty options` | Should handle gracefully |
| `choose with invalid defaultIndex` | Should clamp to valid range |
| `choose with out-of-range input` | Should return default |
| `prompt with null stdin` | Should return defaultValue |
| `confirm with invalid input` | Should return defaultValue |

### 2. Pubspec Parser (`test/core/pubspec_parser_test.dart`)
| Test | Description |
|------|-------------|
| `parse missing pubspec` | Should return null |
| `parse malformed YAML` | Should return null |
| `parse version without +` | Should default buildNumber to 1 |
| `parse missing version key` | Should use default |
| `parse empty name` | Should use default 'app' |

### 3. App Context (`test/core/app_context_test.dart`)
| Test | Description |
|------|-------------|
| `load without config file` | Should use defaults |
| `load without pubspec` | Should work with defaults |
| `hasConfigFile reflects reality` | Should match file existence |
| `reload updates context` | Should refresh values |
| `isStale after time passes` | Should detect stale context |

### 4. Build Config Edge Cases (`test/core/build_config_test.dart`)
| Test | Description |
|------|-------------|
| `empty build section` | Should use all defaults |
| `null values in YAML` | Should use defaults |
| `missing environments section` | Should use defaults |
| `empty alias cmds` | Should skip alias |
| `dart_define with null value` | Should skip entry |

### 5. Existing Feature Coverage Gaps

#### Run Command
- Empty alias commands list
- Alias with no cmds key

#### Gen Command
- Force overwrite behavior
- Gitignore already contains entry

#### Build Config
- Empty flavor section
- Flavor dart_define override priority

---

## Test Execution

```powershell
# Run specific test file
fvm flutter test test/utils/console_test.dart

# Run all tests
fvm flutter test
```
