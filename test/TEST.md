# Testing Guide

## Quick Start: Adding New Tests

```bash
# 1. Create version directory
mkdir test/v{x.x.x}/

# 2. Write test using temp files pattern
# See example below

# 3. Run tests
fvm dart test test/v{x.x.x}/

# 4. Update this guide if new patterns emerge
```

## Standard Test Pattern

```dart
import 'dart:io';
import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';

void main() {
  group('MyFeature (v{x.x.x})', () {
    late String tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('test_').path;
    });

    tearDown(() async {
      try {
        await Directory(tempDir).delete(recursive: true);
      } catch (_) {}
    });

    test('does something', () async {
      final configFile = File('$tempDir/fluttercraft.yaml');
      await configFile.writeAsString('''
build_defaults: &build_defaults
  app_name: testapp
  # ... your config
build:
  <<: *build_defaults
''');

      final config = await BuildConfig.load(configPath: configFile.path);
      
      expect(config.appName, equals('testapp'));
    });
  });
}
```

## Test Structure

```
test/
├── v0.1.1/    # Flavors, dart_define, build_defaults
├── v0.1.2/    # dart_define_from_file
└── TEST.md    # This file
```

## Running Tests

```bash
fvm dart test                        # All tests
fvm dart test test/v0.1.2/           # Specific version
fvm dart analyze                     # Check for issues
```

## Best Practices

✅ **Use temp directories** - Auto-cleanup with `Directory.systemTemp.createTempSync()`  
✅ **Write inline YAML** - No external test files needed  
✅ **Group by version** - Create `test/v{x.x.x}/` for each release  
✅ **Test edge cases** - Null values, overrides, flag interactions  

❌ **Don't** use manual file operations  
❌ **Don't** skip cleanup in tearDown  
❌ **Don't** test external tools (mark with `skip:`)
