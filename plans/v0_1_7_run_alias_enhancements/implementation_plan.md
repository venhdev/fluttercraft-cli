# Implementation Plan - v0.1.7 Run Alias Enhancements

## Goal
Reliably verify the new run alias runtime parameter functionality with comprehensive tests, document the features, and release version 0.1.7.

## User Review Required
> [!NOTE]
> This plan focuses on strict verification and documentation. No functional code changes are expected unless bugs are found during testing.

## Proposed Changes

### Tests
#### [NEW] [test/plans/v0_1_7_run_alias_enhancements_test.dart](file:///C:/src/self/flutter-dart/cli/fluttercraft/test/plans/v0_1_7_run_alias_enhancements_test.dart)
- Migrate and expand comprehensive tests from `run_command_enhanced_test.dart`.
- Cover complex scenarios: multiple placeholders, shell escaping, interactive prompts, and precedence rules.

### Documentation
#### [MODIFY] [CHANGELOG.md](file:///C:/src/self/flutter-dart/cli/fluttercraft/CHANGELOG.md)
- Add entry for v0.1.7 detailing alias enhancements:
    - Direct alias execution in shell.
    - Runtime parameters (`{0}`, `{key}`, `{all}`).
    - Command preview.

#### [MODIFY] [README.md](file:///C:/src/self/flutter-dart/cli/fluttercraft/README.md)
- Update "Aliases" section to include Runtime Parameters syntax and examples.
- Add "Shell Mode" section explaining direct alias execution.

### Versioning
#### [MODIFY] [pubspec.yaml](file:///C:/src/self/flutter-dart/cli/fluttercraft/pubspec.yaml)
- Bump version to `0.1.7`.

#### [MODIFY] [lib/src/version.dart](file:///C:/src/self/flutter-dart/cli/fluttercraft/lib/src/version.dart)
- Update version constant to `0.1.7`.

## Verification Plan
1. Run `dart test test/plans/v0_1_7_run_alias_enhancements_test.dart`.
2. Run `fvm flutter analyze --no-fatal-infos`.
