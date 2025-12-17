# Dual Config Loading Approach

**Last Updated**: 2025-12-22  
**Status**: Ready for Implementation

---

## 📋 Table of Contents
- [Overview](#overview)
- [Goals](#goals)
- [Use Cases](#use-cases)
- [Priority Rules](#priority-rules)
- [Implementation Plan](#implementation-plan)
- [File Structure](#file-structure)
- [Comparison with Shorebird](#comparison-with-shorebird)
- [Verification Plan](#verification-plan)

---

## Overview

Support two configuration methods for maximum flexibility:

| Location | Priority | Use Case |
|----------|----------|----------|
| `fluttercraft.yaml` (separate file) | **Highest** | Complex projects with multiple flavors |
| `pubspec.yaml` (`fluttercraft:` section) | Medium | Simple projects, getting started |
| No config (defaults) | Lowest | Quick testing, minimal setup |

> [!NOTE]
> Both approaches require the `fluttercraft:` root key for consistency and tooling support.

---

## Goals

- ✅ **Flexibility**: Support both embedded and separate config files
- ✅ **Convention over Configuration**: Sensible defaults from pubspec.yaml when no config exists
- ✅ **No Auto-Generation**: Never auto-create config files - only explicit `gen` command creates them
- ✅ **Clean Separation**: `fluttercraft.yaml` = build settings only (no app metadata)
- ✅ **Consistent Structure**: Always use `fluttercraft:` root key for clarity and tooling support

---

## Use Cases

### 📦 Case 1: Embedded in `pubspec.yaml` (Simple Projects)

**Best for**: Small projects, quick prototyping, single flavor apps

```yaml
# pubspec.yaml
name: myapp
version: 1.0.0+42

fluttercraft:
  build:
    platform: apk
    target: lib/main.dart
    flags:
      should_clean: true
  
  environments:
    fvm:
      enabled: true
```

| ✅ Pros | ❌ Cons |
|---------|---------|
| Single file to manage | `pubspec.yaml` can get cluttered |
| Good for small projects | No YAML anchors support |
| Easy to version control | Cannot use advanced DRY patterns |

---

### 🔧 Case 2: Separate `fluttercraft.yaml` (Complex Projects)

**Best for**: Multi-flavor apps, complex build configs, team projects

```yaml
# fluttercraft.yaml
fluttercraft:
  build_defaults: &build_defaults
    platform: aab
    target: lib/main.dart
    global_dart_define:
      API_URL: https://api.example.com
    
  build:
    <<: *build_defaults
    flavor: dev
    
  flavors:
    dev:
      platform: apk
      dart_define:
        IS_DEV: true
    prod:
      platform: aab
      flags:
        should_clean: true
        should_build_runner: true
```

| ✅ Pros | ❌ Cons |
|---------|---------|
| Dedicated file for build config | Extra file to maintain |
| Supports YAML anchors for DRY | - |
| Easier multi-flavor management | - |
| Cleaner `pubspec.yaml` | - |
| Same structure as embedded | - |

---

## Priority Rules

The configuration is loaded in this priority order:

```
┌─────────────────────────────────────┐
│  1. fluttercraft.yaml (if exists)   │  ← Highest Priority
│     └─ Use exclusively              │
└─────────────────────────────────────┘
              ↓ (not found)
┌─────────────────────────────────────┐
│  2. pubspec.yaml → fluttercraft:    │  ← Medium Priority
│     └─ Use embedded config          │
└─────────────────────────────────────┘
              ↓ (not found)
┌─────────────────────────────────────┐
│  3. Defaults from pubspec.yaml      │  ← Lowest Priority
│     └─ Load sensible defaults       │
└─────────────────────────────────────┘
```

> [!IMPORTANT]
> **Key Behaviors:**
> - When both files exist, `fluttercraft.yaml` takes **complete precedence**
> - **No auto-generation**: Config files are ONLY created by explicit `fluttercraft gen` command
> - When no config exists, the tool works with intelligent defaults - **no file creation**

---

## Implementation Plan

### Phase 1: Update Config Loading

#### 1.1 Current Implementation

```dart
// lib/src/core/build_config.dart (CURRENT)
static Future<BuildConfig> load({String? configPath, ...}) async {
  final path = configPath ?? p.join(root, 'fluttercraft.yaml');
  final file = File(path);
  if (!await file.exists()) {
    // return defaults
  }
  final content = await file.readAsString();
  final yaml = loadYaml(content) as YamlMap?;
  return _parseNewFormat(yaml, root, pubspecInfo: pubspecInfo);
}
```

#### 1.2 New Implementation

```dart
// lib/src/core/build_config.dart (NEW)
static Future<BuildConfig> load({
  String? configPath,
  PubspecInfo? pubspecInfo,
  String? projectRoot,
}) async {
  final root = projectRoot ?? Directory.current.path;
  
  // Load pubspec info first (always needed)
  if (pubspecInfo == null) {
    final pubspecParser = PubspecParser(projectRoot: root);
    pubspecInfo = await pubspecParser.parse();
  }
  
  // ═══════════════════════════════════════════════════════════════
  // PRIORITY 1: Explicit configPath (for testing/override)
  // ═══════════════════════════════════════════════════════════════
  if (configPath != null) {
    return _loadFromFile(configPath, root, pubspecInfo);
  }
  
  // ═══════════════════════════════════════════════════════════════
  // PRIORITY 2: fluttercraft.yaml (separate file - HIGHEST PRIORITY)
  // ═══════════════════════════════════════════════════════════════
  final fluttercraftYamlPath = p.join(root, 'fluttercraft.yaml');
  if (await File(fluttercraftYamlPath).exists()) {
    return _loadFromFile(fluttercraftYamlPath, root, pubspecInfo);
  }
  
  // ═══════════════════════════════════════════════════════════════
  // PRIORITY 3: pubspec.yaml → fluttercraft: section (embedded)
  // ═══════════════════════════════════════════════════════════════
  final pubspecYamlPath = p.join(root, 'pubspec.yaml');
  if (await File(pubspecYamlPath).exists()) {
    final pubspecContent = await File(pubspecYamlPath).readAsString();
    final pubspecYaml = loadYaml(pubspecContent) as YamlMap?;
    
    if (pubspecYaml != null && pubspecYaml.containsKey('fluttercraft')) {
      final fluttercraftSection = pubspecYaml['fluttercraft'] as YamlMap?;
      if (fluttercraftSection != null) {
        // Parse embedded config directly
        return _parseNewFormat(fluttercraftSection, root, pubspecInfo: pubspecInfo);
      }
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // PRIORITY 4: No config found - use defaults from pubspec.yaml
  // DO NOT auto-generate any files - just return sensible defaults
  // ═══════════════════════════════════════════════════════════════
  return _createDefaultConfig(root, pubspecInfo);
}

/// Load config from file and enforce fluttercraft: root key
static Future<BuildConfig> _loadFromFile(
  String path,
  String root,
  PubspecInfo? pubspecInfo,
) async {
  final content = await File(path).readAsString();
  final yaml = loadYaml(content) as YamlMap?;
  
  if (yaml == null) {
    throw ConfigParseException('Config file is empty or invalid: $path');
  }
  
  // Expect 'fluttercraft:' root key (required for all config files)
  if (!yaml.containsKey('fluttercraft')) {
    throw ConfigParseException(
      'Config file must have "fluttercraft:" as root key. Found: ${yaml.keys.join(", ")}'
    );
  }
  
  final fluttercraftSection = yaml['fluttercraft'] as YamlMap;
  return _parseNewFormat(fluttercraftSection, root, pubspecInfo: pubspecInfo);
}

/// Create default config when no config file exists
static BuildConfig _createDefaultConfig(
  String root,
  PubspecInfo? pubspecInfo,
) {
  // Return minimal config with pubspec metadata + sensible defaults
  return BuildConfig(
    projectRoot: root,
    appName: pubspecInfo?.name ?? 'app',
    buildName: null, // Let Flutter read from pubspec.yaml
    buildNumber: null,
    platform: 'aab',
    targetDart: 'lib/main.dart',
    noReview: false,
    outputPath: '.fluttercraft/dist',
    flags: BuildFlags.defaults,
    useFvm: false,
    useShorebird: false,
    shorebirdNoConfirm: true,
    keystorePath: 'android/key.properties',
    args: [],
  );
}
```

---

### Phase 2: Root Key Requirements

> [!IMPORTANT]
> **All config files MUST use `fluttercraft:` as root key** - whether separate or embedded.

#### ✅ Separate `fluttercraft.yaml`

```yaml
# fluttercraft.yaml
fluttercraft:
  build_defaults: &build_defaults
    platform: aab
    target: lib/main.dart

  build:
    <<: *build_defaults
    flavor: null

  environments:
    fvm:
      enabled: true
```

#### ✅ Embedded in `pubspec.yaml`

```yaml
# pubspec.yaml
name: myapp
version: 1.0.0+1

fluttercraft:
  build:
    platform: apk
  environments:
    fvm:
      enabled: true
```

**Benefits of consistent root key:**

| Benefit | Description |
|---------|-------------|
| 🔍 **Clarity** | Easy to identify fluttercraft config in any context |
| 🛠️ **Tooling** | IDEs and schema validators can easily locate config |
| 🔄 **Consistency** | Same structure whether embedded or separate |
| 🚀 **Migration** | Easy to move config between pubspec.yaml and separate file |
| 🔮 **Future-proof** | Enables potential config merging or multi-file support |

---

### Phase 3: PubspecParser Helper (Optional)

```dart
// lib/src/core/pubspec_parser.dart

class PubspecParser {
  // ... existing code ...
  
  /// Extract fluttercraft config section from pubspec.yaml (if exists)
  Future<YamlMap?> extractFluttercraftConfig() async {
    final file = File(pubspecPath);
    if (!await file.exists()) {
      return null;
    }
    
    try {
      final content = await file.readAsString();
      final yaml = loadYaml(content) as YamlMap;
      
      if (yaml.containsKey('fluttercraft')) {
        return yaml['fluttercraft'] as YamlMap?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
```

> [!NOTE]
> This method is **optional**. The `BuildConfig.load()` can read pubspec.yaml directly inline without this helper.

---

### Phase 4: AppContext Updates

Add `configSource` tracking to know where configuration was loaded from:

```dart
// lib/src/core/app_context.dart

static Future<AppContext> load({String? projectRoot}) async {
  final root = projectRoot ?? Directory.current.path;
  
  // Load pubspec first
  final pubspecParser = PubspecParser(projectRoot: root);
  final pubspecInfo = await pubspecParser.parse();
  
  // Determine config source for tracking
  final fluttercraftYamlPath = p.join(root, 'fluttercraft.yaml');
  final hasFluttercraftYaml = await File(fluttercraftYamlPath).exists();
  
  String configSource;
  if (hasFluttercraftYaml) {
    configSource = 'fluttercraft.yaml';
  } else {
    // Check if pubspec has embedded config
    final pubspecYamlPath = p.join(root, 'pubspec.yaml');
    if (await File(pubspecYamlPath).exists()) {
      final content = await File(pubspecYamlPath).readAsString();
      final yaml = loadYaml(content) as YamlMap?;
      if (yaml?.containsKey('fluttercraft') ?? false) {
        configSource = 'pubspec.yaml (fluttercraft: section)';
      } else {
        configSource = 'defaults (no config found)';
      }
    } else {
      configSource = 'defaults (no pubspec.yaml)';
    }
  }
  
  // Load config (new loader handles priority automatically)
  final config = await BuildConfig.load(
    pubspecInfo: pubspecInfo,
    projectRoot: root,
  );
  
  return AppContext._(
    config: config,
    pubspecInfo: pubspecInfo,
    projectRoot: root,
    loadedAt: DateTime.now(),
    hasConfigFile: hasFluttercraftYaml,
    configSource: configSource, // NEW: Track where config came from
  );
}
```

**Add new field to `AppContext` class:**
```dart
final String configSource; // e.g., 'fluttercraft.yaml', 'pubspec.yaml', 'defaults'
```

---

### Phase 5: Gen Command (No Changes)

Keep the `gen` command simple - it only creates separate `fluttercraft.yaml` files:

```bash
# Create new config
fluttercraft gen

# Force overwrite existing
fluttercraft gen -f
```

> [!NOTE]
> Users who want embedded config must manually add the `fluttercraft:` section to their `pubspec.yaml`.
> This keeps the tool simple and doesn't require complex pubspec.yaml manipulation.

---

### Phase 6: Breaking Changes & Migration

> [!WARNING]
> **Breaking Change**: Existing `fluttercraft.yaml` files need to be wrapped with `fluttercraft:` root key.

**Error Message for Old Format:**
```
Config file must have "fluttercraft:" as root key. Found: build_defaults, build, flavors, ...
```

**Migration Options:**

| Option | Command | Description |
|--------|---------|-------------|
| 🔄 **Auto-regenerate** | `fluttercraft gen -f` | Regenerate config with new format |
| ✏️ **Manual update** | Edit file | Add `fluttercraft:` root key and indent content |

---

## File Structure

### Simple Project (Embedded)
```
myapp/
├── pubspec.yaml          # Contains 'fluttercraft:' section
├── lib/
│   └── main.dart
└── .fvmrc
```

### Complex Project (Separate File)
```
myapp/
├── pubspec.yaml          # App metadata only
├── fluttercraft.yaml     # Build config with 'fluttercraft:' root
├── lib/
│   └── main.dart
├── .fvmrc
└── shorebird.yaml
```

---

## Files to Modify

### 🔧 [MODIFY] Core Config Loading

**`lib/src/core/build_config.dart`**
- Update `load()` to support priority chain: fluttercraft.yaml → pubspec.yaml (fluttercraft:) → defaults
- Add `_createDefaultConfig()` helper method
- Update `_loadFromFile()` to enforce `fluttercraft:` root key requirement
- Add root key extraction and validation logic
- Add pubspec.yaml reading logic in `load()` method

**`lib/src/core/app_context.dart`**
- Add `configSource` field (String) to track where config was loaded from
- Update `load()` to detect and track config source
- Update constructor to accept `configSource` parameter

---

### 📝 [MODIFY] Examples and Docs

**`README.md`**
- Document both config approaches (separate vs embedded)
- Show examples of each approach
- Explain priority rules clearly
- Document that no auto-generation occurs

**`doc/examples/pubspec_embedded.yaml`** *(NEW)*
- Example of `pubspec.yaml` with embedded `fluttercraft:` section

---

### 📦 [MODIFY] Templates and Examples

**`lib/src/commands/gen_command.dart`**
- Ensure generated config includes `fluttercraft:` root key

**`fluttercraft.yaml.example`**
- Add `fluttercraft:` root key if not already present

---

### ✅ [NO CHANGES NEEDED]

- `lib/src/core/pubspec_parser.dart` - Can read inline, no helper method required

---

## Comparison with Shorebird

### Shorebird Approach
```yaml
# shorebird.yaml (separate file - no root key)
app_id: abc123
flavors:
  development:
    app_id: abc123-dev
  production:
    app_id: abc123-prod
```

### Fluttercraft Approach
```yaml
# Option 1: fluttercraft.yaml (separate - with root key)
fluttercraft:
  build_defaults: &defaults
    platform: aab
  flavors:
    dev:
      platform: apk
    prod:
      platform: aab

# Option 2: pubspec.yaml (embedded - same root key)
name: myapp
version: 1.0.0+1

fluttercraft:
  build:
    platform: apk
  flavors:
    dev:
      platform: apk
```

**Comparison Table:**

| Feature | Shorebird | Fluttercraft |
|---------|-----------|--------------|
| Separate config file | ✅ Yes (no root key) | ✅ Yes (with root key) |
| Embedded in pubspec | ❌ No | ✅ Yes |
| Root key requirement | ❌ No | ✅ Yes (consistent) |
| Easy migration between files | - | ✅ Yes (same structure) |

---

## Verification Plan

### Unit Tests

| # | Test Case |
|---|-----------|
| 1 | ✅ Test loading from `fluttercraft.yaml` (separate file) |
| 2 | ✅ Test loading from `pubspec.yaml` with `fluttercraft:` section (embedded) |
| 3 | ✅ Test priority: separate file takes precedence over embedded config |
| 4 | ✅ Test defaults: no config found returns sensible defaults |
| 5 | ✅ Test config source tracking in `AppContext` |
| 6 | ✅ Test error thrown when root key is missing |

### Integration Tests

| # | Test Scenario |
|---|---------------|
| 1 | Create project with embedded config in `pubspec.yaml` only |
| 2 | Create project with separate `fluttercraft.yaml` only |
| 3 | Create project with both configs (verify separate file wins) |
| 4 | Create project with no config (verify defaults work) |
| 5 | Run `fluttercraft build` with each config scenario |

### Manual Testing

- [ ] Test shell commands work with embedded config
- [ ] Test shell commands work with separate file
- [ ] Verify `info` command shows correct `configSource`
- [ ] Test project with no config runs successfully with defaults
- [ ] Verify helpful error message when root key is missing

---

## Benefits

| Benefit | Description |
|---------|-------------|
| 🎯 **Flexibility** | Users choose embedded (simple) or separate (complex) config |
| 🚫 **No Auto-Generation** | Never surprises users by creating files |
| 📍 **Explicit Priority** | Separate file always wins, no ambiguity |
| ✨ **Clean Defaults** | Works out-of-box with just pubspec.yaml |
| 🔄 **Consistent Structure** | Same format everywhere (easy to migrate) |
| 🛠️ **Better Tooling** | Root key enables IDE autocomplete, validation |
| 📦 **Simple Implementation** | Minimal code changes to existing architecture |

---

**End of Plan Document**
