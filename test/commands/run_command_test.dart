import 'package:test/test.dart';
import 'package:fluttercraft/src/core/app_context.dart';
import 'package:fluttercraft/src/commands/run_command.dart';
import '../test_helper.dart';

/// Tests for RunCommand
///
/// Verifies alias listing, command execution, and error handling.
void main() {
  group('RunCommand', () {
    late String tempDir;
    late Future<void> Function() cleanup;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup(
        'run_command_test_',
      );
    });

    tearDown(() async {
      await cleanup();
    });

    /// Create test context with custom YAML content
    Future<AppContext> createTestContext(String yamlContent) async {
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', yamlContent);
      return await AppContext.load(projectRoot: tempDir);
    }

    group('List Aliases', () {
      test('lists aliases when --list flag is provided', () async {
        final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
  alias:
    simple:
      cmds:
        - echo hello
''');
        final runCmd = RunCommand(context);
        expect(await runCmd.execute(['--list']), 0);
      });

      test('lists aliases when -l flag is provided', () async {
        final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
  alias:
    test:
      cmds:
        - echo test
''');
        final runCmd = RunCommand(context);
        expect(await runCmd.execute(['-l']), 0);
      });

      test('lists aliases when "list" subcommand is provided', () async {
        final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
  alias:
    test:
      cmds:
        - echo test
''');
        final runCmd = RunCommand(context);
        expect(await runCmd.execute(['list']), 0);
      });

      test('shows message when no aliases are defined', () async {
        final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
''');
        final runCmd = RunCommand(context);
        expect(await runCmd.execute(['--list']), 0);
      });
    });

    group('Alias Execution', () {
      test('lists aliases when no alias name is provided', () async {
        final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
  alias:
    simple:
      cmds:
        - echo hello
''');
        final runCmd = RunCommand(context);
        expect(await runCmd.execute([]), 0);
      });

      test('executes single simple command successfully', () async {
        final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
  alias:
    simple:
      cmds:
        - echo hello
''');
        final runCmd = RunCommand(context);
        expect(await runCmd.execute(['simple']), 0);
      });

      test('executes multiple commands in sequence', () async {
        final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
  alias:
    multi:
      cmds:
        - echo first
        - echo second
''');
        final runCmd = RunCommand(context);
        expect(await runCmd.execute(['multi']), 0);
      });
    });

    group('Error Handling', () {
      test('handles nonexistent alias gracefully', () async {
        final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
  alias:
    simple:
      cmds:
        - echo hello
''');
        final runCmd = RunCommand(context);
        expect(await runCmd.execute(['nonexistent']), 1);
      });

      test('handles invalid command gracefully', () async {
        final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
  alias:
    invalid:
      cmds:
        - this-command-does-not-exist-xyz
''');
        final runCmd = RunCommand(context);
        expect(await runCmd.execute(['invalid']), 1);
      });
    });
  });
}
