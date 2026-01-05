# Shorebird Workflow Guide

## Overview

This document consolidates all Shorebird-related workflows, configurations, and usage patterns in the fluttercraft CLI.

---

## Table of Contents

1. [Configuration](#configuration)
2. [Command Structure](#command-structure)
3. [Release Workflow](#release-workflow)
4. [Patch Workflow](#patch-workflow)
5. [Build Arguments](#build-arguments)
6. [Integration Points](#integration-points)
7. [Error Handling](#error-handling)
8. [Testing](#testing)

---

## Configuration

### YAML Configuration

Shorebird is configured in `fluttercraft.yaml` under the `environments` section:

```yaml
fluttercraft:
  environments:
    shorebird:
      enabled: true
      app_id: your_app_id  # Auto-detected from shorebird.yaml if null
      artifact: null        # Derived from build.platform (apk/aab)
      no_confirm: true      # Skip Shorebird confirmation prompts
```

### Auto-Detection

- **app_id**: Automatically detected from `shorebird.yaml` if not specified
- **artifact**: Derived from `build.platform` (`apk` for APK, `aab` for AAB)

### Related Settings

```yaml
fluttercraft:
  build_defaults:
    no_review: false  # Controls fluttercraft's confirmation prompt (separate from Shorebird)
  
  environments:
    fvm:
      enabled: true
      version: "3.35.3"  # Can be used with --flutter-version flag
```

**Important**: `no_review` and `shorebird.no_confirm` are independent:
- `no_review`: Controls fluttercraft's "Do you want to proceed?" prompt
- `shorebird.no_confirm`: Controls Shorebird's `--no-confirm` flag

---

## Command Structure

### Argument Placement Rules

Per [Shorebird official documentation](https://docs.shorebird.dev/):

**Before `--` separator** (Shorebird management flags):
- `--artifact=apk|aab`
- `--no-confirm`
- `--flutter-version=X.Y.Z`

**After `--` separator** (Flutter build flags):
- `--build-name=X.Y.Z`
- `--build-number=N`
- `--flavor=FLAVOR`
- `--target=lib/main.dart`
- `--dart-define=KEY=VALUE`
- `--dart-define-from-file=.env`

### Example Commands

**Correct Structure**:
```bash
shorebird release android --artifact=apk --no-confirm --flutter-version=3.35.3 -- --build-name=1.0.0 --build-number=1 --flavor=prod --dart-define-from-file=.env
```

**Incorrect** (old structure - DO NOT USE):
```bash
# ❌ Wrong: Duplicates flags before and after --
shorebird release android --artifact=apk --build-name=1.0.0 -- --build-name=1.0.0 --dart-define=foo=bar
```

### Platform Mapping

| Build Platform | Shorebird Platform | Default Artifact |
|----------------|-------------------|------------------|
| `apk`          | `android`         | `apk`            |
| `aab`          | `android`         | `aab`            |
| `ipa` / `ios`  | `ios`             | N/A              |
| `app` / `macos`| `macos`           | N/A              |

---

## Release Workflow

### 1. Initial Release

```bash
flc build --platform apk --use-shorebird
```

This generates:
```bash
shorebird release android --artifact=apk --no-confirm -- --build-name=1.0.0 --build-number=1
```

### 2. With Flavor

```bash
flc build --platform apk --flavor prod --use-shorebird
```

Generates:
```bash
shorebird release android --artifact=apk --no-confirm -- --build-name=1.0.0 --build-number=1 --flavor=prod --target=lib/main_prod.dart
```

### 3. With FVM Version

```yaml
environments:
  fvm:
    enabled: true
    version: "3.24.0"
  shorebird:
    enabled: true
```

Generates:
```bash
shorebird release android --artifact=apk --no-confirm --flutter-version=3.24.0 -- --build-name=1.0.0 --build-number=1
```

### 4. With Environment Variables

```yaml
build:
  dart_define_from_file: .env.prod
```

Generates:
```bash
shorebird release android --artifact=apk --no-confirm -- --build-name=1.0.0 --build-number=1 --dart-define-from-file=/absolute/path/.env.prod
```

---

## Patch Workflow

### Creating a Patch

```bash
shorebird patch android --release-version latest
```

### With Specific Version

```bash
shorebird patch android --release-version 0.1.0+1
```

### With Flavor and Target

```bash
shorebird patch android --target ./lib/main_development.dart --flavor development
```

### Passing Flutter Build Arguments

```bash
shorebird patch android -- --dart-define="foo=bar"
```

**PowerShell Note**: The `--` separator must be quoted:
```powershell
shorebird patch android '--' --dart-define="foo=bar"
```

---

## Build Arguments

### Flags NOT Included with Shorebird

❌ **Never add these** (per Shorebird docs):
- `--release`
- `--debug`
- `--profile`

### Required Flags

✅ **Always include** (after `--`):
- `--build-name=X.Y.Z`
- `--build-number=N`

### Optional Flags

- `--flavor=FLAVOR`
- `--target=lib/main.dart`
- `--dart-define=KEY=VALUE`
- `--dart-define-from-file=.env`

---

## Integration Points

### FlutterRunner Implementation

Located in [`lib/src/core/flutter_runner.dart`](../lib/src/core/flutter_runner.dart):

```dart
/// Build with Shorebird
Future<ProcessResult> _buildWithShorebird(
  BuildConfig config,
  List<String> flutterArgs,
) async {
  final sbPlatform = _getShorebirdPlatform(config.platform);
  final sbArgs = <String>['release', sbPlatform];

  // Management flags (before --)
  if (sbPlatform == 'android' && config.platform == 'apk') {
    sbArgs.add('--artifact=apk');
  }
  if (config.shorebirdNoConfirm) {
    sbArgs.add('--no-confirm');
  }
  if (config.flutterVersion != null) {
    sbArgs.add('--flutter-version=${config.flutterVersion}');
  }

  // Flutter build flags (after --)
  sbArgs.add('--');
  if (config.buildName != null) {
    sbArgs.add('--build-name=${config.buildName}');
  }
  if (config.buildNumber != null) {
    sbArgs.add('--build-number=${config.buildNumber}');
  }
  // ... more Flutter flags
}
```

### BuildConfig Loading

Located in [`lib/src/core/build_config.dart`](../lib/src/core/build_config.dart):

```dart
// Shorebird settings
final shorebird = environments?['shorebird'] as YamlMap?;
final useShorebird = YamlHelpers.getBool(shorebird, 'enabled', null) ?? false;
var shorebirdAppId = YamlHelpers.getStringOrNull(shorebird, 'app_id');
final shorebirdArtifact = YamlHelpers.getStringOrNull(shorebird, 'artifact');
final shorebirdNoConfirm = YamlHelpers.getBool(shorebird, 'no_confirm', null) ?? true;

// Auto-detect app_id from shorebird.yaml
if (useShorebird && shorebirdAppId == null) {
  shorebirdAppId = EnvironmentDetectors.detectShorebirdAppId(projectRoot);
}
```

### Environment Detection

Located in [`lib/src/core/helpers/environment_detectors.dart`](../lib/src/core/helpers/environment_detectors.dart):

```dart
/// Detect Shorebird app_id from shorebird.yaml file
static String? detectShorebirdAppId(String projectRoot) {
  try {
    final shorebirdPath = p.join(projectRoot, 'shorebird.yaml');
    final shorebirdFile = File(shorebirdPath);
    
    if (!shorebirdFile.existsSync()) return null;
    
    final content = shorebirdFile.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap?;
    
    return yaml?['app_id']?.toString();
  } catch (e) {
    return null;
  }
}
```

---

## Error Handling

### Detection Patterns

Located in [`lib/src/commands/build_command.dart`](../lib/src/commands/build_command.dart):

```dart
// Check for Shorebird-specific error patterns even when exit code is 0
final hasShorebirdError = buildConfig.useShorebird && (
  buildResult.stdout.contains('Missing argument') ||
  buildResult.stdout.contains('Usage: shorebird') ||
  buildResult.stdout.contains('Run "shorebird help"') ||
  buildResult.stderr.contains('error:') ||
  buildResult.stderr.contains('Error:')
);

if (hasShorebirdError && buildResult.success) {
  console.error('Build failed: Shorebird command error detected');
  logger.error('Build failed: Shorebird returned usage/error message');
}
```

### Command Validation

When manually editing commands (via `e` option):

```dart
// Validate required flags for Shorebird commands
if (buildConfig.useShorebird && edited.contains('shorebird')) {
  final hasDoubleDash = edited.contains(' -- ');
  if (hasDoubleDash) {
    final parts = edited.split(' -- ');
    final flutterArgs = parts.length > 1 ? parts[1] : '';
    
    if (!flutterArgs.contains('--build-name')) {
      console.warning('Warning: --build-name is missing from Flutter arguments (after --).');
    }
    if (!flutterArgs.contains('--build-number')) {
      console.warning('Warning: --build-number is missing from Flutter arguments (after --).');
    }
  } else {
    console.warning('Warning: Missing -- separator for Flutter build arguments.');
  }
}
```

---

## Testing

### Unit Tests

Located in [`test/core/flutter_runner_test.dart`](../test/core/flutter_runner_test.dart):

```dart
test('getBuildCommand handles Shorebird with standard settings', () {
  final config = BuildConfig(
    // ... config
    useShorebird: true,
    shorebirdNoConfirm: true,
  );

  final cmd = runner.getBuildCommand(config);
  
  expect(cmd, startsWith('shorebird release android'));
  expect(cmd, contains('--artifact=apk'));
  expect(cmd, contains('--no-confirm'));
  expect(cmd, anyOf(contains('-- '), contains("'--'")));
});

test('getBuildCommand handles Shorebird iOS with correct flags', () {
  final config = BuildConfig(
    // ... config
    platform: 'ipa',
    useShorebird: true,
    flavor: 'prod',
  );

  final cmd = runner.getBuildCommand(config);
  
  expect(cmd, startsWith('shorebird release ios'));
  expect(cmd, contains('--build-name=1.0.0'));
  expect(cmd, contains('--flavor=prod'));
  expect(cmd, contains('--target=lib/main_prod.dart'));
});
```

### Integration Tests

Located in [`test/core/dart_define_from_file_test.dart`](../test/core/dart_define_from_file_test.dart):

```dart
test('includes dart_define_from_file in Shorebird command', () async {
  await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
fluttercraft:
  build:
    platform: apk
    dart_define_from_file: .env.dev
  environments:
    shorebird:
      enabled: true
      no_confirm: true
''');

  final config = await BuildConfig.load(projectRoot: tempDir);
  expect(config.finalDartDefineFromFile, '.env.dev');
  expect(config.useShorebird, true);
});
```

---

## Key Changes (CHANGELOG)

### v0.2.10 (2025-12-30)
- **Critical Fix**: Fixed "Missing argument for --build-name" error
  - Root cause: Windows shell was mangling `--` separator
  - Solution: Disabled shell execution for Shorebird commands

### v0.2.3 (2025-12-30)
- **Bug Fix**: Fixed false success reporting when Shorebird commands fail
  - Now detects error patterns even when exit code is 0

### v0.2.2 (2025-12-22)
- **Bug Fix**: Fixed incorrect `--` separator placement
  - All Flutter flags now correctly placed after `--`
  - Removed duplicate flags

### v0.1.8 (2025-12-19)
- **Bug Fix**: Fixed missing `--flutter-version` flag when FVM is used

### v0.1.0 (2025-12-15)
- **Breaking**: Renamed `auto_confirm` → `no_confirm`
- **Bug Fix**: Removed `--release` flag (per Shorebird docs)

---

## Official Shorebird Documentation

### Key Points from Official Docs

1. **Argument Separator**: Flutter build arguments must go after `--`
   - PowerShell requires quoting: `'--'`

2. **No Release Flag**: Never use `--release`, `--debug`, or `--profile`

3. **Version Targeting**: Use `--release-version latest` to patch the latest release

4. **Flavors**: Support via `--flavor` and `--target` flags (after `--`)

5. **Flutter Version**: Can specify with `--flutter-version` (before `--`)

### Useful Commands

```bash
# Check Shorebird installation
shorebird doctor

# List releases
shorebird releases

# View console
https://console.shorebird.dev/apps/<app_id>

# Side-loading (APK)
shorebird release android --artifact=apk
```

---

## Troubleshooting

### Common Issues

1. **"Missing argument for --build-name"**
   - Ensure `--build-name` and `--build-number` are after `--`
   - Check that shell execution is disabled for Shorebird commands

2. **"Usage: shorebird" output**
   - Command syntax error
   - Validate `--` separator placement

3. **False success reporting**
   - Check for error patterns in stdout/stderr
   - Verify exit code and output messages

4. **Version mismatch**
   - Ensure `--flutter-version` matches FVM version
   - Run `shorebird doctor` to check version

### Debug Mode

Enable verbose logging in `fluttercraft.yaml`:

```yaml
environments:
  no_color: false  # Keep colors for better readability
```

Or check build logs at `.fluttercraft/logs/build.jsonl`

---

## References

- [Shorebird Official Docs](https://docs.shorebird.dev/)
- [Shorebird Release Guide](https://docs.shorebird.dev/code-push/release/)
- [Shorebird Patch Guide](https://docs.shorebird.dev/code-push/patch/)
- [lib/src/core/flutter_runner.dart](../lib/src/core/flutter_runner.dart)
- [lib/src/core/build_config.dart](../lib/src/core/build_config.dart)
- [doc/refs/shorebird/shorebird-official-docs.md](../refs/shorebird/shorebird-official-docs.md)
- [doc/refs/shorebird/shorebird-args-note.md](../refs/shorebird/shorebird-args-note.md)

---

**Last Updated**: 2025-12-30  
**Version**: v0.2.10