import 'package:fluttercraft/src/commands/gen_command.dart';
import 'package:test/test.dart';

import '../test_helper.dart';
import '../wrapper_test_mocks.dart';

/// Tests for GenCommand
///
/// Verifies config generation and .gitignore update functionality.
void main() {
  group('GenCommand', () {
    late String tempDir;
    late Future<void> Function() cleanup;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup(
        'gen_command_test_',
      );
      // Create minimal pubspec.yaml for detection
      await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0+1
environment:
  sdk: ^3.0.0
''');
    });

    tearDown(() async {
      await cleanup();
    });

    test('generates fluttercraft.yaml in project directory', () async {
      final genCmd = GenCommand(console: MockConsole(), cwd: tempDir);
      final result = await genCmd.run();

      expect(result, 0);
      expect(await TestHelper.fileExists(tempDir, 'fluttercraft.yaml'), true);
    });

    test('creates .gitignore with .fluttercraft/ if not exists', () async {
      final genCmd = GenCommand(console: MockConsole(), cwd: tempDir);
      await genCmd.run();

      expect(await TestHelper.fileExists(tempDir, '.gitignore'), true);
      final content = await TestHelper.readFile(tempDir, '.gitignore');
      expect(content, contains('.fluttercraft/'));
    });

    test('appends to existing .gitignore without .fluttercraft/', () async {
      // Create existing .gitignore
      await TestHelper.writeFile(tempDir, '.gitignore', '*.log\n');

      final genCmd = GenCommand(console: MockConsole(), cwd: tempDir);
      await genCmd.run();

      final content = await TestHelper.readFile(tempDir, '.gitignore');
      expect(content, contains('*.log'));
      expect(content, contains('.fluttercraft/'));
    });

    test('does not duplicate .fluttercraft/ in .gitignore', () async {
      // Create .gitignore with .fluttercraft/ already present
      await TestHelper.writeFile(tempDir, '.gitignore', '.fluttercraft/\n');

      final genCmd = GenCommand(console: MockConsole(), cwd: tempDir);
      await genCmd.run();

      final content = await TestHelper.readFile(tempDir, '.gitignore');
      // Should only have one occurrence
      final count = '.fluttercraft/'.allMatches(content).length;
      expect(count, 1);
    });

    test('refuses to overwrite existing config without --force', () async {
      // Create existing config
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', 'existing: true');

      final genCmd = GenCommand(console: MockConsole(), cwd: tempDir);
      final result = await genCmd.run();

      expect(result, 1); // Should fail without --force
    });

    test('generated config has correct default output path', () async {
      final genCmd = GenCommand(console: MockConsole(), cwd: tempDir);
      await genCmd.run();

      final content = await TestHelper.readFile(tempDir, 'fluttercraft.yaml');
      expect(content, contains('output: .fluttercraft/dist'));
    });

    test('generated config includes args field', () async {
      final genCmd = GenCommand(console: MockConsole(), cwd: tempDir);
      await genCmd.run();

      final content = await TestHelper.readFile(tempDir, 'fluttercraft.yaml');
      expect(content, contains('args: []'));
      expect(content, contains('Extra arguments to pass to the build command'));
    });
  });
}
