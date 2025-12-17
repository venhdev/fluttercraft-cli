import 'dart:io';
import 'package:path/path.dart' as p;

/// Test helper utilities for fluttercraft tests
///
/// Provides core functionality for test setup and file operations.
class TestHelper {
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

  /// Read content from a file
  static Future<String> readFile(String directory, String filename) async {
    final filePath = p.join(directory, filename);
    return await File(filePath).readAsString();
  }

  /// Check if a file exists
  static Future<bool> fileExists(String directory, String filename) async {
    final filePath = p.join(directory, filename);
    return await File(filePath).exists();
  }

  /// Get the path to test fixtures
  static String getFixturePath(String filename) {
    return p.join('test', 'fixtures', filename);
  }
}
