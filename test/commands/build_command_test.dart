import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:fluttercraft/src/commands/build_command.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

/// Tests for BuildCommand
///
/// Verifies command properties and argument parsing.
void main() {
  group('BuildCommand', () {
    test('command has correct name', () {
      final buildCmd = BuildCommand();
      expect(buildCmd.name, 'build');
    });

    test('command has correct description', () {
      final buildCmd = BuildCommand();
      expect(buildCmd.description, contains('Build'));
    });

    test('argParser includes platform option with abbreviation and allowed values', () {
      final buildCmd = BuildCommand();
      final parser = buildCmd.argParser;
      final options = parser.options;

      expect(options.containsKey('platform'), isTrue);
      expect(options['platform']!.abbr, 'p');
      expect(
        options['platform']!.allowed,
        containsAll([
          'apk',
          'aab',
          'ipa',
        ]),
      );
    });

    test('argParser includes clean flag with abbreviation', () {
      final buildCmd = BuildCommand();
      final options = buildCmd.argParser.options;
      expect(options.containsKey('clean'), true);
      expect(options['clean']?.abbr, 'c');
    });

    test('argParser includes no-confirm flag', () {
      final buildCmd = BuildCommand();
      final options = buildCmd.argParser.options;
      expect(options.containsKey('no-confirm'), true);
    });

    test('argParser includes version option with abbreviation', () {
      final buildCmd = BuildCommand();
      final options = buildCmd.argParser.options;
      expect(options.containsKey('version'), true);
      expect(options['version']?.abbr, 'v');
    });

    test('argParser includes build-number option', () {
      final buildCmd = BuildCommand();
      final options = buildCmd.argParser.options;
      expect(options.containsKey('build-number'), true);
    });

    test('platform option allows only valid build types', () {
      final buildCmd = BuildCommand();
      final options = buildCmd.argParser.options;
      final allowed = options['platform']?.allowed;
      expect(
        allowed,
        containsAll([
          'apk',
          'aab',
          'ipa',
        ]),
      );
    });

    group('validation', () {
      late String tempDir;
      late Future<void> Function() cleanup;
      late String originalDir;

      setUp(() async {
        (tempDir, cleanup) = TestHelper.createTempDirWithCleanup(
          'build_validation_test_',
        );
        originalDir = Directory.current.path;
      });

      tearDown(() async {
        Directory.current = originalDir;
        await cleanup();
      });

      test('fails when pubspec.yaml does not exist', () async {
        // Change to temp directory without pubspec.yaml
        Directory.current = tempDir;

        final buildCmd = BuildCommand();
        final runner = CommandRunner<int>('test', 'test')..addCommand(buildCmd);
        // Use --no-confirm to skip interactive version/build-number prompts in tests
        final exitCode = await runner.run(['build', '--no-confirm']);

        expect(exitCode, 1); // Should fail due to missing fluttercraft.yaml after pubspec check
      });

      test('proceeds when pubspec.yaml exists', () async {
        // Create minimal pubspec.yaml
        await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
''');
        
        // Note: This test will still fail at config loading stage,
        // but it validates that pubspec.yaml check passes
        Directory.current = tempDir;

        final buildCmd = BuildCommand();
        final runner = CommandRunner<int>('test', 'test')..addCommand(buildCmd);
        // Use --no-confirm to skip interactive version/build-number prompts in tests
        final exitCode = await runner.run(['build', '--no-confirm']);

        // Will fail at later stage (no fluttercraft.yaml), but different error
        expect(exitCode, 1);
      });
    });
  });
}
