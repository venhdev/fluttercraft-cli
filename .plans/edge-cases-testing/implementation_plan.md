# Edge Cases & Testing Enhancement

## Goals
1. Add comprehensive tests for edge cases (null, empty, malformed data)
2. Fix critical unhandled edge cases in console and config loading
3. Improve test coverage for existing features

---

## Critical Edge Cases Found

### Console (`lib/src/utils/console.dart`)

#### [ISSUE] `choose()` with empty options list
**Problem**: Crashes with index out of bounds if `options` list is empty.
**Fix**: Return -1 or throw descriptive exception for empty options.

#### [ISSUE] Invalid user input in `choose()`
**Current**: Shows warning but returns `defaultIndex` which may still crash.
**Fix**: Handle edge case when `defaultIndex >= options.length`.

---

### Build Config (`lib/src/core/build_config.dart`)

#### [ISSUE] Empty YAML content
**Current**: Throws generic `ConfigParseException`.
**Status**: ✅ Already handled

#### [ISSUE] Missing `build` section
**Current**: May return null values for required fields.
**Fix**: Add validation for required sections.

#### [ISSUE] Invalid `dart_define` value types
**Current**: ✅ Already validates primitive types

#### [NEW TEST NEEDED] Malformed version strings
**Example**: `name: "invalid.version"` should handle gracefully.

---

### Pubspec Parser (`lib/src/core/pubspec_parser.dart`)

#### [ISSUE] Malformed pubspec.yaml
**Current**: Returns `null` on parse error.
**Status**: ✅ Already handled

#### [NEW TEST NEEDED] Invalid version format in pubspec

---

### Shell (`lib/src/ui/shell.dart`)

#### [ISSUE] Null context operations
**Current**: ✅ Checks `appContext != null` before use

---

## Proposed Changes

### [MODIFY] console.dart
- Add guard for empty options in `choose()`
- Validate `defaultIndex` bounds

### [NEW] test/utils/console_test.dart
- Test empty options handling
- Test invalid choice input
- Test color output toggling

### [NEW] test/core/pubspec_parser_test.dart
- Test malformed pubspec
- Test missing version
- Test version parsing edge cases

### [NEW] test/core/app_context_test.dart
- Test loading without fluttercraft.yaml
- Test loading without pubspec.yaml
- Test reload functionality

### [MODIFY] test/core/build_config_test.dart
- Add malformed YAML tests
- Add missing section tests
- Add edge case value tests

---

## Verification Plan

```powershell
fvm flutter analyze --no-fatal-infos | Select-String "error|warning"
fvm flutter test
```
