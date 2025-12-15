# Testing Guide for AI Agents

## TestHelper Summary

### `test/test_helper.dart` - Core Test Utilities

**Key Features:**

- ✅ `getTestPath()` - Resolve test resource paths
- ✅ `testFileExists()` - Check if test resource exists
- ✅ `readYamlFile()` - Read and parse YAML test configs
- ✅ `copyTestFile()` - Copy test resources to temp directories
- ✅ `createTempDirWithCleanup()` - Auto-cleanup temp directories
- ✅ `writeFile()` - Write file with path handling

**Always use TestHelper instead of manual file operations!**

---

## Test Structure

```
test/
├── test_helper.dart          # Shared test utilities
├── v0.0.1/                   # Version-specific tests
├── v0.0.2/
├── v0.0.3/
├── v0.0.6/
│   ├── fluttercraft-test.yaml  # Shared test config
│   ├── alias_config_test.dart
│   ├── run_command_test.dart
│   └── README.md
└── TEST.md                   # This file
```

## Using TestHelper

**Always use `test_helper.dart` utilities instead of manual file operations.**

### Common Patterns

#### 1. Setup/Teardown with Temp Directory
```dart
late String tempDir;
late Future<void> Function() cleanup;

setUp(() async {
  (tempDir, cleanup) = TestHelper.createTempDirWithCleanup('my_test_');
});

tearDown(() async {
  await cleanup();
});
```

#### 2. Read Test Resource Files
```dart
// Read YAML config
final config = TestHelper.readYamlFile('v0.0.6', 'fluttercraft-test.yaml');

// Copy test file to temp dir
await TestHelper.copyTestFile('v0.0.6', 'fluttercraft-test.yaml', '$tempDir/config.yaml');
```

#### 3. Create Test Files
```dart
// Write file
await TestHelper.writeFile(tempDir, 'config.yaml', yamlContent);

// Write pubspec.yaml
await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0

environment:
  sdk: ^3.0.0
''');
```

#### 4. Check File Existence
```dart
// Check test resource
if (TestHelper.testFileExists('v0.0.6', 'config.yaml')) { ... }
```

## Test Organization

### Version-Specific Tests
- Create `test/v{x.x.x}/` directory for each version
- Include version-specific test configs in the version directory
- Add `README.md` in version directory explaining tests

### Shared Test Configs
- Store reusable test configs in version directories (e.g., `fluttercraft-test.yaml`)
- Document all test configs in version `README.md`
- Use `TestHelper.copyTestFile()` to use configs in tests

### Test Naming
- `{feature}_test.dart` for feature tests
- `{component}_config_test.dart` for config parsing tests
- Group related tests with `group()` blocks

## Running Tests

```bash
# All tests
fvm dart test

# Specific version
fvm dart test test/v0.0.6/

# Specific file
fvm dart test test/v0.0.6/alias_config_test.dart

# With coverage
fvm dart test --coverage

# Verbose output
fvm dart test --reporter expanded
```

## Best Practices

1. **Use TestHelper** - Don't write manual file operations
2. **Clean up** - Always use `createTempDirWithCleanup()` for temp directories
3. **Shared configs** - Centralize test data in YAML files
4. **Document** - Update version README when adding tests
5. **Skip manual tests** - Mark tests requiring external tools with `skip:`

## Example Test Structure

```dart
import 'package:test/test.dart';
import '../test_helper.dart';

void main() {
  group('MyFeature', () {
    late String tempDir;
    late Future<void> Function() cleanup;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup('my_test_');
    });

    tearDown(() async {
      await cleanup();
    });

    test('does something', () async {
      // Use TestHelper methods
      await TestHelper.writeFile(tempDir, 'test.txt', 'content');
      final content = await TestHelper.readFile(tempDir, 'test.txt');
      
      expect(content, 'content');
    });
  });
}
```

## Adding New Tests

1. Create version directory: `test/v{x.x.x}/`
2. Add test configs if needed
3. Write tests using TestHelper
4. Update version README
5. Run tests: `fvm dart test test/v{x.x.x}/`
6. Update this guide if adding new patterns
