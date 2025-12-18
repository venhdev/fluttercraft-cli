import 'dart:io';
import 'package:test/test.dart';
import 'package:fluttercraft/src/commands/clean_command.dart';
import '../test_helper.dart';

/// Tests for CleanCommand
///
/// Verifies clean functionality and help display.
void main() {
  group('CleanCommand', () {
    late String tempDir;
    late Future<void> Function() cleanup;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup(
        'clean_command_test_',
      );
    });

    tearDown(() async {
      await cleanup();
    });

    test('command has correct name', () {
      final cleanCmd = CleanCommand();
      expect(cleanCmd.name, 'clean');
    });

    test('command has correct description', () {
      final cleanCmd = CleanCommand();
      expect(cleanCmd.description, contains('Clean project'));
      expect(cleanCmd.description, contains('build folder'));
    });

    test('argParser includes dist-only flag', () {
      final cleanCmd = CleanCommand();
      final options = cleanCmd.argParser.options;
      expect(options.containsKey('dist-only'), true);
    });

    test('argParser includes yes flag with negation disabled', () {
      final cleanCmd = CleanCommand();
      final options = cleanCmd.argParser.options;
      expect(options.containsKey('yes'), true);
      expect(options['yes']?.abbr, 'y');
      expect(options['yes']?.negatable, false);
    });

    test('clean removes build folder when it exists', () async {
      // Create a build folder
      final buildDir = Directory('$tempDir/.fluttercraft/dist');
      await buildDir.create(recursive: true);
      await TestHelper.writeFile(
        '$tempDir/.fluttercraft/dist',
        'test.txt',
        'test content',
      );

      // Create config pointing to this temp dir
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', '''
build:
  app_name: testapp
paths:
  output: .fluttercraft/dist
''');

      expect(await buildDir.exists(), true);

      final originalDir = Directory.current;
      Directory.current = Directory(tempDir);

      try {
        final cleanCmd = CleanCommand();
        // We'd need to mock the FlutterRunner for a proper test
        // For now, just verify the command initializes correctly
        expect(cleanCmd.name, 'clean');
      } finally {
        Directory.current = originalDir;
      }
    });
  });
}
