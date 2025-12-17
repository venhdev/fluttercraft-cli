# Simplify Config Loading Plan

## Overview
**CLEAN BREAK** - Remove ALL config sync, backup, and migration logic. No backward compatibility.

Users manage `pubspec.yaml` and `fluttercraft.yaml` separately. Use `gen` command only for initial setup or force regeneration.

## Goals
- ✅ **Single Source of Truth**: `pubspec.yaml` = app metadata, `fluttercraft.yaml` = build config
- ✅ **Remove ALL Sync Logic**: No automatic version syncing between files
- ✅ **Remove ALL Backup Logic**: No config backup system
- ✅ **Simple Tool**: `gen` command creates/updates config file only when user explicitly runs it

## Problem Statement

Current fluttercraft has too many issues with dual config management:
1. **Automatic Syncing**: `syncVersion()` tries to keep files in sync - causes confusion
2. **Backup System**: Complex backup logic that users don't need
3. **Duplicate Keys**: Same data in two places leads to drift and bugs
4. **Over-Engineering**: Too much code for a simple problem

## Solution: REMOVE ALL

### Core Principle
**Never read app metadata from `fluttercraft.yaml`**
- ✅ `pubspec.yaml` → `name`, `version` (always)
- ✅ `fluttercraft.yaml` → build settings only (platform, flags, dart_define, etc.)
- ✅ `gen` command → creates initial config or force-updates it

### User Workflow
1. **First time**: Run `fluttercraft gen` to create `fluttercraft.yaml`
2. **Need to update**: Edit files manually OR run `fluttercraft gen -f` to regenerate
3. **Build**: Fluttercraft reads `pubspec.yaml` for app info + `fluttercraft.yaml` for build settings

**No automatic syncing. No backups. No magic.**

## Changes

### 1. DELETE Entire Files

**Complete removal, no replacement:**
- ❌ `lib/src/core/config_backup.dart` - entire backup system
- ❌ `test/core/config_backup_test.dart` - all backup tests
- ❌ `test/ui/shell_test.dart` - all sync-related tests

### 2. DELETE Methods from `lib/src/ui/shell.dart`

**Remove these methods completely:**
```dart
// ❌ DELETE
Future<void> syncVersion() async { ... }

// ❌ DELETE  
Future<void> _backupConfig(String reason) async { ... }
```

**Remove sync call from `Shell.run()`:**
```dart
// BEFORE:
Future<int> run() async {
  // Sync version on startup
  await syncVersion();  // ❌ DELETE THIS LINE
  
  // ... rest of code
}

// AFTER:
Future<int> run() async {
  // No syncing - load config as-is
  // ... rest of code
}
```

### 3. UPDATE `lib/src/core/build_config.dart`

**Simplify `_parseNewFormat()` - Remove all version fallback logic:**

```dart
static BuildConfig _parseNewFormat(
  YamlMap yaml,
  String projectRoot, {
  PubspecInfo? pubspecInfo,
}) {
  // ═══════════════════════════════════════════════════════════════
  // ALWAYS USE PUBSPEC FOR APP METADATA - NO FALLBACKS
  // ═══════════════════════════════════════════════════════════════
  final appName = pubspecInfo?.name ?? 'app';
  final buildName = pubspecInfo?.buildName ?? '1.0.0';
  final buildNumber = int.tryParse(pubspecInfo?.buildNumber ?? '1') ?? 1;

  // ═══════════════════════════════════════════════════════════════
  // READ BUILD CONFIG FROM YAML (NO VERSION FIELDS)
  // ═══════════════════════════════════════════════════════════════
  final buildDefaults = yaml['build_defaults'] as YamlMap?;
  final build = yaml['build'] as YamlMap?;

  // Platform, target, etc. (build settings only)
  final platform = _getString(build, 'platform', null) ??
      _getString(buildDefaults, 'platform', 'aab');
  final targetDart = _getString(build, 'target', null) ??
      _getString(buildDefaults, 'target', 'lib/main.dart');
  
  // ❌ NO LONGER READ: app_name, name, number from YAML
  
  // ... rest of parsing logic
}
```

**Remove these lines from `_parseNewFormat()`:**
```dart
// ❌ DELETE - don't read app_name from YAML
final appName = _getString(buildDefaults, 'app_name', pubspecInfo?.name ?? 'app');

// ❌ DELETE - don't read version name from YAML
final buildName = _getString(buildDefaults, 'name', pubspecInfo?.buildName ?? '1.0.0');

// ❌ DELETE - don't read build number from YAML
final buildNumber = _getInt(buildDefaults, 'number', ...);
```

### 4. UPDATE `lib/src/core/flavor_config.dart`

**Remove version override fields:**

```dart
class FlavorConfig {
  final String name;
  
  // ❌ DELETE these fields
  // final String? versionName;
  // final int? buildNumber;
  
  final String? platform;
  final Map<String, dynamic> dartDefine;
  final String? dartDefineFromFile;
  // ... rest
}
```

**Update `FlavorConfig.fromYaml()`:**
```dart
static FlavorConfig fromYaml(String name, YamlMap yaml) {
  // ❌ DELETE version parsing
  // final versionName = yaml['name']?.toString();
  // final buildNumber = ...;
  
  // ✅ KEEP build settings only
  final platform = yaml['platform']?.toString();
  final dartDefineMap = yaml['dart_define'] as YamlMap?;
  // ... parse flags, args, etc.

  return FlavorConfig(
    name: name,
    // versionName: versionName,  // ❌ DELETE
    // buildNumber: buildNumber,  // ❌ DELETE
    platform: platform,
    dartDefine: dartDefine,
    // ... rest
  );
}
```

### 5. UPDATE `lib/src/commands/gen_command.dart`

**Generate clean config without app metadata:**

```dart
Future<int> run() async {
  final force = argResults?['force'] == true;
  final projectRoot = Directory.current.path;

  // Load pubspec to get app name for reference
  final pubspecParser = PubspecParser(projectRoot: projectRoot);
  final pubspecInfo = await pubspecParser.parse();
  final appName = pubspecInfo?.name ?? 'app';

  // Generate YAML WITHOUT version fields
  final template = '''
# fluttercraft.yaml - Build Configuration
# 
# App name and version are ALWAYS read from pubspec.yaml
# This file only contains build-specific settings

# ══════════════════════════════════════════════════════════════════════════════
# BASE BUILD CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════
build_defaults: &build_defaults
  # Platform: aab | apk | ipa | ios | app
  platform: aab
  
  # Main entry point
  target: lib/main.dart
  
  # Skip code review checklist
  no_review: false
  
  # Extra build arguments
  args: []
  
  # Dart Define
  global_dart_define: {}
  dart_define: {}
  dart_define_from_file: null
  
  # Build Flags
  flags:
    should_prompt_dart_define: false
    should_clean: false
    should_build_runner: false

# ══════════════════════════════════════════════════════════════════════════════
# ACTIVE BUILD CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════
build:
  <<: *build_defaults
  flavor: null

# ══════════════════════════════════════════════════════════════════════════════
# FLAVOR OVERRIDES (NO VERSION OVERRIDES - use dart_define instead)
# ══════════════════════════════════════════════════════════════════════════════
flavors:
  dev:
    platform: apk
    dart_define:
      FLAVOR: dev
      IS_DEV: true
    flags:
      should_clean: false

  prod:
    platform: aab
    dart_define:
      FLAVOR: prod
      IS_PROD: true
    flags:
      should_clean: true
      should_build_runner: true

# ══════════════════════════════════════════════════════════════════════════════
# ENVIRONMENT TOOLS
# ══════════════════════════════════════════════════════════════════════════════
environments:
  fvm:
    enabled: true
    version: null
  
  shorebird:
    enabled: false
    app_id: null
    artifact: null
    no_confirm: true
  
  bundletool:
    path: null
    keystore: android/key.properties
  
  no_color: false

# ══════════════════════════════════════════════════════════════════════════════
# OUTPUT PATHS
# ══════════════════════════════════════════════════════════════════════════════
paths:
  output: .fluttercraft/dist

# ══════════════════════════════════════════════════════════════════════════════
# CUSTOM COMMAND ALIASES
# ══════════════════════════════════════════════════════════════════════════════
alias:
  gen-icon:
    cmds:
      - fvm flutter pub get
      - fvm flutter pub run flutter_launcher_icons
  brn:
    cmds:
      - fvm flutter pub get
      - fvm flutter packages pub run build_runner build --delete-conflicting-outputs
''';

  // Write file
  final configPath = p.join(projectRoot, 'fluttercraft.yaml');
  final file = File(configPath);
  
  if (await file.exists() && !force) {
    console.error('fluttercraft.yaml already exists');
    console.info('Use --force to overwrite');
    return 1;
  }

  await file.writeAsString(template);
  console.success('Generated fluttercraft.yaml');
  console.info('App metadata (name, version) will be read from pubspec.yaml');
  
  return 0;
}
```

### 6. UPDATE `fluttercraft.yaml.example`

Replace entire file with clean version (no app_name, name, number fields).

### 7. UPDATE All Test Fixtures

**Remove version fields from ALL test YAML fixtures:**

```yaml
# BEFORE (test fixtures)
build_defaults:
  app_name: testapp
  name: 1.0.0
  number: 42
  platform: aab

# AFTER
build_defaults:
  platform: aab
  target: lib/main.dart
  # No app metadata
```

**Update these test files:**
- `test/core/build_config_test.dart` - all fixtures
- `test/core/app_context_test.dart` - if needed
- `test/fixtures/no_review_fluttercraft.yaml`
- Any other test fixtures

## Files Summary

### [DELETE] Complete Files
1. `lib/src/core/config_backup.dart`
2. `test/core/config_backup_test.dart`
3. Test methods in `test/ui/shell_test.dart` (keep file, delete sync tests)

### [MODIFY] Remove Sync/Backup Methods
1. `lib/src/ui/shell.dart`
   - Delete `syncVersion()` method
   - Delete `_backupConfig()` method
   - Remove sync call from `run()`

### [MODIFY] Remove Version Fallbacks
1. `lib/src/core/build_config.dart`
   - Always use `pubspecInfo` for app metadata
   - Remove `app_name`, `name`, `number` parsing from YAML

2. `lib/src/core/flavor_config.dart`
   - Remove `versionName` field
   - Remove `buildNumber` field
   - Update `fromYaml()` to not parse version overrides

### [MODIFY] Update Templates
1. `lib/src/commands/gen_command.dart`
   - Generate config without version fields
   - Add clear comment about pubspec.yaml

2. `fluttercraft.yaml.example`
   - Remove all app metadata fields
   - Add comments explaining separation

### [MODIFY] Update Test Fixtures
1. `test/core/build_config_test.dart` - update all YAML fixtures
2. `test/fixtures/no_review_fluttercraft.yaml` - remove version fields
3. Any other test files with YAML fixtures

## Verification Plan

### Unit Tests
```bash
fvm dart test test/core/build_config_test.dart
fvm dart test test/core/app_context_test.dart
# Tests should verify config loads without version in YAML
```

### Gen Command Test
```bash
# Create temp project
mkdir test_project
cd test_project
# Create minimal pubspec.yaml
echo "name: testapp\nversion: 1.0.0+1" > pubspec.yaml

# Run gen
fluttercraft gen

# Verify generated file has no version fields
cat fluttercraft.yaml | grep -E "app_name|name:|number:" 
# Should return nothing

# Try force regenerate
fluttercraft gen -f
```

### Build Test
```bash
# Verify build works with new setup
fluttercraft build
# Should read version from pubspec.yaml only
```

## Benefits

✅ **Radically Simpler**: ~300+ lines of code deleted  
✅ **No Magic**: Users understand exactly where data comes from  
✅ **No Sync Issues**: Files never drift because they're independent  
✅ **Clear Responsibility**: `gen` creates config, user maintains it  
✅ **Faster**: No backup, no sync, no checks on startup

## Breaking Changes

> [!CAUTION]
> **This BREAKS existing projects**. Users must:
> 1. Run `fluttercraft gen -f` to regenerate config
> 2. OR manually delete `app_name`, `name`, `number` from their config

No migration path. Clean break.

## Timeline

- **Phase 1**: Delete files and methods (30 min)
- **Phase 2**: Update BuildConfig and FlavorConfig (1 hour)
- **Phase 3**: Update gen command and example (1 hour)
- **Phase 4**: Update all test fixtures (1-2 hours)
- **Phase 5**: Run tests and verify (30 min)

**Total Estimate**: 4-5 hours
