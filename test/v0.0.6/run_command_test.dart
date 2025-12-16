import 'package:test/test.dart';
import 'package:fluttercraft/src/core/app_context.dart';
import 'package:fluttercraft/src/commands/run_command.dart';
import '../test_helper.dart';

void main() {
  group('RunCommand - Integration Tests', () {
    late String tempDir;
    late String configPath;
    late Future<void> Function() cleanup;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup(
        'run_command_test_',
      );
      configPath = '$tempDir/fluttercraft.yaml';
    });

    tearDown(() async {
      await cleanup();
    });

    /// Create test context using the shared test config
    Future<AppContext> createTestContextFromSharedConfig() async {
      // Copy shared test config to temp directory
      await TestHelper.copyTestFile(
        'v0.0.6',
        'fluttercraft-test.yaml',
        configPath,
      );

      // Load context with tempDir as project root
      return await AppContext.load(projectRoot: tempDir);
    }

    /// Create test context with custom YAML content
    Future<AppContext> createTestContext(String yamlContent) async {
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', yamlContent);

      // Load context with tempDir as project root
      return await AppContext.load(projectRoot: tempDir);
    }

    group('List Aliases', () {
      test('lists aliases when --list flag is provided', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);

        // Should return 0
        expect(await runCmd.execute(['--list']), 0);
      });

      test('lists aliases when -l flag is provided', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);

        expect(await runCmd.execute(['-l']), 0);
      });

      test('shows message when no aliases are defined', () async {
        final context = await createTestContext('''
app:
  name: testapp
''');

        final runCmd = RunCommand(context);
        expect(await runCmd.execute(['--list']), 0);
      });
    });

    group('Alias Execution', () {
      test('shows error when no alias name is provided', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);

        expect(await runCmd.execute([]), 1);
      });

      test('executes single simple command successfully', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);

        // This will actually execute the echo command
        expect(await runCmd.execute(['simple']), 0);
      });

      test('executes multiple commands in sequence', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);

        expect(await runCmd.execute(['multi']), 0);
      });

      test('executes commands with arguments', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);

        expect(await runCmd.execute(['args']), 0);
      });

      test(
        'executes fvm dart pub get',
        () async {
          // Create a minimal pubspec.yaml for the test
          await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0

environment:
  sdk: ^3.0.0
''');

          final context = await createTestContextFromSharedConfig();
          final runCmd = RunCommand(context);

          // This will execute fvm dart pub get
          expect(await runCmd.execute(['get']), 0);
        },
        skip: 'Requires fvm to be installed - run manually',
      );

      test(
        'executes fvm flutter doctor',
        () async {
          final context = await createTestContextFromSharedConfig();
          final runCmd = RunCommand(context);

          expect(await runCmd.execute(['doctor']), 0);
        },
        skip: 'Requires fvm and flutter to be installed - run manually',
      );

      test(
        'combines fvm dart pub get and fvm flutter doctor',
        () async {
          // Create a minimal pubspec.yaml
          await TestHelper.writeFile(tempDir, 'pubspec.yaml', '''
name: testapp
version: 1.0.0

environment:
  sdk: ^3.0.0
''');

          final context = await createTestContextFromSharedConfig();
          final runCmd = RunCommand(context);

          expect(await runCmd.execute(['check']), 0);
        },
        skip: 'Requires fvm and flutter to be installed - run manually',
      );
    });

    group('Error Handling', () {
      test('handles nonexistent alias gracefully', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);

        // Should return 1
        expect(await runCmd.execute(['nonexistent']), 1);
      });

      test('handles invalid command gracefully', () async {
        final context = await createTestContextFromSharedConfig();
        final runCmd = RunCommand(context);

        // Should return 1
        expect(await runCmd.execute(['invalid']), 1);
      });
    });
  });
}
