# Testing Guide for AI Agents

## TestHelper Key Features

The `test/test_helper.dart` provides utilities for working with test resources:

- **`getTestPath(subdir, filename)`** - Get path to test resource file
- **`testFileExists(subdir, filename)`** - Check if test file exists  
- **`readYamlFile(subdir, filename)`** - Read and parse YAML file
- **`copyTestFile(subdir, filename, dest)`** - Copy test file to destination
- **`createTempDirWithCleanup(prefix)`** - Create temp dir with auto-cleanup (when needed)
- **`writeFile(dir, filename, content)`** - Write file with path handling

## Adding New Tests Workflow

1. **Create version directory**: `test/v{x.x.x}/`
2. **Add test config**: Create `test/v{x.x.x}/fluttercraft.yaml` with test configurations
3. **Write tests** using TestHelper to load configs
4. **Run verification**: `fvm dart test test/v{x.x.x}/ && fvm dart analyze`
5. **Update this guide** if adding new patterns

## Standard Test Pattern

```dart
import 'package:test/test.dart';
import 'package:fluttercraft/src/core/build_config.dart';
import '../test_helper.dart';

void main() {
  group('MyFeature (v{x.x.x})', () {
    test('does something', () async {
      // Load config from static YAML file
      final configPath = TestHelper.getTestPath('v{x.x.x}', 'fluttercraft.yaml');
      final config = await BuildConfig.load(configPath: configPath);
      
      expect(config.appName, equals('testapp'));
    });
    
    test('with multiple configs', () async {
      // Use different YAML file for different test cases
      final configPath = TestHelper.getTestPath('v{x.x.x}', 'fluttercraft-dev.yaml');
      final config = await BuildConfig.load(configPath: configPath);
      
      expect(config.flavor, equals('dev'));
    });
  });
}
```

## Test Structure

```
test/
├── test_helper.dart          # Shared utilities
├── v0.0.1/
│   └── fluttercraft.yaml     # Static test config
├── v0.0.3/
│   └── fluttercraft.yaml
├── v0.0.6/
│   ├── fluttercraft.yaml
│   └── run_command_test.dart
├── v0.1.1/
│   ├── fluttercraft.yaml     # Main config
│   ├── fluttercraft-dev.yaml # Dev flavor config
│   └── flavor_tests.dart
├── v0.1.2/
│   ├── fluttercraft.yaml
│   └── dart_define_from_file_test.dart
└── TEST-GUIDE.md             # This file
```

## Running Tests

```bash
fvm dart test                        # All tests
fvm dart test test/v0.1.2/           # Specific version
fvm dart analyze                     # Check for issues
```

## Best Practices

✅ **Use static YAML files** - Store test configs in version directories  
✅ **Use TestHelper methods** - Don't manually construct paths  
✅ **Multiple configs per version** - Create separate YAML files for different scenarios  
✅ **Keep tests simple** - No setUp/tearDown unless truly needed  
✅ **Version-specific directories** - Group tests by version

❌ **Don't** use temp directories for simple config tests  
❌ **Don't** write inline YAML in test files (use static files)  
❌ **Don't** manually read files (use TestHelper.readYamlFile)
