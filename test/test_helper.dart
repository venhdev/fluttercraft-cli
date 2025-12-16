import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Test helper utilities for fluttercraft tests
///
/// Provides core functionality for test setup, file operations,
/// and path resolution.
class TestHelper {
  /// Get absolute path to a test resource file
  ///
  /// Examples:
  /// - `getTestPath('v0.0.6', 'fluttercraft-test.yaml')`
  /// - `getTestPath('fixtures', 'sample.yaml')`
  static String getTestPath(String subdir, String filename) {
    return p.join('test', subdir, filename);
  }

  /// Check if a test resource file exists
  ///
  /// Example: `testFileExists('v0.0.6', 'fluttercraft-test.yaml')`
  static bool testFileExists(String subdir, String filename) {
    final path = getTestPath(subdir, filename);
    return File(path).existsSync();
  }

  /// Read a YAML file from test resources
  ///
  /// Returns the parsed YAML as a Map or throws if file doesn't exist
  ///
  /// Example:
  /// ```dart
  /// final config = TestHelper.readYamlFile('v0.0.6', 'fluttercraft-test.yaml');
  /// ```
  static YamlMap readYamlFile(String subdir, String filename) {
    final path = getTestPath(subdir, filename);
    final file = File(path);

    if (!file.existsSync()) {
      throw FileSystemException('Test file not found', path);
    }

    final content = file.readAsStringSync();
    final yaml = loadYaml(content);

    if (yaml is! YamlMap) {
      throw FormatException('Expected YAML map in $path');
    }

    return yaml;
  }

  /// Copy a test resource file to a destination
  ///
  /// Useful for setting up test environments
  ///
  /// Example:
  /// ```dart
  /// await TestHelper.copyTestFile('v0.0.6', 'fluttercraft-test.yaml', '/tmp/test/fluttercraft.yaml');
  /// ```
  static Future<void> copyTestFile(
    String subdir,
    String filename,
    String destination,
  ) async {
    final sourcePath = getTestPath(subdir, filename);
    final sourceFile = File(sourcePath);

    if (!sourceFile.existsSync()) {
      throw FileSystemException('Test file not found', sourcePath);
    }

    await sourceFile.copy(destination);
  }

  /// Create a temporary directory and return a cleanup function
  ///
  /// Returns a tuple of (tempDir, cleanup function)
  ///
  /// Example:
  /// ```dart
  /// final (tempDir, cleanup) = TestHelper.createTempDirWithCleanup('test_');
  /// try {
  ///   // ... use tempDir
  /// } finally {
  ///   await cleanup();
  /// }
  /// ```
  static (String, Future<void> Function()) createTempDirWithCleanup(
    String prefix,
  ) {
    final tempDir = Directory.systemTemp.createTempSync(prefix).path;

    Future<void> cleanup() async {
      try {
        await Directory(tempDir).delete(recursive: true);
      } catch (_) {
        // Ignore cleanup errors
      }
    }

    return (tempDir, cleanup);
  }

  /// Write content to a file in a directory
  ///
  /// Creates parent directories if needed
  ///
  /// Example:
  /// ```dart
  /// await TestHelper.writeFile('/tmp/test', 'config.yaml', 'app:\n  name: test');
  /// ```
  static Future<void> writeFile(
    String directory,
    String filename,
    String content,
  ) async {
    final filePath = p.join(directory, filename);
    final file = File(filePath);

    // Create parent directories if needed
    await file.parent.create(recursive: true);

    await file.writeAsString(content);
  }
}
